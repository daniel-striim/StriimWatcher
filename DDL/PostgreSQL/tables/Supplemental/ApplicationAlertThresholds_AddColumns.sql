

ALTER TABLE mon.ApplicationAlertThresholds
ADD COLUMN retainStaticValueFlag BOOLEAN DEFAULT FALSE;

ALTER TABLE mon.ApplicationAlertThresholds
ADD COLUMN sourceInactivityThresholdMinutes BIGINT;

ALTER TABLE mon.ApplicationAlertThresholds
ADD COLUMN maxQueuedBatchesOnTarget BIGINT;

ALTER TABLE mon.ApplicationAlertThresholds
ADD COLUMN maxBatchSizeBytes BIGINT;

SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'mon'
  AND table_name = 'applicationalertthresholds'
ORDER BY ordinal_position;

