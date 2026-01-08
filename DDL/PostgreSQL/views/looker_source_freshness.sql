-- View: Looker Source Freshness
-- Purpose: Shows source freshness and lag metrics for operational monitoring
-- Dashboard: Operational Dashboard
-- Description: Returns current freshness status for all sources with color-coded health status

CREATE OR REPLACE VIEW mon.looker_source_freshness AS
WITH LatestSourceData AS (
  SELECT
    appName,
    componentName,
    MAX(batchdate) as latest_batchdate
  FROM
    mon.striim_mon_source_information
  GROUP BY
    appName, componentName
)
SELECT
  rh.clusterName,
  si.batchdate,
  lkd.deploymentOn as nodename,
  si.appName,
  si.componentName,
  si.sourceFreshness,
  si.sourceFreshnessMinutes,
  si.readLag,
  si.inputRate,
  si.sourceRate,
  si.cpuRate,
  si.lastEventReadAge,
  si.readTimestamp,
  si.latestActivity,
  CASE
    WHEN si.sourceFreshnessMinutes IS NULL THEN 'UNKNOWN'
    WHEN si.sourceFreshnessMinutes <= 5 THEN 'FRESH'
    WHEN si.sourceFreshnessMinutes <= 30 THEN 'MODERATE'
    WHEN si.sourceFreshnessMinutes <= 60 THEN 'STALE'
    ELSE 'CRITICAL'
  END as freshness_status,
  CASE
    WHEN si.sourceFreshnessMinutes IS NULL THEN 4
    WHEN si.sourceFreshnessMinutes <= 5 THEN 1
    WHEN si.sourceFreshnessMinutes <= 30 THEN 2
    WHEN si.sourceFreshnessMinutes <= 60 THEN 3
    ELSE 4
  END as freshness_severity
FROM
  mon.striim_mon_source_information si
INNER JOIN
  LatestSourceData lsd
  ON si.appName = lsd.appName
  AND si.componentName = lsd.componentName
  AND si.batchdate = lsd.latest_batchdate
INNER JOIN
  mon.striim_mon_table_runhistory rh
  ON si.batchdate = rh.batchdate
LEFT JOIN
  mon.latest_known_deployments lkd
  ON si.appName = lkd.appName
ORDER BY
  si.sourceFreshnessMinutes DESC NULLS LAST;

