-- View: Looker Files Open List
-- Purpose: Shows all files that are not in COMPLETED status for CDC monitoring
-- Dashboard: Operational Dashboard
-- Description: Returns files currently being processed with app and node context

CREATE OR REPLACE VIEW mon.looker_files_open_list AS
WITH LatestFileStatus AS (
  -- Get the most recent status for each file
  SELECT
    fileName,
    appName,
    MAX(batchdate) as latest_batchdate
  FROM
    mon.striim_mon_file_lineage
  GROUP BY
    fileName, appName
)
SELECT
  rh.clusterName,
  fl.batchdate,
  ad.deploymentOn as nodename,
  fl.appName,
  fl.componentName,
  fl.fileName,
  fl.file_status,
  fl.directoryName,
  fl.fileCreationTime,
  fl.numberOfEvents,
  fl.firstEventTimestamp,
  fl.lastEventTimestamp,
  fl.wrapNumber,
  fl.sequenceNumber,
  EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - fl.batchdate)) / 60 as minutes_since_last_update
FROM
  mon.striim_mon_file_lineage fl
INNER JOIN
  LatestFileStatus lfs
  ON fl.fileName = lfs.fileName
  AND fl.appName = lfs.appName
  AND fl.batchdate = lfs.latest_batchdate
INNER JOIN
  mon.striim_mon_table_runhistory rh
  ON fl.batchdate = rh.batchdate
LEFT JOIN
  mon.striim_mon_appdetail ad
  ON fl.appName = ad.appName
  AND fl.batchdate = ad.batchdate
WHERE
  UPPER(TRIM(fl.file_status)) != 'COMPLETED'
ORDER BY
  fl.batchdate DESC, fl.fileName;

