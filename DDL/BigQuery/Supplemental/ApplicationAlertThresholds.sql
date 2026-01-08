CREATE TABLE mon.ApplicationAlertThresholds (
  id STRING,
  appName STRING,
  isCdcApp BOOLEAN,
  terminatedCheckEnabled BOOLEAN,
  terminatedThresholdMinutes INT64,
  backpressureThresholdMinutes INT64,
  checkpointNotProgressingThresholdMin INT64,
  avgLeeThresholdMinutes INT64,
  retainStaticValueFlag BOOLEAN DEFAULT FALSE,
  sourceInactivityThresholdMinutes INT64,
  maxQueuedBatchesOnTarget INT64,
  maxBatchSizeBytes INT64,
  isEnabled BOOLEAN DEFAULT TRUE
);
