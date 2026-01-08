-- Function: Looker App Failure List
-- Purpose: Returns list of applications that have been TERMINATED within a specified time window
-- Dashboard: Operational Dashboard
-- Parameters: days_back - Number of days to look back (recommended: 30)
-- Description: Shows all TERMINATED apps with failure time, duration, and context for drill-down

CREATE OR REPLACE FUNCTION mon.looker_app_failure_list(days_back INTEGER DEFAULT 30)
RETURNS TABLE(
  clusterName TEXT,
  batchdate TIMESTAMP,
  nodename TEXT,
  appName TEXT,
  appStatus TEXT,
  failure_time TIMESTAMP,
  duration_terminated_minutes BIGINT,
  totalInput BIGINT,
  totalOutput BIGINT,
  isBackpressured BOOLEAN,
  checkpointStatus TEXT,
  latestActivity TIMESTAMP
)
AS $$
WITH AppHistory AS (
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
    mon.striim_mon_appdetail ad
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON ad.batchdate = rh.batchdate
  WHERE
    ad.batchdate >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
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
  CAST(EXTRACT(EPOCH FROM (lt.batchdate - COALESCE(tt.failure_start_time, lt.batchdate))) / 60 AS BIGINT) as duration_terminated_minutes,
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
  failure_time DESC;
$$ LANGUAGE SQL;

