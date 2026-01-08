-- Function: Looker Throughput Trends
-- Purpose: Shows source and target throughput over time
-- Dashboard: Leadership Dashboard
-- Description: Returns throughput metrics with trends for capacity planning

CREATE OR REPLACE FUNCTION mon.looker_throughput_trends(days_back INTEGER DEFAULT 30)
RETURNS TABLE(
  clusterName TEXT,
  batchdate TIMESTAMP,
  batch_hour TIMESTAMP,
  total_source_input_rate DOUBLE PRECISION,
  total_target_output_rate DOUBLE PRECISION,
  avg_source_cpu_rate DOUBLE PRECISION,
  avg_target_cpu_rate DOUBLE PRECISION,
  source_count BIGINT,
  target_count BIGINT,
  avg_source_freshness_minutes DOUBLE PRECISION
)
AS $$
WITH SourceMetrics AS (
  SELECT
    rh.clusterName,
    si.batchdate,
    DATE_TRUNC('hour', si.batchdate) as batch_hour,
    SUM(COALESCE(si.inputRate, 0)) as total_source_input_rate,
    AVG(si.cpuRate) as avg_source_cpu_rate,
    COUNT(DISTINCT si.componentName)::BIGINT as source_count,
    AVG(si.sourceFreshnessMinutes) as avg_source_freshness_minutes
  FROM
    mon.striim_mon_source_information si
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON si.batchdate = rh.batchdate
  WHERE
    si.batchdate >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
  GROUP BY
    rh.clusterName, si.batchdate, batch_hour
),
TargetMetrics AS (
  SELECT
    ti.batchdate,
    SUM(COALESCE(ti.targetRate, 0)) as total_target_output_rate,
    AVG(ti.cpuRate) as avg_target_cpu_rate,
    COUNT(DISTINCT ti.componentName)::BIGINT as target_count
  FROM
    mon.striim_mon_target_information ti
  WHERE
    ti.batchdate >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
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
  sm.batchdate;
$$ LANGUAGE SQL;

