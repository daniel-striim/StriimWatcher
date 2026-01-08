-- View: Looker CPU Usage Per App
-- Purpose: Shows the latest CPU usage per application for operational monitoring
-- Dashboard: Operational Dashboard
-- Description: Returns the most recent CPU rate for each application with cluster and node context

CREATE OR REPLACE VIEW `striim_watcher_metadata.looker_cpu_usage_per_app` AS
WITH LatestBatch AS (
  -- Get the most recent batchdate for each app
  SELECT
    appname,
    MAX(batchdate) as latest_batchdate
  FROM
    `striim_watcher_metadata.striim_mon_node_applications`
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
  `striim_watcher_metadata.striim_mon_node_applications` app
INNER JOIN
  LatestBatch lb
  ON app.appname = lb.appname 
  AND app.batchdate = lb.latest_batchdate
INNER JOIN
  `striim_watcher_metadata.striim_mon_table_runhistory` rh
  ON app.batchdate = rh.batchdate
LEFT JOIN
  `striim_watcher_metadata.striim_mon_appdetail` ad
  ON app.appname = ad.appName
  AND app.batchdate = ad.batchdate
WHERE
  app.cpurate IS NOT NULL
ORDER BY
  app.cpurate DESC;

