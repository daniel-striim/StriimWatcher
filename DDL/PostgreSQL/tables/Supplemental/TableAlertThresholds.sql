

CREATE TABLE mon.TableAlertThresholds (
    id TEXT PRIMARY KEY,
    appName TEXT,
    tableName TEXT,
    sourceTableName TEXT,
    targetTableName TEXT,
    

    dataFreshnessThresholdMinutes BIGINT,
    dataFreshnessCheckEnabled BOOLEAN,
    

    queuedBatchesThreshold BIGINT,
    queuedBatchesCheckEnabled BOOLEAN,
    queuedBatchesConsistentMinutes BIGINT,
    

    pkUpdatesThreshold BIGINT,
    pkUpdatesCheckEnabled BOOLEAN,
    

    isEnabled BOOLEAN DEFAULT TRUE,
    createdDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lastModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

