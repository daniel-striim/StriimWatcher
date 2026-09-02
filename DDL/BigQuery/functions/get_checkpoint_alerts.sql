-- Function: Get Checkpoint Not Progressing Alerts
-- Purpose: Identifies apps where recovery is enabled but checkpoints are not progressing
-- Returns: Alerts for applications with checkpoint progression issues

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.get_checkpoint_alerts`()
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
-- Step 1: Get checkpoint status history with cluster information
CheckpointHistory AS (
  SELECT
    smd.appName,
    smd.batchdate,
    rh.clusterName,
    -- Define checkpoint issue condition (exclude apps that haven't started running yet)
    (smd.isRecoveryEnabled = TRUE AND UPPER(TRIM(smd.checkpointStatus)) != 'PROGRESSING' AND smd.appStatus NOT IN ('CREATED', 'DEPLOYED')) AS is_checkpoint_issue,
    aat.checkpointNotProgressingThresholdMin,
    LAG((smd.isRecoveryEnabled = TRUE AND UPPER(TRIM(smd.checkpointStatus)) != 'PROGRESSING' AND smd.appStatus NOT IN ('CREATED', 'DEPLOYED')), 1, NULL)
      OVER (PARTITION BY smd.appName ORDER BY smd.batchdate) as prev_is_checkpoint_issue
  FROM
    `striim_watcher_metadata.striim_mon_appdetail` AS smd
  INNER JOIN
    `striim_watcher_metadata.ApplicationAlertThresholds` AS aat
    ON smd.appName = aat.appName
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON smd.batchdate = rh.batchdate
  WHERE
    rh.batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY)
    AND smd.batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY)
    AND aat.checkpointNotProgressingThresholdMin IS NOT NULL
    AND aat.checkpointNotProgressingThresholdMin > 0 
    AND aat.isEnabled IS TRUE
),

-- Step 2: Group consecutive checkpoint issue periods into "spells"
SpellGroups AS (
  SELECT
    appName,
    batchdate,
    clusterName,
    is_checkpoint_issue,
    checkpointNotProgressingThresholdMin,
    -- Create spell_id for consecutive periods of same checkpoint state
    SUM(CASE WHEN is_checkpoint_issue IS DISTINCT FROM prev_is_checkpoint_issue THEN 1 ELSE 0 END) 
      OVER (PARTITION BY appName ORDER BY batchdate) as spell_id,
    -- Get latest record for each app
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY batchdate DESC) as rn
  FROM
    CheckpointHistory
),

-- Step 3: Calculate duration of each spell
SpellDurations AS (
  SELECT
    appName,
    spell_id,
    MIN(checkpointNotProgressingThresholdMin) AS configured_threshold_minutes,
    MAX(batchdate) as spell_end_date,
    TIMESTAMP_DIFF(MAX(batchdate), MIN(batchdate), MINUTE) as duration_of_problem_state_minutes
  FROM
    SpellGroups
  GROUP BY
    appName, spell_id
)

-- Step 4: Generate alerts for qualifying checkpoint issues
SELECT
  sg.clusterName,
  sg.appName AS entity_name,
  lkd.deploymentOn,
  'CHECKPOINT_NOT_PROGRESSING' AS alert_type,
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
  -- Currently experiencing checkpoint issue
  AND sg.is_checkpoint_issue = TRUE
  -- Duration exceeds threshold
  AND sd.duration_of_problem_state_minutes >= sd.configured_threshold_minutes
);
