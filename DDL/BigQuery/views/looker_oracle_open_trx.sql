-- View: Looker Oracle Open Transactions
-- Purpose: Shows open Oracle transactions for CDC sources (Oracle-specific monitoring)
-- Dashboard: Operational Dashboard
-- Description: Returns current open transactions with age and operation counts

CREATE OR REPLACE VIEW `striim_watcher_metadata.looker_oracle_open_trx` AS
WITH LatestTrxData AS (
  SELECT
    appName,
    componentName,
    MAX(batchdate) as latest_batchdate
  FROM
    `striim_watcher_metadata.striim_mon_oracle_open_trx`
  GROUP BY
    appName, componentName
)
SELECT
  rh.clusterName,
  ot.batchdate,
  lkd.deploymentOn as nodename,
  ot.appName,
  ot.componentName,
  ot.transactionId,
  ot.numOfOps,
  ot.sequenceNum,
  ot.startscn,
  ot.rbaBlock,
  ot.threadNum,
  ot.montimestamp as transaction_start_time,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), ot.montimestamp, MINUTE) as transaction_age_minutes,
  ROUND(TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), ot.montimestamp, MINUTE) / 60.0, 2) as transaction_age_hours,
  -- Transaction health status based on age
  CASE
    WHEN ot.montimestamp IS NULL THEN 'UNKNOWN'
    WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), ot.montimestamp, MINUTE) <= 30 THEN 'NORMAL'
    WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), ot.montimestamp, MINUTE) <= 120 THEN 'AGED'
    ELSE 'LONG_RUNNING'
  END as transaction_status
FROM
  `striim_watcher_metadata.striim_mon_oracle_open_trx` ot
INNER JOIN
  LatestTrxData ltd
  ON ot.appName = ltd.appName
  AND ot.componentName = ltd.componentName
  AND ot.batchdate = ltd.latest_batchdate
INNER JOIN
  `striim_watcher_metadata.striim_mon_table_runhistory` rh
  ON ot.batchdate = rh.batchdate
LEFT JOIN
  `striim_watcher_metadata.latest_known_deployments` lkd
  ON ot.appName = lkd.appName
ORDER BY
  transaction_age_minutes DESC;

