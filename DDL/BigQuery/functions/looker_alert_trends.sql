-- Function: Looker Alert Trends
-- Purpose: Shows alert frequency and patterns over time
-- Dashboard: Leadership Dashboard
-- Description: Returns alert trend analysis for historical reporting

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.looker_alert_trends`(days_back INT64)
RETURNS TABLE<
  alert_date DATE,
  alert_type STRING,
  alert_count INT64,
  avg_duration_minutes FLOAT64,
  max_duration_minutes INT64,
  unique_apps_affected INT64
>
AS (
WITH AlertHistory AS (
  -- Terminated apps
  SELECT
    DATE(batchdate) as alert_date,
    'TERMINATED' as alert_type,
    appName,
    1 as alert_count,
    0 as duration_minutes
  FROM
    `striim_watcher_metadata.striim_mon_appdetail`
  WHERE
    batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY)
    AND UPPER(TRIM(appStatus)) = 'TERMINATED'

  UNION ALL

  -- Backpressured apps
  SELECT
    DATE(batchdate) as alert_date,
    'BACKPRESSURE' as alert_type,
    appName,
    1 as alert_count,
    0 as duration_minutes
  FROM
    `striim_watcher_metadata.striim_mon_appdetail`
  WHERE
    batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY)
    AND isBackpressured = TRUE

  UNION ALL

  -- Halted apps
  SELECT
    DATE(batchdate) as alert_date,
    'HALTED' as alert_type,
    appName,
    1 as alert_count,
    0 as duration_minutes
  FROM
    `striim_watcher_metadata.striim_mon_appdetail`
  WHERE
    batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY)
    AND UPPER(TRIM(appStatus)) = 'HALTED'

  UNION ALL

  -- Stale sources (freshness > 60 minutes)
  SELECT
    DATE(batchdate) as alert_date,
    'SOURCE_STALE' as alert_type,
    appName,
    1 as alert_count,
    COALESCE(sourceFreshnessMinutes, 0) as duration_minutes
  FROM
    `striim_watcher_metadata.striim_mon_source_information`
  WHERE
    batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY)
    AND sourceFreshnessMinutes > 60

  UNION ALL

  -- High queue depth
  SELECT
    DATE(batchdate) as alert_date,
    'HIGH_QUEUE_DEPTH' as alert_type,
    appName,
    1 as alert_count,
    0 as duration_minutes
  FROM
    `striim_watcher_metadata.striim_mon_datawarehouse_detail`
  WHERE
    batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY)
    AND total_batches_queued > 10
)
SELECT
  alert_date,
  alert_type,
  SUM(alert_count) as alert_count,
  AVG(duration_minutes) as avg_duration_minutes,
  MAX(CAST(duration_minutes AS INT64)) as max_duration_minutes,
  COUNT(DISTINCT appName) as unique_apps_affected
FROM
  AlertHistory
GROUP BY
  alert_date, alert_type
ORDER BY
  alert_date DESC, alert_count DESC
);

