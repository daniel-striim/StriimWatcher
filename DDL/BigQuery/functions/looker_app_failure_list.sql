-- Function: Looker App Failure List
-- Purpose: Returns list of applications that have been TERMINATED within a specified time window
-- Dashboard: Operational Dashboard
-- Parameters: days_back - Number of days to look back (recommended: 30)
-- Description: Shows all TERMINATED apps with failure time, duration, and context for drill-down

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.looker_app_failure_list`(days_back INT64)
RETURNS TABLE<
  clusterName STRING,
  batchdate TIMESTAMP,
  nodename STRING,
  appName STRING,
  appStatus STRING,
  failure_time TIMESTAMP,
  duration_terminated_minutes INT64,
  totalInput INT64,
  totalOutput INT64,
  isBackpressured BOOL,
  checkpointStatus STRING,
  latestActivity TIMESTAMP
>
AS (
  WITH TimeWindow AS (
    SELECT TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY) as cutoff_time
  ),
  AppHistory AS (
    -- Get app status history with previous status for transition detection
    SELECT
      ad.appName,
      ad.batchdate,
      UPPER(TRIM(ad.appStatus)) as appStatus,
      LAG(UPPER(TRIM(ad.appStatus))) OVER (PARTITION BY ad.appName ORDER BY ad.batchdate) as prev_status,
      ad.totalInput,
      ad.totalOutput,
      ad.isBackpressured,
      ad.checkpointStatus,
      ad.latestActivity,
      ad.deploymentOn,
      rh.clusterName
    FROM
      `striim_watcher_metadata.striim_mon_appdetail` ad
    INNER JOIN
      `striim_watcher_metadata.striim_mon_table_runhistory` rh
      ON ad.batchdate = rh.batchdate
    CROSS JOIN
      TimeWindow tw
    WHERE
      ad.batchdate >= tw.cutoff_time
  ),
  TerminatedTransitions AS (
    -- Find when apps transitioned to TERMINATED state
    SELECT
      ah.appName,
      MIN(ah.batchdate) as failure_start_time
    FROM
      AppHistory ah
    WHERE
      ah.appStatus = 'TERMINATED'
      AND (ah.prev_status IS NULL OR ah.prev_status != 'TERMINATED')
    GROUP BY
      ah.appName
  ),
  LatestTerminated AS (
    -- Get the most recent record for each terminated app
    SELECT
      ah.clusterName,
      ah.batchdate,
      ah.deploymentOn as nodename,
      ah.appName,
      ah.appStatus,
      ah.totalInput,
      ah.totalOutput,
      ah.isBackpressured,
      ah.checkpointStatus,
      ah.latestActivity,
      ROW_NUMBER() OVER (PARTITION BY ah.appName ORDER BY ah.batchdate DESC) as rn
    FROM
      AppHistory ah
    WHERE
      ah.appStatus = 'TERMINATED'
  )
  SELECT
    lt.clusterName,
    lt.batchdate,
    lt.nodename,
    lt.appName,
    lt.appStatus,
    COALESCE(tt.failure_start_time, lt.batchdate) as failure_time,
    TIMESTAMP_DIFF(lt.batchdate, COALESCE(tt.failure_start_time, lt.batchdate), MINUTE) as duration_terminated_minutes,
    lt.totalInput,
    lt.totalOutput,
    lt.isBackpressured,
    lt.checkpointStatus,
    lt.latestActivity
  FROM
    LatestTerminated lt
  LEFT JOIN
    TerminatedTransitions tt
    ON lt.appName = tt.appName
  WHERE
    lt.rn = 1  -- Only show the most recent status for each app
  ORDER BY
    failure_time DESC
);

