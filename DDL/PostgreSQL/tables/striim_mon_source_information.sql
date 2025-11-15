-- Table: striim_mon_source_information
-- Purpose: Source component monitoring metrics including throughput, CPU, lag, and event processing statistics
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures common source metrics across different source types (Oracle CDC, PostgreSQL, MySQL, etc.) for monitoring source health and performance

CREATE TABLE mon.striim_mon_source_information (
    monsrcinfoid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appName TEXT,
    componentName TEXT,
    input_count BIGINT,
    inputRate BIGINT,
    sourceInput BIGINT,
    sourceRate BIGINT,
    event_rate BIGINT,
    numberOfEventsSeenPerMonitorSnapshotInterval BIGINT,
    cpu DOUBLE PRECISION,
    cpuRatePerNode DOUBLE PRECISION,
    cpuRate DOUBLE PRECISION,
    lastEventReadAge TEXT,
    latestActivity TIMESTAMP,
    readLag BIGINT,
    readTimestamp TIMESTAMP,
    sourceFreshness TEXT,
    sourceFreshnessMinutes BIGINT,
    numServers BIGINT,
    montimestamp TIMESTAMP,
    jsonoutput TEXT
);

