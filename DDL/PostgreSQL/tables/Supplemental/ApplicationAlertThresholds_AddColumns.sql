

ALTER TABLE mon.ApplicationAlertThresholds
ADD COLUMN retainStaticValueFlag BOOLEAN DEFAULT FALSE;

ALTER TABLE mon.ApplicationAlertThresholds
ADD COLUMN sourceInactivityThresholdMinutes BIGINT;

ALTER TABLE mon.ApplicationAlertThresholds
ADD COLUMN maxQueuedBatchesOnTarget BIGINT;

ALTER TABLE mon.ApplicationAlertThresholds
ADD COLUMN maxBatchSizeBytes BIGINT;

-- Required for insert_alert_updates() / update_alert_thresholds()'s "ON CONFLICT (appName)"
-- upsert to work at all — Postgres requires a unique constraint/index matching the conflict
-- target. Before running this in a live deployment, check for existing duplicate appName rows
-- first (this ALTER will fail if any exist):
--   SELECT appName, COUNT(*) FROM mon.ApplicationAlertThresholds GROUP BY appName HAVING COUNT(*) > 1;
ALTER TABLE mon.ApplicationAlertThresholds
ADD CONSTRAINT uq_applicationalertthresholds_appname UNIQUE (appName);

SELECT
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'mon'
  AND table_name = 'applicationalertthresholds'
ORDER BY ordinal_position;

