-- Function: toggle_alert
-- Purpose: Enables or disables alerting for a single application
-- Usage: SELECT * FROM mon.toggle_alert('MyApp', FALSE);
-- Returns: The app's appName, isEnabled, and the timestamp of the change

CREATE OR REPLACE FUNCTION mon.toggle_alert(sp_appName TEXT, sp_isEnabled BOOLEAN)
RETURNS TABLE(
  appName TEXT,
  isEnabled BOOLEAN,
  updated_timestamp TIMESTAMPTZ
)
AS $$
BEGIN
  UPDATE mon.ApplicationAlertThresholds
  SET isEnabled = sp_isEnabled
  WHERE LOWER(appName) = LOWER(sp_appName);

  RETURN QUERY
  SELECT
    aat.appName,
    aat.isEnabled,
    CURRENT_TIMESTAMP as updated_timestamp
  FROM mon.ApplicationAlertThresholds aat
  WHERE LOWER(aat.appName) = LOWER(sp_appName);
END;
$$ LANGUAGE plpgsql;
