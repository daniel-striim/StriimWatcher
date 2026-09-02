-- Function: Get Queued Batches Alerts
-- Purpose: Identifies applications with excessive queued batches on target
-- Returns: Alerts for applications with queued batches exceeding configured threshold

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.get_queuedbatches_alerts`()
RETURNS TABLE<
  clusterName STRING,
  entity_name STRING,
  deploymentOn STRING,
  alert_type STRING,
  alert_trigger_time TIMESTAMP,
  duration_of_problem_state_minutes INT64,
  configured_threshold_minutes INT64
>
AS (
WITH
-- Step 1: Get queued batches history with cluster information
QueuedBatchesHistory AS (
  SELECT
    swd.appName,
    swd.batchdate,
    rh.clusterName,
    swd.total_batches_queued,
    aat.maxQueuedBatchesOnTarget,
    LAG(swd.total_batches_queued, 1, NULL) 
      OVER (PARTITION BY swd.appName ORDER BY swd.batchdate) as prev_queued_batches
  FROM
    `striim_watcher_metadata.striim_mon_datawarehouse_detail` AS swd
  INNER JOIN
    `striim_watcher_metadata.ApplicationAlertThresholds` AS aat
    ON swd.appName = aat.appName
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON swd.batchdate = rh.batchdate
  WHERE
    rh.batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 DAY)
    AND swd.batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 DAY)
    AND aat.maxQueuedBatchesOnTarget IS NOT NULL
    AND aat.maxQueuedBatchesOnTarget > 0 
    AND aat.isEnabled IS TRUE
    AND swd.total_batches_queued IS NOT NULL
),

-- Step 2: Group consecutive high queue periods into "spells"
SpellGroups AS (
  SELECT
    appName,
    batchdate,
    clusterName,
    total_batches_queued,
    maxQueuedBatchesOnTarget,
    -- Define high queue condition (alert when queued batches EXCEED the threshold)
    (total_batches_queued > maxQueuedBatchesOnTarget) AS is_high_queue,
    -- Create spell_id for consecutive periods of same queue state
    SUM(CASE
      WHEN (total_batches_queued > maxQueuedBatchesOnTarget) IS DISTINCT FROM
           (prev_queued_batches > maxQueuedBatchesOnTarget) THEN 1
      ELSE 0
    END)
      OVER (PARTITION BY appName ORDER BY batchdate) as spell_id,
    -- Get latest record for each app
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY batchdate DESC) as rn
  FROM
    QueuedBatchesHistory
),

-- Step 3: Calculate duration of each spell
SpellDurations AS (
  SELECT
    appName,
    spell_id,
    MIN(maxQueuedBatchesOnTarget) AS configured_threshold_batches,
    MAX(batchdate) as spell_end_date,
    TIMESTAMP_DIFF(MAX(batchdate), MIN(batchdate), MINUTE) as duration_of_problem_state_minutes
  FROM
    SpellGroups
  WHERE
    is_high_queue = TRUE
  GROUP BY
    appName, spell_id
)

-- Step 4: Generate alerts for qualifying queued batch situations
SELECT
  sg.clusterName,
  sg.appName AS entity_name,
  lkd.deploymentOn,
  'QUEUED_BATCHES' AS alert_type,
  sd.spell_end_date AS alert_trigger_time,
  sd.duration_of_problem_state_minutes,
  -- Convert batch count threshold to a duration representation (using batch count as "minutes")
  sd.configured_threshold_batches as configured_threshold_minutes
FROM
  SpellGroups sg
JOIN SpellDurations sd 
  ON sg.appName = sd.appName AND sg.spell_id = sd.spell_id
-- Get latest known deployment info (may be from different batch to avoid NULLs)
LEFT JOIN `striim_watcher_metadata.latest_known_deployments` lkd
  ON sg.appName = lkd.appName
WHERE
  -- Evaluate latest status only
  sg.rn = 1
  -- Currently experiencing high queue
  AND sg.is_high_queue = TRUE
  -- Duration exceeds minimum threshold (at least 5 minutes of sustained high queue)
  AND sd.duration_of_problem_state_minutes >= 5
);
