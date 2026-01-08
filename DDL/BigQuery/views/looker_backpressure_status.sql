-- View: Looker Backpressure Status
-- Purpose: Shows current backpressured applications for operational monitoring
-- Dashboard: Operational Dashboard
-- Description: Returns apps currently experiencing backpressure with duration and context

CREATE OR REPLACE VIEW `striim_watcher_metadata.looker_backpressure_status` AS
WITH LatestAppStatus AS (
  SELECT
    appName,
    MAX(batchdate) as latest_batchdate
  FROM
    `striim_watcher_metadata.striim_mon_appdetail`
  GROUP BY
    appName
),
BackpressureHistory AS (
  SELECT
    ad.appName,
    ad.batchdate,
    ad.isBackpressured,
    LAG(ad.isBackpressured) OVER (PARTITION BY ad.appName ORDER BY ad.batchdate) as prev_backpressured
  FROM
    `striim_watcher_metadata.striim_mon_appdetail` ad
  WHERE
    ad.isBackpressured IS NOT NULL
),
BackpressureSpells AS (
  SELECT
    appName,
    batchdate,
    isBackpressured,
    SUM(CASE WHEN isBackpressured != prev_backpressured OR prev_backpressured IS NULL THEN 1 ELSE 0 END) 
      OVER (PARTITION BY appName ORDER BY batchdate) as spell_id
  FROM
    BackpressureHistory
),
CurrentBackpressure AS (
  SELECT
    ad.appName,
    ad.batchdate,
    ad.appStatus,
    ad.isBackpressured,
    ad.totalInput,
    ad.totalOutput,
    ad.deploymentOn,
    ad.checkpointStatus,
    ad.latestActivity,
    rh.clusterName,
    bs.spell_id
  FROM
    `striim_watcher_metadata.striim_mon_appdetail` ad
  INNER JOIN
    LatestAppStatus las
    ON ad.appName = las.appName
    AND ad.batchdate = las.latest_batchdate
  INNER JOIN
    `striim_watcher_metadata.striim_mon_table_runhistory` rh
    ON ad.batchdate = rh.batchdate
  LEFT JOIN
    BackpressureSpells bs
    ON ad.appName = bs.appName
    AND ad.batchdate = bs.batchdate
  WHERE
    ad.isBackpressured = TRUE
),
BackpressureDuration AS (
  SELECT
    cb.appName,
    cb.spell_id,
    MIN(bs.batchdate) as backpressure_started
  FROM
    CurrentBackpressure cb
  INNER JOIN
    BackpressureSpells bs
    ON cb.appName = bs.appName
    AND cb.spell_id = bs.spell_id
    AND bs.isBackpressured = TRUE
  GROUP BY
    cb.appName, cb.spell_id
)
SELECT
  cb.clusterName,
  cb.batchdate,
  cb.deploymentOn as nodename,
  cb.appName,
  cb.appStatus,
  cb.isBackpressured,
  bd.backpressure_started,
  TIMESTAMP_DIFF(cb.batchdate, bd.backpressure_started, MINUTE) as duration_backpressured_minutes,
  ROUND(TIMESTAMP_DIFF(cb.batchdate, bd.backpressure_started, MINUTE) / 60.0, 2) as duration_backpressured_hours,
  cb.totalInput,
  cb.totalOutput,
  cb.checkpointStatus,
  cb.latestActivity
FROM
  CurrentBackpressure cb
LEFT JOIN
  BackpressureDuration bd
  ON cb.appName = bd.appName
  AND cb.spell_id = bd.spell_id
ORDER BY
  duration_backpressured_minutes DESC;

