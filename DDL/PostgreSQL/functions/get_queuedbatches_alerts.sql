-- Function: Get Queued Batches Alerts
-- Purpose: Identifies applications with excessive queued batches on target
-- Returns: Alerts for applications with queued batches exceeding configured threshold

CREATE OR REPLACE FUNCTION mon.get_queuedbatches_alerts()
RETURNS TABLE(
  clusterName TEXT,
  entity_name TEXT,
  deploymentOn TEXT,
  alert_type TEXT,
  alert_trigger_time TIMESTAMP,
  duration_of_problem_state_minutes BIGINT,
  configured_threshold_minutes BIGINT
)
AS $$
WITH
-- Step 1: Get queued batches history with cluster information
QueuedBatchesHistory AS (
  SELECT
    swd.appName,
    swd.batchdate,
    rh.clusterName,
    swd.total_batches_queued,
    aat.maxqueuedbatchesontarget,
    LAG(swd.total_batches_queued, 1, NULL)
      OVER (PARTITION BY swd.appName ORDER BY swd.batchdate) as prev_queued_batches
  FROM
    mon.striim_mon_datawarehouse_detail AS swd
  INNER JOIN
    mon.applicationalertthresholds AS aat
    ON swd.appName = aat.appname
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON swd.batchdate = rh.batchdate
  WHERE
    aat.maxqueuedbatchesontarget IS NOT NULL
    AND aat.maxqueuedbatchesontarget > 0
    AND aat.isenabled = TRUE
    AND swd.total_batches_queued IS NOT NULL
),

-- Step 2: Group consecutive high queue periods into "spells"
SpellGroups AS (
  SELECT
    appName,
    batchdate,
    clusterName,
    total_batches_queued,
    maxqueuedbatchesontarget,
    (total_batches_queued > maxqueuedbatchesontarget) AS is_high_queue,
    SUM(CASE
      WHEN (total_batches_queued > maxqueuedbatchesontarget) IS DISTINCT FROM
           (prev_queued_batches > maxqueuedbatchesontarget) THEN 1
      ELSE 0
    END)
      OVER (PARTITION BY appName ORDER BY batchdate) as spell_id,
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY batchdate DESC) as rn
  FROM
    QueuedBatchesHistory
),

-- Step 3: Calculate duration of each spell
SpellDurations AS (
  SELECT
    appName,
    spell_id,
    MIN(maxqueuedbatchesontarget) AS configured_threshold_batches,
    MAX(batchdate) as spell_end_date,
    EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate))) / 60 as duration_of_problem_state_minutes
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
  CAST(sd.duration_of_problem_state_minutes AS BIGINT),
  CAST(sd.configured_threshold_batches AS BIGINT) as configured_threshold_minutes
FROM
  SpellGroups sg
JOIN SpellDurations sd 
  ON sg.appName = sd.appName AND sg.spell_id = sd.spell_id
LEFT JOIN mon.latest_known_deployments lkd
  ON sg.appName = lkd.appName
WHERE
  sg.rn = 1
  AND sg.is_high_queue = TRUE
  AND sd.duration_of_problem_state_minutes >= 5;
$$ LANGUAGE SQL;

