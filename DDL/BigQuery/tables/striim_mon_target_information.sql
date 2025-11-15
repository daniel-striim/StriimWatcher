-- Table: striim_mon_target_information
-- Purpose: Target component monitoring metrics including throughput, CPU, lag, and event processing statistics
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures common target metrics across different target types (Oracle, BigQuery, etc.) for monitoring target health and performance

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_target_information` (
    montgtinfoid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The application name."
    ),
    componentName STRING OPTIONS (
        DESCRIPTION="The target component name."
    ),
    accepted INT64 OPTIONS (
        DESCRIPTION="Total events accepted by the target. Parsed from comma-separated string (e.g., '4,180' -> 4180)."
    ),
    noOfEventsAcceptedPerInterval INT64 OPTIONS (
        DESCRIPTION="Events accepted in the current monitoring interval."
    ),
    acceptedRate FLOAT64 OPTIONS (
        DESCRIPTION="Rate of event acceptance (events per second)."
    ),
    input_count INT64 OPTIONS (
        DESCRIPTION="Total input events to the target. Parsed from comma-separated string (e.g., '4,239' -> 4239). Renamed from 'input' to avoid reserved keyword."
    ),
    inputRate FLOAT64 OPTIONS (
        DESCRIPTION="Input event rate (events per second)."
    ),
    output_count INT64 OPTIONS (
        DESCRIPTION="Total output events from the target. Parsed from comma-separated string (e.g., '4,239' -> 4239). Renamed from 'output' to avoid reserved keyword."
    ),
    event_rate FLOAT64 OPTIONS (
        DESCRIPTION="General processing rate (events per second). Renamed from 'rate' to avoid reserved keyword."
    ),
    targetAcked INT64 OPTIONS (
        DESCRIPTION="Events acknowledged by the target. Parsed from comma-separated string (e.g., '4,180' -> 4180)."
    ),
    targetOutput INT64 OPTIONS (
        DESCRIPTION="Events output to the target. Parsed from comma-separated string (e.g., '4,180' -> 4180)."
    ),
    targetRate FLOAT64 OPTIONS (
        DESCRIPTION="Target output rate (events per second)."
    ),
    cpu FLOAT64 OPTIONS (
        DESCRIPTION="CPU usage value (e.g., 0.00879)."
    ),
    cpuRatePerNode FLOAT64 OPTIONS (
        DESCRIPTION="CPU rate per node. Parsed from percentage string (e.g., '0.11%' -> 0.11)."
    ),
    cpuRate FLOAT64 OPTIONS (
        DESCRIPTION="Overall CPU rate percentage. Parsed from percentage string (e.g., '0.879%' -> 0.879)."
    ),
    discardedEventCount INT64 OPTIONS (
        DESCRIPTION="Count of discarded events - indicates potential data loss."
    ),
    numberOfEventsSeenPerMonitorSnapshotInterval INT64 OPTIONS (
        DESCRIPTION="Events seen in the monitoring snapshot interval."
    ),
    lastEventWriteAge STRING OPTIONS (
        DESCRIPTION="Age of the last written event - indicates staleness (e.g., '56.018 sec'). Kept as STRING due to units."
    ),
    latestActivity TIMESTAMP OPTIONS (
        DESCRIPTION="Timestamp of the latest activity on the target."
    ),
    maxLeeFromAllSources STRING OPTIONS (
        DESCRIPTION="Maximum lag from all sources - indicates lag/freshness issues (e.g., '5,384,403.239 sec'). Kept as STRING due to units and complex format."
    ),
    numServers INT64 OPTIONS (
        DESCRIPTION="Number of servers."
    ),
    montimestamp TIMESTAMP OPTIONS (
        DESCRIPTION="Monitoring timestamp. Renamed from 'timestamp' to avoid reserved keyword."
    ),
    writeBytes STRING OPTIONS (
        DESCRIPTION="Bytes written per second (e.g., '0MB/s'). Kept as STRING due to units."
    ),
    jsonoutput STRING OPTIONS (
        DESCRIPTION="Full JSON output from the target monitoring command. Only populated if IncludeTargetInformationDetail flag is enabled, otherwise NULL."
    ),
    PRIMARY KEY (montgtinfoid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="Target component monitoring metrics including throughput, CPU, lag, and event processing statistics"
);

