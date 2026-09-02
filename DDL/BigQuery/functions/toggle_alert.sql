-- Function: toggle_alert
-- Purpose: Enables or disables alerting for a single application
-- Usage: CALL `striim_watcher_metadata.toggle_alert`('MyApp', FALSE);
-- Returns: The app's appName, isEnabled, and the timestamp of the change

CREATE OR REPLACE PROCEDURE `striim_watcher_metadata.toggle_alert`(IN sp_appName STRING, IN sp_isEnabled BOOL)
BEGIN
  UPDATE `striim_watcher_metadata.ApplicationAlertThresholds`
  SET
    isEnabled = sp_isEnabled
  WHERE LOWER(appName) = LOWER(sp_appName);

  SELECT
    appName,
    isEnabled,
    CURRENT_TIMESTAMP() AS updated_timestamp
  FROM `striim_watcher_metadata.ApplicationAlertThresholds`
  WHERE LOWER(appName) = LOWER(sp_appName);
END;
