-- View: Latest Known Deployments
-- Purpose: Gets the deployment info from the last time each app was RUNNING to provide reliable deployment context
-- This is a common lookup used across all alert types
-- Includes batchdate to maintain FK reference consistency with other monitoring data

CREATE OR REPLACE VIEW `striim_watcher_metadata.latest_known_deployments` AS
SELECT
  appName,
  deploymentOn,
  batchdate
FROM (
  SELECT
    appName,
    deploymentOn,
    batchdate,
    -- Find the most recent record for each app where it was actually RUNNING
    ROW_NUMBER() OVER(PARTITION BY appName ORDER BY batchdate DESC) as rn
  FROM
    `striim_watcher_metadata.striim_mon_appdetail`
  WHERE UPPER(TRIM(appStatus)) = 'RUNNING'
)
WHERE rn = 1;
