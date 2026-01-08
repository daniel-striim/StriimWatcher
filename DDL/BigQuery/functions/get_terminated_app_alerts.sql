-- Function: Get Terminated Application Alerts
-- Purpose: Identifies applications that are in a non-RUNNING state for a specified duration
-- Returns: Alerts for applications that have been terminated longer than their threshold

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.get_terminated_app_alerts`()
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
-- Step 1: Get application status history with cluster information
AppStatusHistory AS (
  SELECT
    smd.appName,
    smd.batchdate,
    rh.clusterName,
    UPPER(TRIM(smd.appStatus)) as status,
    aat.terminatedThresholdMinutes,
    -- Detect when the status changes
    LAG(UPPER(TRIM(smd.appStatus)), 1, '') OVER (PARTITION BY smd.appName ORDER BY smd.batchdate) as prev_status
  FROM
    `striim_watcher_metadata.striim_mon_appdetail` AS smd
  INNER JOIN
    `striim_watcher_metadata.ApplicationAlertThresholds` AS aat
    ON smd.appName = aat.appName
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON smd.batchdate = rh.batchdate
  WHERE
    aat.terminatedCheckEnabled IS TRUE
    AND aat.isEnabled IS TRUE
),

-- Step 2: Group consecutive status periods into "spells"
SpellGroups AS (
  SELECT
    appName,
    batchdate,
    clusterName,
    status,
    terminatedThresholdMinutes,
    -- Create spell_id for consecutive periods of same status
    SUM(CASE WHEN status != prev_status THEN 1 ELSE 0 END) 
      OVER (PARTITION BY appName ORDER BY batchdate) as spell_id,
    -- Identify the most recent record for each app
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY batchdate DESC) as rn
  FROM
    AppStatusHistory
),

-- Step 3: Calculate duration of each spell
SpellDurations AS (
  SELECT
    appName,
    spell_id,
    MIN(terminatedThresholdMinutes) AS configured_threshold_minutes,
    MAX(batchdate) as spell_end_date,
    -- Calculate the duration of each "spell"
    TIMESTAMP_DIFF(MAX(batchdate), MIN(batchdate), MINUTE) as duration_of_problem_state_minutes
  FROM
    SpellGroups
  GROUP BY
    appName, spell_id
)

-- Step 4: Generate alerts for qualifying terminated applications
SELECT
  sg.clusterName,
  sg.appName AS entity_name,
  lkd.deploymentOn,
  'TERMINATED' AS alert_type,
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
  -- Only evaluate the most recent status for each application
  sg.rn = 1
  -- Only trigger alert if current status is a problem state
  AND sg.status != 'RUNNING'
  -- And duration has met or exceeded the threshold
  AND sd.duration_of_problem_state_minutes >= sd.configured_threshold_minutes
);
