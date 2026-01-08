-- Function: Looker Data Flowing Graph
-- Purpose: Returns cumulative data flow metrics and rates for all RUNNING applications
-- Dashboard: Leadership Dashboard
-- Parameters: days_back - Number of days of history to include (default 7)
-- Description: Shows totalInput and totalOutput over time with rate calculations between batches

CREATE OR REPLACE FUNCTION mon.looker_data_flowing_graph(days_back INTEGER DEFAULT 7)
RETURNS TABLE(
  clusterName TEXT,
  batchdate TIMESTAMP,
  total_input_cumulative BIGINT,
  total_output_cumulative BIGINT,
  total_input_rate BIGINT,
  total_output_rate BIGINT,
  running_apps_count BIGINT,
  minutes_since_last_batch DOUBLE PRECISION
)
AS $$
WITH RunningAppsData AS (
  SELECT
    rh.clusterName,
    ad.batchdate,
    SUM(ad.totalInput)::BIGINT as total_input_cumulative,
    SUM(ad.totalOutput)::BIGINT as total_output_cumulative,
    COUNT(DISTINCT ad.appName)::BIGINT as running_apps_count
  FROM
    mon.striim_mon_appdetail ad
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON ad.batchdate = rh.batchdate
  WHERE
    UPPER(TRIM(ad.appStatus)) = 'RUNNING'
    AND ad.batchdate >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
  GROUP BY
    rh.clusterName, ad.batchdate
),
DataWithLag AS (
  SELECT
    rad.clusterName,
    rad.batchdate,
    rad.total_input_cumulative,
    rad.total_output_cumulative,
    rad.running_apps_count,
    LAG(rad.total_input_cumulative) OVER (PARTITION BY rad.clusterName ORDER BY rad.batchdate) as prev_total_input,
    LAG(rad.total_output_cumulative) OVER (PARTITION BY rad.clusterName ORDER BY rad.batchdate) as prev_total_output,
    LAG(rad.batchdate) OVER (PARTITION BY rad.clusterName ORDER BY rad.batchdate) as prev_batchdate
  FROM
    RunningAppsData rad
)
SELECT
  dwl.clusterName,
  dwl.batchdate,
  dwl.total_input_cumulative,
  dwl.total_output_cumulative,
  CASE 
    WHEN dwl.prev_total_input IS NOT NULL 
    THEN (dwl.total_input_cumulative - dwl.prev_total_input)::BIGINT
    ELSE 0::BIGINT
  END as total_input_rate,
  CASE 
    WHEN dwl.prev_total_output IS NOT NULL 
    THEN (dwl.total_output_cumulative - dwl.prev_total_output)::BIGINT
    ELSE 0::BIGINT
  END as total_output_rate,
  dwl.running_apps_count,
  CASE
    WHEN dwl.prev_batchdate IS NOT NULL
    THEN EXTRACT(EPOCH FROM (dwl.batchdate - dwl.prev_batchdate)) / 60
    ELSE NULL
  END as minutes_since_last_batch
FROM
  DataWithLag dwl
ORDER BY
  dwl.batchdate DESC;
$$ LANGUAGE SQL;

