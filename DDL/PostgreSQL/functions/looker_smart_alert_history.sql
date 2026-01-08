-- Function: Looker Smart Alert History
-- Purpose: Returns WARN level log entries for smart alerting and monitoring
-- Dashboard: Operational Dashboard
-- Parameters: days_back - Number of days to look back (default 7)
-- Description: Shows all WARN level logs ordered by most recent, with cluster and app context

CREATE OR REPLACE FUNCTION mon.looker_smart_alert_history(days_back INTEGER DEFAULT 7)
RETURNS TABLE(
  clusterName TEXT,
  log_date TIMESTAMP,
  batchdate TIMESTAMP,
  server TEXT,
  appName TEXT,
  log_level TEXT,
  message TEXT,
  contextbuffertext TEXT
)
AS $$
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
    mon.striim_mon_log_watcher lw
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON lw.batchdate = rh.batchdate
  WHERE
    UPPER(TRIM(lw.log_level)) = 'WARN'
    AND lw.log_date >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
  ORDER BY
    lw.log_date DESC;
$$ LANGUAGE SQL;

