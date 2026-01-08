-- Function: Looker Lag Graph
-- Purpose: Returns lag metrics with 7-day rolling average and current lag for trend analysis
-- Dashboard: Leadership Dashboard
-- Parameters: 
--   days_back - Number of days of history to include (default 30)
--   filter_app_name - Optional app name filter (NULL for all apps)
--   filter_source_type - Optional source type filter (NULL for all)
--   filter_target_type - Optional target type filter (NULL for all)
-- Description: Shows avgLEE over time with 7-day rolling average, filterable by app and types

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.looker_lag_graph`(
  days_back INT64,
  filter_app_name STRING,
  filter_source_type STRING,
  filter_target_type STRING
)
RETURNS TABLE<
  clusterName STRING,
  batchdate TIMESTAMP,
  appName STRING,
  sourceApp STRING,
  sourceName STRING,
  sourceType STRING,
  targetApp STRING,
  targetName STRING,
  targetType STRING,
  current_lag NUMERIC,
  rolling_avg_7day NUMERIC,
  min_lag NUMERIC,
  max_lag NUMERIC
>
AS (
  WITH TimeWindow AS (
    SELECT TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY) as cutoff_time
  ),
  FilteredLagData AS (
    SELECT
      rh.clusterName,
      lee.batchdate,
      COALESCE(lee.sourceApp, lee.targetApp, 'Unknown') as appName,
      lee.sourceApp,
      lee.sourceName,
      lee.sourceType,
      lee.targetApp,
      lee.targetName,
      lee.targetType,
      lee.avgLEE as current_lag,
      lee.minLEE,
      lee.maxLEE
    FROM
      `striim_watcher_metadata.striim_mon_lee` lee
    INNER JOIN
      `striim_watcher_metadata.striim_mon_table_runhistory` rh
      ON lee.batchdate = rh.batchdate
    CROSS JOIN
      TimeWindow tw
    WHERE
      lee.batchdate >= tw.cutoff_time
      AND (filter_app_name IS NULL OR lee.sourceApp = filter_app_name OR lee.targetApp = filter_app_name)
      AND (filter_source_type IS NULL OR lee.sourceType = filter_source_type)
      AND (filter_target_type IS NULL OR lee.targetType = filter_target_type)
      AND lee.avgLEE IS NOT NULL
  )
  SELECT
    fld.clusterName,
    fld.batchdate,
    fld.appName,
    fld.sourceApp,
    fld.sourceName,
    fld.sourceType,
    fld.targetApp,
    fld.targetName,
    fld.targetType,
    fld.current_lag,
    AVG(fld.current_lag) OVER (
      PARTITION BY fld.appName, fld.sourceName, fld.targetName
      ORDER BY fld.batchdate
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as rolling_avg_7day,
    fld.minLEE as min_lag,
    fld.maxLEE as max_lag
  FROM
    FilteredLagData fld
  ORDER BY
    fld.batchdate DESC, fld.appName
);

