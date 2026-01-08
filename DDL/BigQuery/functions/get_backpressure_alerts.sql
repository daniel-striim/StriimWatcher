-- Function: Get Backpressure Alerts
-- Purpose: Identifies applications that are backpressured for a specified duration
-- Returns: Alerts for applications experiencing sustained backpressure

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.get_backpressure_alerts`()
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
-- Step 1: Get backpressure history with cluster information
BackpressureHistory AS (
  SELECT
    smd.appName,
    smd.batchdate,
    rh.clusterName,
    smd.isBackpressured,
    aat.backpressureThresholdMinutes,
    LAG(smd.isBackpressured, 1, NULL) 
      OVER (PARTITION BY smd.appName ORDER BY smd.batchdate) as prev_isBackpressured
  FROM
    `striim_watcher_metadata.striim_mon_appdetail` AS smd
  INNER JOIN
    `striim_watcher_metadata.ApplicationAlertThresholds` AS aat
    ON smd.appName = aat.appName
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON smd.batchdate = rh.batchdate
  WHERE
    aat.backpressureThresholdMinutes IS NOT NULL 
    AND aat.backpressureThresholdMinutes > 0 
    AND aat.isEnabled IS TRUE
),

-- Step 2: Group consecutive backpressure periods into "spells"
SpellGroups AS (
  SELECT
    appName,
    batchdate,
    clusterName,
    isBackpressured,
    backpressureThresholdMinutes,
    -- Create spell_id for consecutive periods of same backpressure state
    SUM(CASE WHEN isBackpressured IS DISTINCT FROM prev_isBackpressured THEN 1 ELSE 0 END) 
      OVER (PARTITION BY appName ORDER BY batchdate) as spell_id,
    -- Get latest record for each app
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY batchdate DESC) as rn
  FROM
    BackpressureHistory
),

-- Step 3: Calculate duration of each spell
SpellDurations AS (
  SELECT
    appName,
    spell_id,
    MIN(backpressureThresholdMinutes) AS configured_threshold_minutes,
    MAX(batchdate) as spell_end_date,
    TIMESTAMP_DIFF(MAX(batchdate), MIN(batchdate), MINUTE) as duration_of_problem_state_minutes
  FROM
    SpellGroups
  GROUP BY
    appName, spell_id
)

-- Step 4: Generate alerts for qualifying backpressure situations
SELECT
  sg.clusterName,
  sg.appName AS entity_name,
  lkd.deploymentOn,
  'BACKPRESSURE' AS alert_type,
  sd.spell_end_date AS alert_trigger_time,
  sd.duration_of_problem_state_minutes,
  sd.configured_threshold_minutes
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
  -- Currently experiencing backpressure
  AND sg.isBackpressured = TRUE
  -- Duration exceeds threshold
  AND sd.duration_of_problem_state_minutes >= sd.configured_threshold_minutes
);
