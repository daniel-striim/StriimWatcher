-- Function: tune_alert_thresholds
-- Purpose: Manually overrides the four tunable alert thresholds for a single application
-- Usage: SELECT * FROM mon.tune_alert_thresholds('MyApp', 60, 60, 60, 60);
-- Returns: The app's updated threshold values and the timestamp of the change
-- Known gap (ported as-is from the live PROD implementation): this does not set
--   retainStaticValueFlag = TRUE, so a manual override here can be silently overwritten by the
--   next run of update_alert_thresholds() if that app's auto-tuned values differ by >20%.
--   Set retainStaticValueFlag manually (e.g. via toggle in the ApplicationAlertThresholds table)
--   if a manual override needs to stick.

CREATE OR REPLACE FUNCTION mon.tune_alert_thresholds(
  sp_appName TEXT,
  sp_terminatedThresholdMinutes BIGINT,
  sp_checkpointNotProgressingThresholdMin BIGINT,
  sp_backpressureThresholdMinutes BIGINT,
  sp_sourceInactivityThresholdMinutes BIGINT
)
RETURNS TABLE(
  appName TEXT,
  terminatedThresholdMinutes BIGINT,
  checkpointNotProgressingThresholdMin BIGINT,
  backpressureThresholdMinutes BIGINT,
  sourceInactivityThresholdMinutes BIGINT,
  updated_timestamp TIMESTAMPTZ
)
AS $$
BEGIN
  UPDATE mon.ApplicationAlertThresholds
  SET
    terminatedThresholdMinutes = sp_terminatedThresholdMinutes,
    checkpointNotProgressingThresholdMin = sp_checkpointNotProgressingThresholdMin,
    backpressureThresholdMinutes = sp_backpressureThresholdMinutes,
    sourceInactivityThresholdMinutes = sp_sourceInactivityThresholdMinutes
  WHERE LOWER(appName) = LOWER(sp_appName);

  RETURN QUERY
  SELECT
    aat.appName,
    aat.terminatedThresholdMinutes,
    aat.checkpointNotProgressingThresholdMin,
    aat.backpressureThresholdMinutes,
    aat.sourceInactivityThresholdMinutes,
    CURRENT_TIMESTAMP as updated_timestamp
  FROM mon.ApplicationAlertThresholds aat
  WHERE LOWER(aat.appName) = LOWER(sp_appName);
END;
$$ LANGUAGE plpgsql;
