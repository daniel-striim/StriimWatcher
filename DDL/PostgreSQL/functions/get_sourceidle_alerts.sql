-- Function: Get Source Idle Alerts
-- Purpose: Identifies applications with sources that have been idle for longer than configured threshold
-- Returns: Alerts for applications experiencing source inactivity issues

CREATE OR REPLACE FUNCTION mon.get_sourceidle_alerts()
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
-- Step 1: Get source idle log entries with cluster information
SourceIdleHistory AS (
  SELECT
    slw.appName,
    slw.batchdate,
    slw.log_date,
    rh.clusterName,
    slw.contextbuffertext,
    aat.sourceinactivitythresholdminutes,
    -- Extract the seconds value from contextbuffertext using regex
    -- Example: "Source_Idle, Medium: WEB, Message: Source admin.SWA: No new event read in last 62.351 seconds."
    CAST(
      NULLIF(REGEXP_REPLACE(slw.contextbuffertext, '.*last\s+([0-9]+\.?[0-9]*)\s+seconds.*', '\1'), slw.contextbuffertext)
      AS DOUBLE PRECISION
    ) as idle_seconds,
    ROW_NUMBER() OVER (PARTITION BY slw.appName ORDER BY slw.batchdate DESC, slw.log_date DESC) as rn
  FROM
    mon.striim_mon_log_watcher AS slw
  INNER JOIN
    mon.applicationalertthresholds AS aat
    ON slw.appName = aat.appname
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON slw.batchdate = rh.batchdate
  WHERE
    UPPER(TRIM(slw.log_level)) = 'WARN'
    AND slw.contextbuffertext LIKE 'Source_Idle%'
    AND aat.sourceinactivitythresholdminutes IS NOT NULL
    AND aat.sourceinactivitythresholdminutes > 0
    AND aat.isenabled = TRUE
),

-- Step 2: Calculate duration and filter for threshold violations
ThresholdViolations AS (
  SELECT
    appName,
    batchdate,
    log_date,
    clusterName,
    contextbuffertext,
    sourceinactivitythresholdminutes,
    idle_seconds,
    idle_seconds / 60.0 as idle_minutes,
    rn
  FROM
    SourceIdleHistory
  WHERE
    idle_seconds IS NOT NULL
    AND (idle_seconds / 60.0) >= sourceinactivitythresholdminutes
)

-- Step 3: Generate alerts for qualifying source idle situations
SELECT
  tv.clusterName,
  tv.appName AS entity_name,
  lkd.deploymentOn,
  'SOURCE_IDLE' AS alert_type,
  tv.log_date AS alert_trigger_time,
  CAST(tv.idle_minutes AS BIGINT) as duration_of_problem_state_minutes,
  CAST(tv.sourceinactivitythresholdminutes AS BIGINT) as configured_threshold_minutes
FROM
  ThresholdViolations tv
LEFT JOIN mon.latest_known_deployments lkd
  ON tv.appName = lkd.appName
WHERE
  tv.rn = 1
ORDER BY
  tv.clusterName,
  tv.appName;
$$ LANGUAGE SQL;

