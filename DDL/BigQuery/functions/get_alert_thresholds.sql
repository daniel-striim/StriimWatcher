-- Function: get_alert_thresholds
-- Purpose: Reads the configured alert thresholds for a single application
-- Usage: CALL `striim_watcher_metadata.get_alert_thresholds`('MyApp');
-- Returns: isEnabled and the four tunable threshold columns for the given app

CREATE OR REPLACE PROCEDURE `striim_watcher_metadata.get_alert_thresholds`(IN sp_appName STRING)
BEGIN
  SELECT
    isEnabled,
    terminatedThresholdMinutes,
    checkpointNotProgressingThresholdMin,
    backpressureThresholdMinutes,
    sourceInactivityThresholdMinutes
  FROM `striim_watcher_metadata.ApplicationAlertThresholds`
  WHERE appName = sp_appName;
END;
