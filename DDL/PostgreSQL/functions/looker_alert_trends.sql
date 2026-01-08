-- Function: Looker Alert Trends
-- Purpose: Shows alert frequency and patterns over time
-- Dashboard: Leadership Dashboard
-- Description: Returns alert trend analysis for historical reporting

CREATE OR REPLACE FUNCTION mon.looker_alert_trends(days_back INTEGER DEFAULT 30)
RETURNS TABLE(
  alert_date DATE,
  alert_type TEXT,
  alert_count BIGINT,
  avg_duration_minutes DOUBLE PRECISION,
  max_duration_minutes BIGINT,
  unique_apps_affected BIGINT
)
AS $$
WITH AlertHistory AS (
  -- Terminated apps
  SELECT
    DATE(batchdate) as alert_date,
    'TERMINATED' as alert_type,
    appName,
    1 as alert_count,
    0::DOUBLE PRECISION as duration_minutes
  FROM
    mon.striim_mon_appdetail
  WHERE
    batchdate >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
    AND UPPER(TRIM(appStatus)) = 'TERMINATED'

  UNION ALL

  -- Backpressured apps
  SELECT
    DATE(batchdate) as alert_date,
    'BACKPRESSURE' as alert_type,
    appName,
    1 as alert_count,
    0::DOUBLE PRECISION as duration_minutes
  FROM
    mon.striim_mon_appdetail
  WHERE
    batchdate >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
    AND isBackpressured = TRUE

  UNION ALL

  -- Halted apps
  SELECT
    DATE(batchdate) as alert_date,
    'HALTED' as alert_type,
    appName,
    1 as alert_count,
    0::DOUBLE PRECISION as duration_minutes
  FROM
    mon.striim_mon_appdetail
  WHERE
    batchdate >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
    AND UPPER(TRIM(appStatus)) = 'HALTED'

  UNION ALL

  -- Stale sources (freshness > 60 minutes)
  SELECT
    DATE(batchdate) as alert_date,
    'SOURCE_STALE' as alert_type,
    appName,
    1 as alert_count,
    COALESCE(sourceFreshnessMinutes, 0)::DOUBLE PRECISION as duration_minutes
  FROM
    mon.striim_mon_source_information
  WHERE
    batchdate >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
    AND sourceFreshnessMinutes > 60

  UNION ALL

  -- High queue depth
  SELECT
    DATE(batchdate) as alert_date,
    'HIGH_QUEUE_DEPTH' as alert_type,
    appName,
    1 as alert_count,
    0::DOUBLE PRECISION as duration_minutes
  FROM
    mon.striim_mon_datawarehouse_detail
  WHERE
    batchdate >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
    AND total_batches_queued > 10
)
SELECT
  ah.alert_date,
  ah.alert_type,
  SUM(ah.alert_count)::BIGINT as alert_count,
  AVG(ah.duration_minutes) as avg_duration_minutes,
  MAX(ah.duration_minutes)::BIGINT as max_duration_minutes,
  COUNT(DISTINCT ah.appName)::BIGINT as unique_apps_affected
FROM
  AlertHistory ah
GROUP BY
  ah.alert_date, ah.alert_type
ORDER BY
  ah.alert_date DESC, alert_count DESC;
$$ LANGUAGE SQL;

