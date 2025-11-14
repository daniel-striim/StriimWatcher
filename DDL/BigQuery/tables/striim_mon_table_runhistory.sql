-- Table: striim_mon_table_runhistory
-- Purpose: Core table that tracks StriimWatcher execution runs
-- Dependencies: None (base table)
-- Description: Records when StriimWatcher runs, duration, cluster info, and scheduling

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_table_runhistory` (
    runid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference, datetime of when this batch was run."
    ),
    runtimeEnd TIMESTAMP OPTIONS (
        DESCRIPTION="The time when the StriimWatcher app finished all its internal calls."
    ),
    runtimeDurationMS NUMERIC OPTIONS (
        DESCRIPTION="The length of time, in milliseconds, for how long it took StriimWatcher from start to finish."
    ),
    clusterName STRING OPTIONS (
        DESCRIPTION="The 'clustername' from the startUp.properties file."
    ),
    companyName STRING OPTIONS (
        DESCRIPTION="The 'companyname' from the startUp.properties file."
    ),
    lastrun TIMESTAMP OPTIONS (
        DESCRIPTION="Either a default start value, or the actual last run of the StriimWatcher app."
    ),
    nextrun TIMESTAMP OPTIONS (
        DESCRIPTION="The next planned run, based on configured value 'RepeatInSeconds'."
    ),
    PRIMARY KEY (runid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="Core table that tracks StriimWatcher execution runs, cluster information, and scheduling details"
);
