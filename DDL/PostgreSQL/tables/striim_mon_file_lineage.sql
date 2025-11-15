-- Table: striim_mon_file_lineage
-- Purpose: File lineage tracking for Striim CDC sources (e.g., Oracle GoldenGate trail files)
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures file lineage information from CDC sources, tracking new files and status changes to monitor file processing progress

CREATE TABLE mon.striim_mon_file_lineage (
    monfilelineageid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appName TEXT,
    componentName TEXT,
    fileName TEXT,
    file_status TEXT,
    directoryName TEXT,
    fileCreationTime TIMESTAMP,
    numberOfEvents BIGINT,
    firstEventTimestamp TIMESTAMP,
    lastEventTimestamp TIMESTAMP,
    wrapNumber BIGINT,
    sequenceNumber TEXT
);

