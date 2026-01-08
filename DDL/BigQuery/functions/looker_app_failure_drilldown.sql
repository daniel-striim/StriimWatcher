-- Function: Looker App Failure Drill-down
-- Purpose: Returns log entries near the time of app failure for root cause analysis
-- Dashboard: Operational Dashboard
-- Parameters: 
--   app_name - The application name to investigate
--   failure_batchdate - The batchdate when the failure was detected
--   minutes_window - Minutes before/after to search (default 15)
-- Description: Shows ERROR and WARN logs within ±15 minutes of failure time

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.looker_app_failure_drilldown`(
  app_name STRING,
  failure_batchdate TIMESTAMP,
  minutes_window INT64
)
RETURNS TABLE<
  clusterName STRING,
  log_date TIMESTAMP,
  batchdate TIMESTAMP,
  server STRING,
  appName STRING,
  log_level STRING,
  message STRING,
  contextbuffertext STRING,
  minutes_from_failure FLOAT64
>
AS (
  SELECT
    rh.clusterName,
    lw.log_date,
    lw.batchdate,
    lw.server,
    lw.appName,
    lw.log_level,
    lw.message,
    lw.contextbuffertext,
    TIMESTAMP_DIFF(lw.log_date, failure_batchdate, MINUTE) as minutes_from_failure
  FROM
    `striim_watcher_metadata.striim_mon_log_watcher` lw
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON lw.batchdate = rh.batchdate
  WHERE
    lw.appName = app_name
    AND lw.log_date BETWEEN 
      TIMESTAMP_SUB(failure_batchdate, INTERVAL minutes_window MINUTE)
      AND TIMESTAMP_ADD(failure_batchdate, INTERVAL minutes_window MINUTE)
    AND UPPER(TRIM(lw.log_level)) IN ('ERROR', 'WARN')
  ORDER BY
    lw.log_date DESC
);

