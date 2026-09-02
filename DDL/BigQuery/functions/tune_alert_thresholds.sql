-- Function: tune_alert_thresholds
-- Purpose: Manually overrides the four tunable alert thresholds for a single application
-- Usage: CALL `striim_watcher_metadata.tune_alert_thresholds`('MyApp', 60, 60, 60, 60);
-- Returns: The app's updated threshold values and the timestamp of the change
-- Known gap (ported as-is from the live PROD implementation): this does not set
--   retainStaticValueFlag = TRUE, so a manual override here can be silently overwritten by the
--   next run of update_alert_thresholds() if that app's auto-tuned values differ by >20%.
--   Set retainStaticValueFlag manually (e.g. via toggle in the ApplicationAlertThresholds table)
--   if a manual override needs to stick.

CREATE OR REPLACE PROCEDURE `striim_watcher_metadata.tune_alert_thresholds`(
  IN sp_appName STRING,
  IN sp_terminatedThresholdMinutes INT64,
  IN sp_checkpointNotProgressingThresholdMin INT64,
  IN sp_backpressureThresholdMinutes INT64,
  IN sp_sourceInactivityThresholdMinutes INT64
)
BEGIN
  UPDATE `striim_watcher_metadata.ApplicationAlertThresholds`
  SET
    terminatedThresholdMinutes = sp_terminatedThresholdMinutes,
    checkpointNotProgressingThresholdMin = sp_checkpointNotProgressingThresholdMin,
    backpressureThresholdMinutes = sp_backpressureThresholdMinutes,
    sourceInactivityThresholdMinutes = sp_sourceInactivityThresholdMinutes
  WHERE LOWER(appName) = LOWER(sp_appName);

  SELECT
    appName,
    terminatedThresholdMinutes,
    checkpointNotProgressingThresholdMin,
    backpressureThresholdMinutes,
    sourceInactivityThresholdMinutes,
    CURRENT_TIMESTAMP() AS updated_timestamp
  FROM `striim_watcher_metadata.ApplicationAlertThresholds`
  WHERE LOWER(appName) = LOWER(sp_appName);
END;
