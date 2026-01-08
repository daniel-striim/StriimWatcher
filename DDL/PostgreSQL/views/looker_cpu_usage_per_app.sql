-- View: Looker CPU Usage Per App
-- Purpose: Shows the latest CPU usage per application for operational monitoring
-- Dashboard: Operational Dashboard
-- Description: Returns the most recent CPU rate for each application with cluster and node context

CREATE OR REPLACE VIEW mon.looker_cpu_usage_per_app AS
WITH LatestBatch AS (
  SELECT
    appname,
    MAX(batchdate) as latest_batchdate
  FROM
    mon.striim_mon_node_applications
  GROUP BY
    appname
)
SELECT
  rh.clusterName,
  app.batchdate,
  app.appname,
  ad.deploymentOn as nodename,
  app.cpurate,
  app.rate,
  app.sourcerate,
  app.status,
  app.latestActivity
FROM
  mon.striim_mon_node_applications app
INNER JOIN
  LatestBatch lb
  ON app.appname = lb.appname 
  AND app.batchdate = lb.latest_batchdate
INNER JOIN
  mon.striim_mon_table_runhistory rh
  ON app.batchdate = rh.batchdate
LEFT JOIN
  mon.striim_mon_appdetail ad
  ON app.appname = ad.appName
  AND app.batchdate = ad.batchdate
WHERE
  app.cpurate IS NOT NULL
ORDER BY
  app.cpurate DESC;

