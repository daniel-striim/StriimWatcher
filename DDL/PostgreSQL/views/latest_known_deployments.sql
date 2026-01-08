-- View: Latest Known Deployments
-- Purpose: Gets the deployment info from the last time each app was RUNNING to provide reliable deployment context
-- This is a common lookup used across all alert types
-- Includes batchdate to maintain FK reference consistency with other monitoring data

CREATE OR REPLACE VIEW mon.latest_known_deployments AS
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
    mon.striim_mon_appdetail
  WHERE UPPER(TRIM(appStatus)) = 'RUNNING'
    AND deploymentOn IS NOT NULL
) ranked
WHERE rn = 1;
