-- Table: striim_mon_table_comparison
-- Purpose: Tracks cumulative differences between source and target tables
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Records total counts and differences for inserts, updates, deletes, DDLs, and PK updates

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_table_comparison` (
    tblcompareid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The app which has this source/target."
    ),
    sourceName STRING OPTIONS (
        DESCRIPTION="The table name of the source."
    ),
    targetName STRING OPTIONS (
        DESCRIPTION="The table name of the target."
    ),
    srcNumOfDeletes INT64 OPTIONS (
        DESCRIPTION="Number of deletes in source table"
    ),
    tgtNumOfDeletes INT64 OPTIONS (
        DESCRIPTION="Number of deletes in target table"
    ),
    diffNumOfDeletes INT64 OPTIONS (
        DESCRIPTION="Difference in number of deletes"
    ),
    srcNumOfDdls INT64 OPTIONS (
        DESCRIPTION="Number of DDLs in source table"
    ),
    tgtNumOfDdls INT64 OPTIONS (
        DESCRIPTION="Number of DDLs in target table"
    ),
    diffNumOfDdls INT64 OPTIONS (
        DESCRIPTION="Difference in number of DDLs"
    ),
    srcNumOfPkupdates INT64 OPTIONS (
        DESCRIPTION="Number of primary key updates in source table"
    ),
    tgtNumOfPkupdates INT64 OPTIONS (
        DESCRIPTION="Number of primary key updates in target table"
    ),
    diffNumOfPkupdates INT64 OPTIONS (
        DESCRIPTION="Difference in number of primary key updates"
    ),
    srcNumOfUpdates INT64 OPTIONS (
        DESCRIPTION="Number of updates in source table"
    ),
    tgtNumOfUpdates INT64 OPTIONS (
        DESCRIPTION="Number of updates in target table"
    ),
    diffNumOfUpdates INT64 OPTIONS (
        DESCRIPTION="Difference in number of updates"
    ),
    srcNumOfInserts INT64 OPTIONS (
        DESCRIPTION="Number of inserts in source table"
    ),
    tgtNumOfInserts INT64 OPTIONS (
        DESCRIPTION="Number of inserts in target table"
    ),
    diffNumOfInserts INT64 OPTIONS (
        DESCRIPTION="Difference in number of inserts"
    ),

    -- Component Information
    sourceComponentName STRING OPTIONS (
        DESCRIPTION="Source component name from monitoring command"
    ),
    targetComponentName STRING OPTIONS (
        DESCRIPTION="Target component name from monitoring command"
    ),

    PRIMARY KEY (tblcompareid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Tracks cumulative differences between source and target tables"
);
