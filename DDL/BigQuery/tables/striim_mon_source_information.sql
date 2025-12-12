-- Table: striim_mon_source_information
-- Purpose: Source component monitoring metrics including throughput, CPU, lag, and event processing statistics
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures common source metrics across different source types (Oracle CDC, PostgreSQL, MySQL, etc.) for monitoring source health and performance

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_source_information` (
    monsrcinfoid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The application name."
    ),
    componentName STRING OPTIONS (
        DESCRIPTION="The source component name."
    ),
    input_count INT64 OPTIONS (
        DESCRIPTION="Total input events to the source. Parsed from comma-separated string (e.g., '57,253' -> 57253). Renamed from 'input' to avoid reserved keyword."
    ),
    inputRate FLOAT64 OPTIONS (
        DESCRIPTION="Input event rate."
    ),
    sourceInput INT64 OPTIONS (
        DESCRIPTION="Source input events. Parsed from comma-separated string (e.g., '57,253' -> 57253)."
    ),
    sourceRate INT64 OPTIONS (
        DESCRIPTION="Source event rate."
    ),
    event_rate INT64 OPTIONS (
        DESCRIPTION="General processing rate. Renamed from 'rate' to avoid reserved keyword."
    ),
    numberOfEventsSeenPerMonitorSnapshotInterval INT64 OPTIONS (
        DESCRIPTION="Events seen in the monitoring snapshot interval."
    ),
    cpu FLOAT64 OPTIONS (
        DESCRIPTION="CPU usage value (e.g., 0.00235)."
    ),
    cpuRatePerNode FLOAT64 OPTIONS (
        DESCRIPTION="CPU rate per node. Parsed from percentage string (e.g., '0.029%' -> 0.029)."
    ),
    cpuRate FLOAT64 OPTIONS (
        DESCRIPTION="Overall CPU rate percentage. Parsed from percentage string (e.g., '0.235%' -> 0.235)."
    ),
    lastEventReadAge STRING OPTIONS (
        DESCRIPTION="Age of the last read event - indicates staleness (e.g., '0.24 sec')."
    ),
    latestActivity TIMESTAMP OPTIONS (
        DESCRIPTION="Timestamp of the latest activity on the source."
    ),
    readLag INT64 OPTIONS (
        DESCRIPTION="Read lag value - indicates how far behind the source is from the database. Parsed from comma-separated string (e.g., '156,800' -> 156800)."
    ),
    readTimestamp TIMESTAMP OPTIONS (
        DESCRIPTION="Read timestamp - the timestamp of the last read event from the source database."
    ),
    sourceFreshness STRING OPTIONS (
        DESCRIPTION="Source freshness indicator - how fresh the data is from the source (e.g., '08H:02M:32S' or '1D:08H:02M:32S'). Original string format preserved."
    ),
    sourceFreshnessMinutes INT64 OPTIONS (
        DESCRIPTION="Source freshness converted to total minutes. Calculated from sourceFreshness field. Format supports days, hours, minutes, seconds (e.g., '08H:02M:32S' -> 482 minutes, '1D:08H:02M:32S' -> 1922 minutes)."
    ),
    numServers INT64 OPTIONS (
        DESCRIPTION="Number of servers."
    ),
    montimestamp TIMESTAMP OPTIONS (
        DESCRIPTION="Monitoring timestamp. Renamed from 'timestamp' to avoid reserved keyword."
    ),
    jsonoutput STRING OPTIONS (
        DESCRIPTION="Full JSON output from the source monitoring command. Only populated if IncludeSourceInformationDetail flag is enabled, otherwise NULL."
    ),
    PRIMARY KEY (monsrcinfoid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="Source component monitoring metrics including throughput, CPU, lag, and event processing statistics"
);

