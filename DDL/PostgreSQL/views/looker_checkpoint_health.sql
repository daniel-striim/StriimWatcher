-- View: Looker Checkpoint Health
-- Purpose: Shows checkpoint health status for applications with recovery enabled
-- Dashboard: Operational Dashboard
-- Description: Returns checkpoint status with time since last checkpoint and frequency metrics

CREATE OR REPLACE VIEW mon.looker_checkpoint_health AS
WITH LatestAppStatus AS (
  SELECT
    appName,
    MAX(batchdate) as latest_batchdate
  FROM
    mon.striim_mon_appdetail
  GROUP BY
    appName
),
LatestCheckpoints AS (
  SELECT
    appName,
    MAX(checkpointRecordedTime) as last_checkpoint_time,
    COUNT(*) as total_checkpoints_24h
  FROM
    mon.striim_mon_checkpoint_history
  WHERE
    batchdate >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
  GROUP BY
    appName
),
CheckpointFrequency AS (
  SELECT
    appName,
    COUNT(*) as checkpoints_last_hour
  FROM
    mon.striim_mon_checkpoint_history
  WHERE
    checkpointRecordedTime >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
  GROUP BY
    appName
)
SELECT
  rh.clusterName,
  ad.batchdate,
  ad.deploymentOn as nodename,
  ad.appName,
  ad.appStatus,
  ad.isRecoveryEnabled,
  ad.recoverySetting,
  ad.checkpointStatus,
  lc.last_checkpoint_time,
  EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - lc.last_checkpoint_time)) / 60 as minutes_since_last_checkpoint,
  COALESCE(lc.total_checkpoints_24h, 0) as checkpoints_last_24h,
  COALESCE(cf.checkpoints_last_hour, 0) as checkpoints_last_hour,
  CASE
    WHEN ad.isRecoveryEnabled = FALSE THEN 'RECOVERY_DISABLED'
    WHEN lc.last_checkpoint_time IS NULL THEN 'NO_CHECKPOINTS'
    WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - lc.last_checkpoint_time)) / 60 > 60 THEN 'STALE'
    WHEN ad.checkpointStatus LIKE '%lag%' OR ad.checkpointStatus LIKE '%Lag%' THEN 'LAGGING'
    ELSE 'HEALTHY'
  END as checkpoint_health_status,
  ad.latestActivity
FROM
  mon.striim_mon_appdetail ad
INNER JOIN
  LatestAppStatus las
  ON ad.appName = las.appName
  AND ad.batchdate = las.latest_batchdate
INNER JOIN
  mon.striim_mon_table_runhistory rh
  ON ad.batchdate = rh.batchdate
LEFT JOIN
  LatestCheckpoints lc
  ON ad.appName = lc.appName
LEFT JOIN
  CheckpointFrequency cf
  ON ad.appName = cf.appName
WHERE
  ad.isRecoveryEnabled = TRUE
  OR lc.last_checkpoint_time IS NOT NULL
ORDER BY
  minutes_since_last_checkpoint DESC NULLS FIRST;

