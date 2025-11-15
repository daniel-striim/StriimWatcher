-- Table: striim_mon_file_lineage
-- Purpose: File lineage tracking for Striim CDC sources (e.g., Oracle GoldenGate trail files)
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures file lineage information from CDC sources, tracking new files and status changes to monitor file processing progress

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_file_lineage` (
    monfilelineageid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The full name of the Striim application (e.g., 'admin.SQLCDC'). This is the application containing the source component."
    ),
    componentName STRING OPTIONS (
        DESCRIPTION="The full name of the source component (e.g., 'admin.GGTrail_Reader'). This is the CDC source for which file lineage is being tracked."
    ),
    fileName STRING OPTIONS (
        DESCRIPTION="The name of the trail file or CDC file being processed (e.g., 'ea000082385'). This is the unique identifier for the file in the lineage."
    ),
    file_status STRING OPTIONS (
        DESCRIPTION="The processing status of the file. Common values: 'PROCESSING' (currently being read), 'COMPLETED' (fully processed). Indicates the current state of file processing. Renamed from 'status' to avoid reserved keyword."
    ),
    directoryName STRING OPTIONS (
        DESCRIPTION="The full directory path where the file is located (e.g., '/ogg/ogg191/dirdat'). This is the physical location of the trail file on the source system."
    ),
    fileCreationTime TIMESTAMP OPTIONS (
        DESCRIPTION="The timestamp when the file was created on the source system. This helps track when new trail files are generated."
    ),
    numberOfEvents INT64 OPTIONS (
        DESCRIPTION="The total number of events/records contained in this file. A value of 0 indicates an empty file or a file with only metadata."
    ),
    firstEventTimestamp TIMESTAMP OPTIONS (
        DESCRIPTION="The timestamp of the first event in the file. NULL or 'N/A' if the file contains no events. This represents the earliest data change captured in this file."
    ),
    lastEventTimestamp TIMESTAMP OPTIONS (
        DESCRIPTION="The timestamp of the last event in the file. NULL or 'N/A' if the file contains no events. This represents the most recent data change captured in this file."
    ),
    wrapNumber INT64 OPTIONS (
        DESCRIPTION="The wrap number for the trail file sequence. Used in GoldenGate to track file sequence across wraps. Typically 1 for most deployments."
    ),
    sequenceNumber STRING OPTIONS (
        DESCRIPTION="The sequence number for the trail file. May be NULL if not applicable. Used to order files within a wrap."
    ),
    PRIMARY KEY (monfilelineageid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="File lineage tracking for CDC sources - records new files and status changes to monitor file processing progress"
);


