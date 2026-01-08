-- View: Looker Apps Down Count and List
-- Purpose: Shows count and detailed list of applications that are HALTED or TERMINATED
-- Dashboard: Leadership Dashboard
-- Description: Returns current status of down apps with duration and context for drill-down

CREATE OR REPLACE VIEW mon.looker_apps_down_count AS
WITH LatestAppStatus AS (
  SELECT
    appName,
    MAX(batchdate) as latest_batchdate
  FROM
    mon.striim_mon_appdetail
  GROUP BY
    appName
),
CurrentDownApps AS (
  SELECT
    ad.appName,
    ad.batchdate,
    ad.appStatus,
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
    LatestAppStatus las
    ON ad.appName = las.appName
    AND ad.batchdate = las.latest_batchdate
  INNER JOIN
    mon.striim_mon_table_runhistory rh
    ON ad.batchdate = rh.batchdate
  WHERE
    UPPER(TRIM(ad.appStatus)) IN ('HALTED', 'TERMINATED')
),
AppHistory AS (
  SELECT
    ad.appName,
    ad.batchdate,
    UPPER(TRIM(ad.appStatus)) as appStatus,
    LAG(UPPER(TRIM(ad.appStatus))) OVER (PARTITION BY ad.appName ORDER BY ad.batchdate) as prev_status
  FROM
    mon.striim_mon_appdetail ad
  WHERE
    ad.appName IN (SELECT appName FROM CurrentDownApps)
),
DownSpellStart AS (
  SELECT
    ah.appName,
    MIN(ah.batchdate) as down_since
  FROM
    AppHistory ah
  WHERE
    ah.appStatus IN ('HALTED', 'TERMINATED')
    AND (ah.prev_status IS NULL OR ah.prev_status NOT IN ('HALTED', 'TERMINATED'))
    AND ah.batchdate <= (SELECT MAX(batchdate) FROM CurrentDownApps WHERE appName = ah.appName)
  GROUP BY
    ah.appName
)
SELECT
  da.clusterName,
  da.batchdate,
  da.deploymentOn as nodename,
  da.appName,
  da.appStatus,
  COALESCE(dss.down_since, da.batchdate) as down_since,
  EXTRACT(EPOCH FROM (da.batchdate - COALESCE(dss.down_since, da.batchdate))) / 60 as duration_down_minutes,
  ROUND(EXTRACT(EPOCH FROM (da.batchdate - COALESCE(dss.down_since, da.batchdate))) / 3600.0, 2) as duration_down_hours,
  da.totalInput,
  da.totalOutput,
  da.isBackpressured,
  da.checkpointStatus,
  da.latestActivity
FROM
  CurrentDownApps da
LEFT JOIN
  DownSpellStart dss
  ON da.appName = dss.appName
ORDER BY
  down_since ASC;

