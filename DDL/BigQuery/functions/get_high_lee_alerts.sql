-- Function: Get High Average LEE (Lag End-to-End) Alerts
-- Purpose: Identifies source->target paths with high average latency
-- Returns: Alerts for source-target pairs experiencing sustained high latency

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.get_high_lee_alerts`()
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
-- Step 1: Get LEE history with cluster information
LeeHistory AS (
  SELECT
    sml.sourceApp,
    sml.targetApp,
    sml.batchdate,
    rh.clusterName,
    aat.avgLeeThresholdMinutes,
    -- Check if avgLEE exceeds threshold (assuming avgLEE is in milliseconds)
    (sml.avgLEE IS NOT NULL AND (sml.avgLEE / 60000.0) > aat.avgLeeThresholdMinutes) AS is_high_avglee,
    LAG((sml.avgLEE IS NOT NULL AND (sml.avgLEE / 60000.0) > aat.avgLeeThresholdMinutes), 1, NULL) 
      OVER (PARTITION BY sml.sourceApp, COALESCE(sml.targetApp, 'UNKNOWN_TARGET_APP') ORDER BY sml.batchdate) as prev_is_high_avglee
  FROM
    `striim_watcher_metadata.striim_mon_lee` AS sml
  INNER JOIN
    `striim_watcher_metadata.ApplicationAlertThresholds` AS aat
    ON sml.sourceApp = aat.appName
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON sml.batchdate = rh.batchdate
  WHERE
    aat.avgLeeThresholdMinutes IS NOT NULL 
    AND aat.avgLeeThresholdMinutes > 0 
    AND aat.isEnabled IS TRUE
),

-- Step 2: Group consecutive high LEE periods into "spells"
SpellGroups AS (
  SELECT
    sourceApp,
    targetApp,
    batchdate,
    clusterName,
    is_high_avglee,
    avgLeeThresholdMinutes,
    -- Create spell_id for consecutive periods of same LEE state
    SUM(CASE WHEN is_high_avglee IS DISTINCT FROM prev_is_high_avglee THEN 1 ELSE 0 END)
      OVER (PARTITION BY sourceApp, COALESCE(targetApp, 'UNKNOWN_TARGET_APP') ORDER BY batchdate) as spell_id,
    -- Get latest record for each source-target pair
    ROW_NUMBER() OVER (PARTITION BY sourceApp, COALESCE(targetApp, 'UNKNOWN_TARGET_APP') ORDER BY batchdate DESC) as rn
  FROM
    LeeHistory
),

-- Step 3: Calculate duration of each spell
SpellDurations AS (
  SELECT
    sourceApp,
    COALESCE(targetApp, 'UNKNOWN_TARGET_APP') AS effective_targetApp,
    spell_id,
    MIN(avgLeeThresholdMinutes) AS configured_threshold_minutes,
    MAX(batchdate) as spell_end_date,
    TIMESTAMP_DIFF(MAX(batchdate), MIN(batchdate), MINUTE) as duration_of_problem_state_minutes
  FROM
    SpellGroups
  GROUP BY
    sourceApp, effective_targetApp, spell_id
)

-- Step 4: Generate alerts for qualifying high LEE situations
SELECT
  sg.clusterName,
  sg.sourceApp || ' -> ' || COALESCE(sg.targetApp, 'UNKNOWN_TARGET_APP') AS entity_name,
  lkd.deploymentOn,
  'HIGH_AVG_LEE' AS alert_type,
  sd.spell_end_date AS alert_trigger_time,
  sd.duration_of_problem_state_minutes,
  sd.configured_threshold_minutes
FROM
  SpellGroups sg
JOIN SpellDurations sd 
  ON sg.sourceApp = sd.sourceApp 
  AND COALESCE(sg.targetApp, 'UNKNOWN_TARGET_APP') = sd.effective_targetApp 
  AND sg.spell_id = sd.spell_id
-- Get latest known deployment info (may be from different batch to avoid NULLs)
LEFT JOIN `striim_watcher_metadata.latest_known_deployments` lkd
  ON sg.sourceApp = lkd.appName
WHERE
  -- Evaluate latest status only
  sg.rn = 1
  -- Currently experiencing high LEE
  AND sg.is_high_avglee = TRUE
  -- Duration exceeds threshold
  AND sd.duration_of_problem_state_minutes >= sd.configured_threshold_minutes
);
