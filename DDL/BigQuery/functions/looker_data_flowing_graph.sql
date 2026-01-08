-- Function: Looker Data Flowing Graph
-- Purpose: Returns cumulative data flow metrics and rates for all RUNNING applications
-- Dashboard: Leadership Dashboard
-- Parameters: days_back - Number of days of history to include (default 7)
-- Description: Shows totalInput and totalOutput over time with rate calculations between batches

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.looker_data_flowing_graph`(days_back INT64)
RETURNS TABLE<
  clusterName STRING,
  batchdate TIMESTAMP,
  total_input_cumulative INT64,
  total_output_cumulative INT64,
  total_input_rate INT64,
  total_output_rate INT64,
  running_apps_count INT64,
  minutes_since_last_batch FLOAT64
>
AS (
  WITH TimeWindow AS (
    SELECT TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY) as cutoff_time
  ),
  RunningAppsData AS (
    SELECT
      rh.clusterName,
      ad.batchdate,
      SUM(ad.totalInput) as total_input_cumulative,
      SUM(ad.totalOutput) as total_output_cumulative,
      COUNT(DISTINCT ad.appName) as running_apps_count
    FROM
      `striim_watcher_metadata.striim_mon_appdetail` ad
    INNER JOIN
      `striim_watcher_metadata.striim_mon_table_runhistory` rh
      ON ad.batchdate = rh.batchdate
    CROSS JOIN
      TimeWindow tw
    WHERE
      UPPER(TRIM(ad.appStatus)) = 'RUNNING'
      AND ad.batchdate >= tw.cutoff_time
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
      THEN dwl.total_input_cumulative - dwl.prev_total_input
      ELSE 0
    END as total_input_rate,
    CASE 
      WHEN dwl.prev_total_output IS NOT NULL 
      THEN dwl.total_output_cumulative - dwl.prev_total_output
      ELSE 0
    END as total_output_rate,
    dwl.running_apps_count,
    CASE
      WHEN dwl.prev_batchdate IS NOT NULL
      THEN TIMESTAMP_DIFF(dwl.batchdate, dwl.prev_batchdate, MINUTE)
      ELSE NULL
    END as minutes_since_last_batch
  FROM
    DataWithLag dwl
  ORDER BY
    dwl.batchdate DESC
);

