-- View: Looker Node Resources
-- Purpose: Shows node-level resource utilization (CPU, memory, uptime)
-- Dashboard: Operational Dashboard
-- Description: Returns current resource metrics for all cluster nodes

CREATE OR REPLACE VIEW `striim_watcher_metadata.looker_node_resources` AS
WITH LatestNodeData AS (
  SELECT
    nodename,
    MAX(batchdate) as latest_batchdate
  FROM
    `striim_watcher_metadata.striim_mon_node_cluster`
  GROUP BY
    nodename
)
SELECT
  rh.clusterName,
  nc.batchdate,
  nc.nodename,
  nc.striimversion,
  nc.freemem,
  nc.cpurate,
  nc.uptime,
  -- Parse freemem to extract numeric value in GB (handles formats like "1.2 GB", "500 MB")
  CASE
    WHEN UPPER(nc.freemem) LIKE '%GB%' THEN 
      SAFE_CAST(REGEXP_EXTRACT(nc.freemem, r'([0-9.]+)') AS FLOAT64)
    WHEN UPPER(nc.freemem) LIKE '%MB%' THEN 
      SAFE_CAST(REGEXP_EXTRACT(nc.freemem, r'([0-9.]+)') AS FLOAT64) / 1024
    ELSE NULL
  END as freemem_gb,
  -- CPU health status
  CASE
    WHEN nc.cpurate IS NULL THEN 'UNKNOWN'
    WHEN nc.cpurate < 50 THEN 'HEALTHY'
    WHEN nc.cpurate < 80 THEN 'MODERATE'
    WHEN nc.cpurate < 100 THEN 'HIGH'
    ELSE 'CRITICAL'
  END as cpu_health_status,
  -- Memory health (assuming freemem < 1GB is concerning)
  CASE
    WHEN nc.freemem IS NULL THEN 'UNKNOWN'
    WHEN UPPER(nc.freemem) LIKE '%GB%' AND 
         SAFE_CAST(REGEXP_EXTRACT(nc.freemem, r'([0-9.]+)') AS FLOAT64) >= 2 THEN 'HEALTHY'
    WHEN UPPER(nc.freemem) LIKE '%GB%' AND 
         SAFE_CAST(REGEXP_EXTRACT(nc.freemem, r'([0-9.]+)') AS FLOAT64) >= 1 THEN 'MODERATE'
    WHEN UPPER(nc.freemem) LIKE '%MB%' AND 
         SAFE_CAST(REGEXP_EXTRACT(nc.freemem, r'([0-9.]+)') AS FLOAT64) >= 512 THEN 'MODERATE'
    ELSE 'LOW'
  END as memory_health_status
FROM
  `striim_watcher_metadata.striim_mon_node_cluster` nc
INNER JOIN
  LatestNodeData lnd
  ON nc.nodename = lnd.nodename
  AND nc.batchdate = lnd.latest_batchdate
INNER JOIN
  `striim_watcher_metadata.striim_mon_table_runhistory` rh
  ON nc.batchdate = rh.batchdate
ORDER BY
  nc.cpurate DESC NULLS LAST;

