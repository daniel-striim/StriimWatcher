-- Function: get_app_downtime_analysis
-- Purpose: Analyze application downtime patterns over a configurable time period
-- Returns: Downtime metrics including transition counts, longest outage, and most recent outage
-- Parameters: days_back - Number of days to look back (recommended: 30 for last month)

CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.get_app_downtime_analysis`(days_back INT64)
RETURNS TABLE<
  appName STRING,
  total_downtime_transitions INT64,
  longest_downtime_minutes INT64,
  longest_downtime_start TIMESTAMP,
  longest_downtime_end TIMESTAMP,
  most_recent_downtime_start TIMESTAMP,
  most_recent_downtime_end TIMESTAMP,
  most_recent_downtime_minutes INT64,
  minutes_since_last_downtime INT64,
  currently_down BOOL
>
AS (
WITH
-- Step 1: Get all status records within the time period
StatusHistory AS (
  SELECT
    appName,
    batchdate,
    UPPER(TRIM(appStatus)) as status
  FROM
    `striim_watcher_metadata.striim_mon_appdetail`
  WHERE
    batchdate >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL days_back DAY)
),

-- Step 2: Identify status transitions
StatusTransitions AS (
  SELECT
    appName,
    batchdate,
    status,
    LAG(status) OVER (PARTITION BY appName ORDER BY batchdate) as prev_status,
    LAG(batchdate) OVER (PARTITION BY appName ORDER BY batchdate) as prev_batchdate
  FROM
    StatusHistory
),

-- Step 3: Identify downtime starts (transition from RUNNING to non-RUNNING)
DowntimeStarts AS (
  SELECT
    appName,
    batchdate as downtime_start,
    status,
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY batchdate) as downtime_seq
  FROM
    StatusTransitions
  WHERE
    (prev_status = 'RUNNING' AND status != 'RUNNING')
    OR (prev_status IS NULL AND status != 'RUNNING')
),

-- Step 4: Find recovery times (next time app went to RUNNING after each downtime start)
RecoveryTimes AS (
  SELECT
    appName,
    batchdate as recovery_time,
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY batchdate) as recovery_seq
  FROM
    StatusTransitions
  WHERE
    status = 'RUNNING' AND (prev_status IS NULL OR prev_status != 'RUNNING')
),

-- Step 5: Match downtime starts with their corresponding recovery
DowntimePeriods AS (
  SELECT
    ds.appName,
    ds.downtime_start,
    ds.status as downtime_status,
    MIN(rt.recovery_time) as downtime_end
  FROM
    DowntimeStarts ds
  LEFT JOIN RecoveryTimes rt
    ON ds.appName = rt.appName AND rt.recovery_time > ds.downtime_start
  GROUP BY ds.appName, ds.downtime_start, ds.status
),

-- Step 6: Calculate downtime duration
DowntimeWithDuration AS (
  SELECT
    appName,
    downtime_start,
    downtime_status,
    COALESCE(downtime_end, CURRENT_TIMESTAMP()) as downtime_end,
    TIMESTAMP_DIFF(
      COALESCE(downtime_end, CURRENT_TIMESTAMP()),
      downtime_start,
      MINUTE
    ) as downtime_minutes,
    CASE WHEN downtime_end IS NULL THEN TRUE ELSE FALSE END as is_currently_down
  FROM
    DowntimePeriods
),

-- Step 7: Rank downtime periods for longest and most recent
RankedDowntime AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY downtime_minutes DESC, downtime_start DESC) as longest_rank,
    ROW_NUMBER() OVER (PARTITION BY appName ORDER BY downtime_start DESC) as recent_rank
  FROM
    DowntimeWithDuration
),

-- Step 8: Get longest downtime per app
LongestDowntime AS (
  SELECT appName, downtime_start as longest_downtime_start, downtime_end as longest_downtime_end, downtime_minutes as longest_downtime_minutes
  FROM RankedDowntime WHERE longest_rank = 1
),

-- Step 9: Get most recent downtime per app
MostRecentDowntime AS (
  SELECT appName, downtime_start as most_recent_downtime_start, downtime_end as most_recent_downtime_end, downtime_minutes as most_recent_downtime_minutes, is_currently_down
  FROM RankedDowntime WHERE recent_rank = 1
),

-- Step 10: Aggregate metrics per application
AppDowntimeMetrics AS (
  SELECT
    dwd.appName,
    COUNT(*) as total_downtime_transitions,
    ld.longest_downtime_minutes,
    ld.longest_downtime_start,
    ld.longest_downtime_end,
    mrd.most_recent_downtime_start,
    mrd.most_recent_downtime_end,
    mrd.most_recent_downtime_minutes,
    mrd.is_currently_down as currently_down
  FROM
    DowntimeWithDuration dwd
  LEFT JOIN LongestDowntime ld ON dwd.appName = ld.appName
  LEFT JOIN MostRecentDowntime mrd ON dwd.appName = mrd.appName
  GROUP BY
    dwd.appName, ld.longest_downtime_minutes, ld.longest_downtime_start, ld.longest_downtime_end,
    mrd.most_recent_downtime_start, mrd.most_recent_downtime_end, mrd.most_recent_downtime_minutes, mrd.is_currently_down
)

-- Step 11: Final output with time since last downtime
SELECT
  appName,
  total_downtime_transitions,
  longest_downtime_minutes,
  longest_downtime_start,
  longest_downtime_end,
  most_recent_downtime_start,
  most_recent_downtime_end,
  most_recent_downtime_minutes,
  CASE
    WHEN currently_down THEN NULL
    ELSE TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), most_recent_downtime_end, MINUTE)
  END as minutes_since_last_downtime,
  currently_down
FROM
  AppDowntimeMetrics
ORDER BY
  total_downtime_transitions DESC,
  longest_downtime_minutes DESC
);

