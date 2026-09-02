-- Function: Get Large Batches Alerts
-- Purpose: Identifies applications with batch sizes exceeding configured threshold
-- Returns: Alerts for applications with batch sizes that are too large

CREATE OR REPLACE FUNCTION mon.get_largebatches_alerts()
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
-- Step 1: Get batch size history with cluster information
BatchSizeHistory AS (
  SELECT
    swd.appName,
    swd.batchdate,
    rh.clusterName,
    swd.last_batch_size_bytes,
    swd.avg_batch_size_bytes,
    aat.maxbatchsizebytes,
    CASE
      WHEN swd.last_batch_size_bytes >= aat.maxbatchsizebytes THEN TRUE
      WHEN swd.avg_batch_size_bytes >= aat.maxbatchsizebytes THEN TRUE
      ELSE FALSE
    END as is_large_batch,
    LAG(CASE
      WHEN swd.last_batch_size_bytes >= aat.maxbatchsizebytes THEN TRUE
      WHEN swd.avg_batch_size_bytes >= aat.maxbatchsizebytes THEN TRUE
      ELSE FALSE
    END, 1, NULL)
      OVER (PARTITION BY swd.appName ORDER BY swd.batchdate) as prev_is_large_batch
  FROM
    mon.striim_mon_datawarehouse_detail AS swd
  INNER JOIN
    mon.applicationalertthresholds AS aat
    ON swd.appName = aat.appname
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON swd.batchdate = rh.batchdate
  WHERE
    rh.batchdate >= CURRENT_TIMESTAMP - INTERVAL '5 days'
    AND swd.batchdate >= CURRENT_TIMESTAMP - INTERVAL '5 days'
    AND aat.maxbatchsizebytes IS NOT NULL
    AND aat.maxbatchsizebytes > 0
    AND aat.isenabled = TRUE
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
    maxbatchsizebytes,
    is_large_batch,
    SUM(CASE WHEN is_large_batch IS DISTINCT FROM prev_is_large_batch THEN 1 ELSE 0 END) 
      OVER (PARTITION BY appName ORDER BY batchdate) as spell_id,
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY batchdate DESC) as rn
  FROM
    BatchSizeHistory
),

-- Step 3: Calculate duration of each spell
SpellDurations AS (
  SELECT
    appName,
    spell_id,
    MIN(maxbatchsizebytes) AS configured_threshold_bytes,
    MAX(batchdate) as spell_end_date,
    EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate))) / 60 as duration_of_problem_state_minutes
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
  CAST(sd.duration_of_problem_state_minutes AS BIGINT),
  CAST(sd.configured_threshold_bytes / 1048576 AS BIGINT) as configured_threshold_minutes
FROM
  SpellGroups sg
JOIN SpellDurations sd 
  ON sg.appName = sd.appName AND sg.spell_id = sd.spell_id
LEFT JOIN mon.latest_known_deployments lkd
  ON sg.appName = lkd.appName
WHERE
  sg.rn = 1
  AND sg.is_large_batch = TRUE
  AND sd.duration_of_problem_state_minutes >= 5;
$$ LANGUAGE SQL;

