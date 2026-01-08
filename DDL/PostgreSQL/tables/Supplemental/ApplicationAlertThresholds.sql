CREATE TABLE mon.ApplicationAlertThresholds (
    id TEXT PRIMARY KEY,
    appName TEXT,
    isCdcApp BOOLEAN,
    terminatedCheckEnabled BOOLEAN,
    terminatedThresholdMinutes BIGINT,
    backpressureThresholdMinutes BIGINT,
    checkpointNotProgressingThresholdMin BIGINT,
    avgLeeThresholdMinutes BIGINT,
    isEnabled BOOLEAN DEFAULT TRUE
);
