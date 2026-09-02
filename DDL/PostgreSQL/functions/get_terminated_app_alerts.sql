-- Function: Get Terminated Application Alerts
-- Purpose: Identifies applications that are in a non-RUNNING state for a specified duration
-- Returns: Alerts for applications that have been terminated longer than their threshold

CREATE OR REPLACE FUNCTION mon.get_terminated_app_alerts()
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
-- Step 1: Get application status history with cluster information
AppStatusHistory AS (
  SELECT
    smd.appName,
    smd.batchdate,
    rh.clusterName,
    UPPER(TRIM(smd.appStatus)) as status,
    aat.terminatedthresholdminutes,
    -- Detect when the status changes
    LAG(UPPER(TRIM(smd.appStatus)), 1, '') OVER (PARTITION BY smd.appName ORDER BY smd.batchdate) as prev_status
  FROM
    mon.striim_mon_appdetail AS smd
  INNER JOIN
    mon.applicationalertthresholds AS aat
    ON smd.appName = aat.appname
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON smd.batchdate = rh.batchdate
  WHERE
    rh.batchdate >= CURRENT_TIMESTAMP - INTERVAL '10 days'
    AND smd.batchdate >= CURRENT_TIMESTAMP - INTERVAL '10 days'
    AND aat.terminatedcheckenabled IS TRUE
    AND aat.isenabled IS TRUE
),

-- Step 2: Group consecutive status periods into "spells"
SpellGroups AS (
  SELECT
    appname,
    batchdate,
    clusterName,
    status,
    terminatedthresholdminutes,
    -- Create spell_id for consecutive periods of same status
    SUM(CASE WHEN status != prev_status THEN 1 ELSE 0 END) 
      OVER (PARTITION BY appname ORDER BY batchdate) as spell_id,
    -- Identify the most recent record for each app
    ROW_NUMBER() OVER (PARTITION BY appname ORDER BY batchdate DESC) as rn
  FROM
    AppStatusHistory
),

-- Step 3: Calculate duration of each spell
SpellDurations AS (
  SELECT
    appname,
    spell_id,
    MIN(terminatedthresholdminutes) AS configured_threshold_minutes,
    MAX(batchdate) as spell_end_date,
    -- Calculate the duration of each "spell"
    EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate)))/60 as duration_of_problem_state_minutes
  FROM
    SpellGroups
  GROUP BY
    appname, spell_id
)

-- Step 4: Generate alerts for qualifying terminated applications
SELECT
  sg.clusterName,
  sg.appname AS entity_name,
  lkd.deploymentOn,
  'TERMINATED' AS alert_type,
  sd.spell_end_date AS alert_trigger_time,
  sd.duration_of_problem_state_minutes::BIGINT,
  sd.configured_threshold_minutes
FROM
  SpellGroups sg
JOIN SpellDurations sd 
  ON sg.appname = sd.appname AND sg.spell_id = sd.spell_id
-- Get latest known deployment info (may be from different batch to avoid NULLs)
LEFT JOIN mon.latest_known_deployments lkd
  ON sg.appName = lkd.appName
WHERE
  -- Only evaluate the most recent status for each application
  sg.rn = 1
  -- Only trigger alert if current status is a problem state
  -- (COMPLETED/STOPPED/CREATED/DEPLOYED are legitimate non-error states, not terminations)
  AND sg.status IN ('HALT', 'CRASH', 'UNKNOWN')
  -- And duration has met or exceeded the threshold
  AND sd.duration_of_problem_state_minutes >= sd.configured_threshold_minutes;
$$ LANGUAGE SQL;
