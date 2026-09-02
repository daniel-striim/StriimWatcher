-- Function: get_alert_thresholds
-- Purpose: Reads the configured alert thresholds for a single application
-- Usage: SELECT * FROM mon.get_alert_thresholds('MyApp');
-- Returns: isEnabled and the four tunable threshold columns for the given app

CREATE OR REPLACE FUNCTION mon.get_alert_thresholds(sp_appName TEXT)
RETURNS TABLE(
  isEnabled BOOLEAN,
  terminatedThresholdMinutes BIGINT,
  checkpointNotProgressingThresholdMin BIGINT,
  backpressureThresholdMinutes BIGINT,
  sourceInactivityThresholdMinutes BIGINT
)
AS $$
  SELECT
    isEnabled,
    terminatedThresholdMinutes,
    checkpointNotProgressingThresholdMin,
    backpressureThresholdMinutes,
    sourceInactivityThresholdMinutes
  FROM mon.ApplicationAlertThresholds
  WHERE appName = sp_appName;
$$ LANGUAGE SQL;
