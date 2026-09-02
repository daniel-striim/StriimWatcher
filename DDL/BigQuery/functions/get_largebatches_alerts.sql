-- Function: Get Large Batches Alerts
-- Purpose: Identifies applications with batch sizes exceeding configured threshold
-- Returns: Alerts for applications with batch sizes that are too large

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.get_largebatches_alerts`()
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
-- Step 1: Get batch size history with cluster information
BatchSizeHistory AS (
  SELECT
    swd.appName,
    swd.batchdate,
    rh.clusterName,
    swd.last_batch_size_bytes,
    swd.avg_batch_size_bytes,
    aat.maxBatchSizeBytes,
    -- Check if either last batch or average batch size exceeds threshold
    CASE 
      WHEN swd.last_batch_size_bytes >= aat.maxBatchSizeBytes THEN TRUE
      WHEN swd.avg_batch_size_bytes >= aat.maxBatchSizeBytes THEN TRUE
      ELSE FALSE
    END as is_large_batch,
    LAG(CASE 
      WHEN swd.last_batch_size_bytes >= aat.maxBatchSizeBytes THEN TRUE
      WHEN swd.avg_batch_size_bytes >= aat.maxBatchSizeBytes THEN TRUE
      ELSE FALSE
    END, 1, NULL) 
      OVER (PARTITION BY swd.appName ORDER BY swd.batchdate) as prev_is_large_batch
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
    AND aat.maxBatchSizeBytes IS NOT NULL
    AND aat.maxBatchSizeBytes > 0 
    AND aat.isEnabled IS TRUE
    AND (swd.last_batch_size_bytes IS NOT NULL OR swd.avg_batch_size_bytes IS NOT NULL)
),

-- Step 2: Group consecutive large batch periods into "spells"
SpellGroups AS (
  SELECT
    appName,
    batchdate,
    clusterName,
    last_batch_size_bytes,
    avg_batch_size_bytes,
    maxBatchSizeBytes,
    is_large_batch,
    -- Create spell_id for consecutive periods of same batch size state
    SUM(CASE WHEN is_large_batch IS DISTINCT FROM prev_is_large_batch THEN 1 ELSE 0 END) 
      OVER (PARTITION BY appName ORDER BY batchdate) as spell_id,
    -- Get latest record for each app
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY batchdate DESC) as rn
  FROM
    BatchSizeHistory
),

-- Step 3: Calculate duration of each spell
SpellDurations AS (
  SELECT
    appName,
    spell_id,
    MIN(maxBatchSizeBytes) AS configured_threshold_bytes,
    MAX(batchdate) as spell_end_date,
    TIMESTAMP_DIFF(MAX(batchdate), MIN(batchdate), MINUTE) as duration_of_problem_state_minutes
  FROM
    SpellGroups
  WHERE
    is_large_batch = TRUE
  GROUP BY
    appName, spell_id
)

-- Step 4: Generate alerts for qualifying large batch situations
SELECT
  sg.clusterName,
  sg.appName AS entity_name,
  lkd.deploymentOn,
  'LARGE_BATCHES' AS alert_type,
  sd.spell_end_date AS alert_trigger_time,
  sd.duration_of_problem_state_minutes,
  -- Convert byte threshold to a duration representation (using MB as "minutes")
  CAST(sd.configured_threshold_bytes / 1048576 AS INT64) as configured_threshold_minutes
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
  -- Currently experiencing large batches
  AND sg.is_large_batch = TRUE
  -- Duration exceeds minimum threshold (at least 5 minutes of sustained large batches)
  AND sd.duration_of_problem_state_minutes >= 5
);
