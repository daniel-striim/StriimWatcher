-- View: Looker Batch Processing
-- Purpose: Shows batch processing efficiency metrics for data warehouse targets
-- Dashboard: Leadership Dashboard
-- Description: Returns batch processing health including queue depth, sizes, and integration times

CREATE OR REPLACE VIEW `striim_watcher_metadata.looker_batch_processing` AS
WITH LatestDWData AS (
  SELECT
    appName,
    targetName,
    MAX(batchdate) as latest_batchdate
  FROM
    `striim_watcher_metadata.striim_mon_datawarehouse_detail`
  GROUP BY
    appName, targetName
)
SELECT
  rh.clusterName,
  dw.batchdate,
  lkd.deploymentOn as nodename,
  dw.appName,
  dw.sourceName,
  dw.targetName,
  dw.targetComponentName,
  dw.target_adaptername,
  dw.projectId,
  dw.Mode,
  dw.streamingUpload,
  dw.optimizedMerge,
  -- Batch configuration
  dw.batch_event_count,
  dw.batch_interval,
  -- Queue metrics
  dw.total_batches_queued,
  dw.total_batches_created,
  dw.total_batches_uploaded,
  dw.total_batches_ignored,
  dw.partition_pruned_batches,
  -- Size metrics
  dw.avg_batch_size_bytes,
  ROUND(dw.avg_batch_size_bytes / 1048576.0, 2) as avg_batch_size_mb,
  dw.last_batch_size_bytes,
  ROUND(dw.last_batch_size_bytes / 1048576.0, 2) as last_batch_size_mb,
  dw.avg_event_count_per_batch,
  -- Time metrics
  dw.avg_integration_time_ms,
  dw.avg_waiting_time_in_queue_ms,
  dw.avg_upload_time_ms,
  dw.avg_merge_time_ms,
  dw.avg_compaction_time_ms,
  dw.max_integration_time_ms,
  dw.min_integration_time_ms,
  dw.last_successful_merge_time,
  -- Last batch details
  dw.last_batch_event_count,
  dw.last_batch_inserts,
  dw.last_batch_updates,
  dw.last_batch_deletes,
  dw.last_batch_ddls,
  dw.last_batch_total_integration_time_ms,
  -- Processing efficiency
  CASE
    WHEN dw.total_batches_created > 0 THEN
      ROUND((dw.total_batches_uploaded * 100.0) / dw.total_batches_created, 2)
    ELSE 100
  END as upload_success_rate_pct,
  -- Queue health status
  CASE
    WHEN dw.total_batches_queued IS NULL THEN 'UNKNOWN'
    WHEN dw.total_batches_queued = 0 THEN 'HEALTHY'
    WHEN dw.total_batches_queued <= 5 THEN 'MODERATE'
    WHEN dw.total_batches_queued <= 20 THEN 'HIGH'
    ELSE 'CRITICAL'
  END as queue_health_status,
  -- Integration time health
  CASE
    WHEN dw.avg_integration_time_ms IS NULL THEN 'UNKNOWN'
    WHEN dw.avg_integration_time_ms <= 5000 THEN 'FAST'
    WHEN dw.avg_integration_time_ms <= 30000 THEN 'NORMAL'
    WHEN dw.avg_integration_time_ms <= 60000 THEN 'SLOW'
    ELSE 'VERY_SLOW'
  END as integration_speed_status
FROM
  `striim_watcher_metadata.striim_mon_datawarehouse_detail` dw
INNER JOIN
  LatestDWData ldw
  ON dw.appName = ldw.appName
  AND dw.targetName = ldw.targetName
  AND dw.batchdate = ldw.latest_batchdate
INNER JOIN
  `striim_watcher_metadata.striim_mon_table_runhistory` rh
  ON dw.batchdate = rh.batchdate
LEFT JOIN
  `striim_watcher_metadata.latest_known_deployments` lkd
  ON dw.appName = lkd.appName
ORDER BY
  dw.total_batches_queued DESC NULLS LAST;

