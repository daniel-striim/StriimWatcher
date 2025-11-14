-- Table: striim_mon_target_information
-- Purpose: Target component monitoring metrics including throughput, CPU, lag, and event processing statistics
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures common target metrics across different target types (Oracle, BigQuery, etc.) for monitoring target health and performance

CREATE TABLE mon.striim_mon_target_information (
    montgtinfoid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appName TEXT,
    componentName TEXT,
    accepted BIGINT,
    noOfEventsAcceptedPerInterval BIGINT,
    acceptedRate DOUBLE PRECISION,
    input BIGINT,
    inputRate DOUBLE PRECISION,
    output BIGINT,
    rate DOUBLE PRECISION,
    targetAcked BIGINT,
    targetOutput BIGINT,
    targetRate DOUBLE PRECISION,
    cpu DOUBLE PRECISION,
    cpuRatePerNode DOUBLE PRECISION,
    cpuRate DOUBLE PRECISION,
    discardedEventCount BIGINT,
    numberOfEventsSeenPerMonitorSnapshotInterval BIGINT,
    lastEventWriteAge TEXT,
    latestActivity TIMESTAMP,
    maxLeeFromAllSources TEXT,
    numServers BIGINT,
    timestamp TIMESTAMP,
    writeBytes TEXT,
    jsonoutput TEXT
);

