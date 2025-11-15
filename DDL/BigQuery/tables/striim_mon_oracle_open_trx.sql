-- Copyright © 2024 Striim Inc.
-- Licensed under Striim License Agreement
-- https://www.striim.com/striim-software-license-agreement/
-- Table: striim_mon_oracle_open_trx

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_oracle_open_trx` (
    monopentrxid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The application name."
    ),
    componentName STRING OPTIONS (
        DESCRIPTION="The source component name (Oracle CDC source)."
    ),
    transactionId STRING OPTIONS (
        DESCRIPTION="The Oracle transaction ID (e.g., '4.8.11465')."
    ),
    numOfOps STRING OPTIONS (
        DESCRIPTION="Number of operations in the open transaction."
    ),
    sequenceNum STRING OPTIONS (
        DESCRIPTION="Sequence number of the transaction."
    ),
    startscn STRING OPTIONS (
        DESCRIPTION="Start SCN (System Change Number) of the transaction."
    ),
    rbaBlock STRING OPTIONS (
        DESCRIPTION="RBA (Redo Byte Address) block number."
    ),
    threadNum STRING OPTIONS (
        DESCRIPTION="Oracle thread number."
    ),
    montimestamp TIMESTAMP OPTIONS (
        DESCRIPTION="Timestamp when the transaction started. Renamed from 'timestamp' to avoid reserved keyword."
    ),
    PRIMARY KEY (monopentrxid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="Tracks open Oracle transactions from CDC sources. Each row represents an open transaction at the time of monitoring. Fresh output each run - only currently open transactions are included."
);

