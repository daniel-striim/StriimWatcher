-- Function: Get Checkpoint Not Progressing Alerts
-- Purpose: Identifies apps where recovery is enabled but checkpoints are not progressing
-- Returns: Alerts for applications with checkpoint progression issues

CREATE OR REPLACE FUNCTION mon.get_checkpoint_alerts()
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
-- Step 1: Get checkpoint status history with cluster information
CheckpointHistory AS (
  SELECT
    smd.appName,
    smd.batchdate,
    rh.clusterName,
    -- Define checkpoint issue condition
    (smd.isRecoveryEnabled = TRUE AND UPPER(TRIM(smd.checkpointStatus)) != 'PROGRESSING') AS is_checkpoint_issue,
    aat.checkpointnotprogressingthresholdmin,
    LAG((smd.isRecoveryEnabled = TRUE AND UPPER(TRIM(smd.checkpointStatus)) != 'PROGRESSING'), 1, NULL)
      OVER (PARTITION BY smd.appName ORDER BY smd.batchdate) as prev_is_checkpoint_issue
  FROM
    mon.striim_mon_appdetail AS smd
  INNER JOIN
    mon.applicationalertthresholds AS aat
    ON smd.appName = aat.appname
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON smd.batchdate = rh.batchdate
  WHERE
    aat.checkpointnotprogressingthresholdmin IS NOT NULL
    AND aat.checkpointnotprogressingthresholdmin > 0
    AND aat.isenabled IS TRUE
),

-- Step 2: Group consecutive checkpoint issue periods into "spells"
SpellGroups AS (
  SELECT
    appName,
    batchdate,
    clusterName,
    is_checkpoint_issue,
    checkpointnotprogressingthresholdmin,
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
    MIN(checkpointnotprogressingthresholdmin) AS configured_threshold_minutes,
    MAX(batchdate) as spell_end_date,
    EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate)))/60 as duration_of_problem_state_minutes
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
  sd.duration_of_problem_state_minutes::BIGINT,
  sd.configured_threshold_minutes
FROM
  SpellGroups sg
JOIN SpellDurations sd 
  ON sg.appName = sd.appName AND sg.spell_id = sd.spell_id
-- Get latest known deployment info (may be from different batch to avoid NULLs)
LEFT JOIN mon.latest_known_deployments lkd
  ON sg.appName = lkd.appName
WHERE
  -- Evaluate latest status only
  sg.rn = 1
  -- Currently experiencing checkpoint issue
  AND sg.is_checkpoint_issue = TRUE
  -- Duration exceeds threshold
  AND sd.duration_of_problem_state_minutes >= sd.configured_threshold_minutes;
$$ LANGUAGE SQL;
