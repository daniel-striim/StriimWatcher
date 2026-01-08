-- Function: Looker Smart Alert History
-- Purpose: Returns WARN level log entries for smart alerting and monitoring
-- Dashboard: Operational Dashboard
-- Parameters: days_back - Number of days to look back (default 7)
-- Description: Shows all WARN level logs ordered by most recent, with cluster and app context

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.looker_smart_alert_history`(days_back INT64)
RETURNS TABLE<
  clusterName STRING,
  log_date TIMESTAMP,
  batchdate TIMESTAMP,
  server STRING,
  appName STRING,
  log_level STRING,
  message STRING,
  contextbuffertext STRING
>
AS (
  WITH TimeWindow AS (
    SELECT TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY) as cutoff_time
  )
  SELECT
    rh.clusterName,
    lw.log_date,
    lw.batchdate,
    lw.server,
    lw.appName,
    lw.log_level,
    lw.message,
    lw.contextbuffertext
  FROM
    `striim_watcher_metadata.striim_mon_log_watcher` lw
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON lw.batchdate = rh.batchdate
  CROSS JOIN
    TimeWindow tw
  WHERE
    UPPER(TRIM(lw.log_level)) = 'WARN'
    AND lw.log_date >= tw.cutoff_time
  ORDER BY
    lw.log_date DESC
);

