-- Function: Looker Throughput Trends
-- Purpose: Shows source and target throughput over time
-- Dashboard: Leadership Dashboard
-- Description: Returns throughput metrics with trends for capacity planning

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.looker_throughput_trends`(days_back INT64)
RETURNS TABLE<
  clusterName STRING,
  batchdate TIMESTAMP,
  batch_hour TIMESTAMP,
  total_source_input_rate FLOAT64,
  total_target_output_rate FLOAT64,
  avg_source_cpu_rate FLOAT64,
  avg_target_cpu_rate FLOAT64,
  source_count INT64,
  target_count INT64,
  avg_source_freshness_minutes FLOAT64
>
AS (
WITH SourceMetrics AS (
  SELECT
    rh.clusterName,
    si.batchdate,
    TIMESTAMP_TRUNC(si.batchdate, HOUR) as batch_hour,
    SUM(COALESCE(si.inputRate, 0)) as total_source_input_rate,
    AVG(si.cpuRate) as avg_source_cpu_rate,
    COUNT(DISTINCT si.componentName) as source_count,
    AVG(si.sourceFreshnessMinutes) as avg_source_freshness_minutes
  FROM
    `striim_watcher_metadata.striim_mon_source_information` si
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON si.batchdate = rh.batchdate
  WHERE
    si.batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY)
  GROUP BY
    rh.clusterName, si.batchdate, batch_hour
),
TargetMetrics AS (
  SELECT
    ti.batchdate,
    SUM(COALESCE(ti.targetRate, 0)) as total_target_output_rate,
    AVG(ti.cpuRate) as avg_target_cpu_rate,
    COUNT(DISTINCT ti.componentName) as target_count
  FROM
    `striim_watcher_metadata.striim_mon_target_information` ti
  WHERE
    ti.batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY)
  GROUP BY
    ti.batchdate
)
SELECT
  sm.clusterName,
  sm.batchdate,
  sm.batch_hour,
  sm.total_source_input_rate,
  COALESCE(tm.total_target_output_rate, 0) as total_target_output_rate,
  sm.avg_source_cpu_rate,
  tm.avg_target_cpu_rate,
  sm.source_count,
  COALESCE(tm.target_count, 0) as target_count,
  sm.avg_source_freshness_minutes
FROM
  SourceMetrics sm
LEFT JOIN
  TargetMetrics tm
  ON sm.batchdate = tm.batchdate
ORDER BY
  sm.batchdate
);

