-- Function: Get Source Idle Alerts
-- Purpose: Identifies applications with sources that have been idle for longer than configured threshold
-- Returns: Alerts for applications experiencing source inactivity issues

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.get_sourceidle_alerts`()
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
-- Step 1: Get source idle log entries with cluster information
SourceIdleHistory AS (
  SELECT
    slw.appName,
    slw.batchdate,
    slw.log_date,
    rh.clusterName,
    slw.contextbuffertext,
    aat.sourceInactivityThresholdMinutes,
    -- Extract the seconds value from contextbuffertext using regex
    -- Example: "Source_Idle, Medium: WEB, Message: Source admin.SWA: No new event read in last 62.351 seconds."
    SAFE_CAST(
      REGEXP_EXTRACT(slw.contextbuffertext, r'last\s+([0-9]+\.?[0-9]*)\s+seconds') 
      AS FLOAT64
    ) as idle_seconds,
    -- Get the most recent record for each app
    ROW_NUMBER() OVER (PARTITION BY slw.appName ORDER BY slw.batchdate DESC, slw.log_date DESC) as rn
  FROM
    `striim_watcher_metadata.striim_mon_log_watcher` AS slw
  INNER JOIN
    `striim_watcher_metadata.ApplicationAlertThresholds` AS aat
    ON slw.appName = aat.appName
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON slw.batchdate = rh.batchdate
  WHERE
    rh.batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 DAY)
    AND slw.batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 DAY)
    -- Filter for WARN level logs
    AND UPPER(TRIM(slw.log_level)) = 'WARN'
    -- Filter for Source_Idle messages
    AND slw.contextbuffertext LIKE 'Source_Idle%'
    -- Ensure we have a valid threshold configured
    AND aat.sourceInactivityThresholdMinutes IS NOT NULL 
    AND aat.sourceInactivityThresholdMinutes > 0 
    AND aat.isEnabled IS TRUE
),

-- Step 2: Calculate duration and filter for threshold violations
ThresholdViolations AS (
  SELECT
    appName,
    batchdate,
    log_date,
    clusterName,
    contextbuffertext,
    sourceInactivityThresholdMinutes,
    idle_seconds,
    -- Convert seconds to minutes for comparison
    idle_seconds / 60.0 as idle_minutes,
    rn
  FROM
    SourceIdleHistory
  WHERE
    -- Only include records where we successfully extracted the seconds value
    idle_seconds IS NOT NULL
    -- Only include records where idle time exceeds the threshold
    AND (idle_seconds / 60.0) >= sourceInactivityThresholdMinutes
)

-- Step 3: Generate alerts for qualifying source idle situations
SELECT
  tv.clusterName,
  tv.appName AS entity_name,
  lkd.deploymentOn,
  'SOURCE_IDLE' AS alert_type,
  tv.log_date AS alert_trigger_time,
  CAST(tv.idle_minutes AS INT64) as duration_of_problem_state_minutes,
  tv.sourceInactivityThresholdMinutes as configured_threshold_minutes
FROM
  ThresholdViolations tv
-- Get latest known deployment info (may be from different batch to avoid NULLs)
LEFT JOIN `striim_watcher_metadata.latest_known_deployments` lkd
  ON tv.appName = lkd.appName
WHERE
  -- Evaluate latest status only (most recent log entry per app)
  tv.rn = 1
ORDER BY
  tv.clusterName,
  tv.appName
);
