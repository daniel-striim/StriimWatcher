-- Table: striim_mon_table_comparison_sli
-- Purpose: Tracks incremental differences between source and target tables since last interval
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Records changes since last monitoring interval for inserts, updates, deletes, DDLs, and PK updates

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_table_comparison_sli` (
    tblcomparehistoryid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    timesincelastbatch INT64 OPTIONS (
        DESCRIPTION="How many seconds have passed since the last run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The app which has this source/target."
    ),
    sourceName STRING OPTIONS (
        DESCRIPTION="Source table name"
    ),
    targetName STRING OPTIONS (
        DESCRIPTION="Target table name"
    ),
    srcNumOfDeletes_sli INT64 OPTIONS (
        DESCRIPTION="Number of deletes in source table since last interval"
    ),
    tgtNumOfDeletes_sli INT64 OPTIONS (
        DESCRIPTION="Number of deletes in target table since last interval"
    ),
    diffNumOfDeletes_sli INT64 OPTIONS (
        DESCRIPTION="Difference in number of deletes since last interval"
    ),
    srcNumOfDdls_sli INT64 OPTIONS (
        DESCRIPTION="Number of DDLs in source table since last interval"
    ),
    tgtNumOfDdls_sli INT64 OPTIONS (
        DESCRIPTION="Number of DDLs in target table since last interval"
    ),
    diffNumOfDdls_sli INT64 OPTIONS (
        DESCRIPTION="Difference in number of DDLs since last interval"
    ),
    srcNumOfPkupdates_sli INT64 OPTIONS (
        DESCRIPTION="Number of primary key updates in source table since last interval"
    ),
    tgtNumOfPkupdates_sli INT64 OPTIONS (
        DESCRIPTION="Number of primary key updates in target table since last interval"
    ),
    diffNumOfPkupdates_sli INT64 OPTIONS (
        DESCRIPTION="Difference in number of primary key updates since last interval"
    ),
    srcNumOfUpdates_sli INT64 OPTIONS (
        DESCRIPTION="Number of updates in source table since last interval"
    ),
    tgtNumOfUpdates_sli INT64 OPTIONS (
        DESCRIPTION="Number of updates in target table since last interval"
    ),
    diffNumOfUpdates_sli INT64 OPTIONS (
        DESCRIPTION="Difference in number of updates since last interval"
    ),
    srcNumOfInserts_sli INT64 OPTIONS (
        DESCRIPTION="Number of inserts in source table since last interval"
    ),
    tgtNumOfInserts_sli INT64 OPTIONS (
        DESCRIPTION="Number of inserts in target table since last interval"
    ),
    diffNumOfInserts_sli INT64 OPTIONS (
        DESCRIPTION="Difference in number of inserts since last interval"
    ),

    -- Component Information
    sourceComponentName STRING OPTIONS (
        DESCRIPTION="Source component name from monitoring command"
    ),
    targetComponentName STRING OPTIONS (
        DESCRIPTION="Target component name from monitoring command"
    ),

    PRIMARY KEY (tblcomparehistoryid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Tracks incremental differences between source and target tables since last interval"
);
