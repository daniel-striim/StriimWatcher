

CREATE TABLE mon.striim_mon_appdetail (
    monid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    appName TEXT,
    appStatus TEXT,
    totalInput BIGINT,
    totalOutput BIGINT,
    isBackpressured BOOLEAN,
    isRecoveryEnabled BOOLEAN,
    recoverySetting TEXT,
    checkpointStatus TEXT,
    checkpointDetail TEXT,
    isEncryptionEnabled BOOLEAN,
    deploymentOn TEXT,
    deploymentIn TEXT,
    appCreatedDate TIMESTAMP,
    latestActivity TIMESTAMP
    -- ,backpressuredcomponents TEXT
);

