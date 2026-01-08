-- View: Looker Data Integrity
-- Purpose: Shows source vs target comparison metrics for data integrity monitoring
-- Dashboard: Leadership Dashboard
-- Description: Returns current sync status and drift detection for all tables

CREATE OR REPLACE VIEW `striim_watcher_metadata.looker_data_integrity` AS
WITH LatestComparisonData AS (
  SELECT
    appName,
    sourceName,
    targetName,
    MAX(batchdate) as latest_batchdate
  FROM
    `striim_watcher_metadata.striim_mon_table_comparison`
  GROUP BY
    appName, sourceName, targetName
)
SELECT
  rh.clusterName,
  tc.batchdate,
  lkd.deploymentOn as nodename,
  tc.appName,
  tc.sourceName,
  tc.targetName,
  tc.sourceComponentName,
  tc.targetComponentName,
  -- Inserts
  tc.srcNumOfInserts,
  tc.tgtNumOfInserts,
  tc.diffNumOfInserts,
  -- Updates
  tc.srcNumOfUpdates,
  tc.tgtNumOfUpdates,
  tc.diffNumOfUpdates,
  -- Deletes
  tc.srcNumOfDeletes,
  tc.tgtNumOfDeletes,
  tc.diffNumOfDeletes,
  -- DDLs
  tc.srcNumOfDdls,
  tc.tgtNumOfDdls,
  tc.diffNumOfDdls,
  -- PK Updates
  tc.srcNumOfPkupdates,
  tc.tgtNumOfPkupdates,
  tc.diffNumOfPkupdates,
  -- Total differences
  ABS(COALESCE(tc.diffNumOfInserts, 0)) + 
  ABS(COALESCE(tc.diffNumOfUpdates, 0)) + 
  ABS(COALESCE(tc.diffNumOfDeletes, 0)) + 
  ABS(COALESCE(tc.diffNumOfDdls, 0)) + 
  ABS(COALESCE(tc.diffNumOfPkupdates, 0)) as total_difference,
  -- Sync status
  CASE
    WHEN (ABS(COALESCE(tc.diffNumOfInserts, 0)) + 
          ABS(COALESCE(tc.diffNumOfUpdates, 0)) + 
          ABS(COALESCE(tc.diffNumOfDeletes, 0))) = 0 THEN 'IN_SYNC'
    WHEN (ABS(COALESCE(tc.diffNumOfInserts, 0)) + 
          ABS(COALESCE(tc.diffNumOfUpdates, 0)) + 
          ABS(COALESCE(tc.diffNumOfDeletes, 0))) <= 100 THEN 'MINOR_DRIFT'
    WHEN (ABS(COALESCE(tc.diffNumOfInserts, 0)) + 
          ABS(COALESCE(tc.diffNumOfUpdates, 0)) + 
          ABS(COALESCE(tc.diffNumOfDeletes, 0))) <= 1000 THEN 'MODERATE_DRIFT'
    ELSE 'SIGNIFICANT_DRIFT'
  END as sync_status,
  -- Severity for sorting/filtering
  CASE
    WHEN (ABS(COALESCE(tc.diffNumOfInserts, 0)) + 
          ABS(COALESCE(tc.diffNumOfUpdates, 0)) + 
          ABS(COALESCE(tc.diffNumOfDeletes, 0))) = 0 THEN 1
    WHEN (ABS(COALESCE(tc.diffNumOfInserts, 0)) + 
          ABS(COALESCE(tc.diffNumOfUpdates, 0)) + 
          ABS(COALESCE(tc.diffNumOfDeletes, 0))) <= 100 THEN 2
    WHEN (ABS(COALESCE(tc.diffNumOfInserts, 0)) + 
          ABS(COALESCE(tc.diffNumOfUpdates, 0)) + 
          ABS(COALESCE(tc.diffNumOfDeletes, 0))) <= 1000 THEN 3
    ELSE 4
  END as sync_severity
FROM
  `striim_watcher_metadata.striim_mon_table_comparison` tc
INNER JOIN
  LatestComparisonData lcd
  ON tc.appName = lcd.appName
  AND tc.sourceName = lcd.sourceName
  AND tc.targetName = lcd.targetName
  AND tc.batchdate = lcd.latest_batchdate
INNER JOIN
  `striim_watcher_metadata.striim_mon_table_runhistory` rh
  ON tc.batchdate = rh.batchdate
LEFT JOIN
  `striim_watcher_metadata.latest_known_deployments` lkd
  ON tc.appName = lkd.appName
ORDER BY
  sync_severity DESC,
  total_difference DESC;

