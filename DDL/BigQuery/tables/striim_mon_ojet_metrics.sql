-- Table: striim_mon_ojet_metrics
-- Purpose: OJet (Oracle JET/Java Edition Tracker) metrics from Striim Oracle CDC sources
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures Oracle LogMiner and CDC memory usage, transaction spilling, and SCN tracking metrics

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_ojet_metrics` (
    monojetid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The full name of the Striim application (e.g., 'admin.OracleCDC')."
    ),
    componentName STRING OPTIONS (
        DESCRIPTION="The name of the source component being monitored."
    ),
    memUsageLogminer FLOAT64 OPTIONS (
        DESCRIPTION="Memory usage by the LogMiner process in MB."
    ),
    memUsageCapture FLOAT64 OPTIONS (
        DESCRIPTION="Memory usage by the Capture process in MB."
    ),
    memUsageApply FLOAT64 OPTIONS (
        DESCRIPTION="Memory usage by the Apply process in MB."
    ),
    memUsageStreamsPool FLOAT64 OPTIONS (
        DESCRIPTION="Memory usage of the Oracle Streams Pool in MB."
    ),
    txnSpillingToDisk BOOL OPTIONS (
        DESCRIPTION="Indicates whether Oracle transactions are spilling to disk, which can impact CDC performance."
    ),
    lastObservedScn STRING OPTIONS (
        DESCRIPTION="The last System Change Number (SCN) observed by the CDC source."
    ),
    currentScn STRING OPTIONS (
        DESCRIPTION="The current SCN of the Oracle database at time of monitoring."
    ),
    redoSwitchCount STRING OPTIONS (
        DESCRIPTION="Number of redo log switches observed."
    ),
    logmnrRecordCount STRING OPTIONS (
        DESCRIPTION="Number of records processed by LogMiner."
    ),
    lastObservedTimestamp TIMESTAMP OPTIONS (
        DESCRIPTION="The timestamp corresponding to the last observed SCN."
    ),
    PRIMARY KEY (monojetid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="OJet metrics from Striim Oracle CDC sources — LogMiner memory usage, transaction spilling, and SCN tracking"
);
