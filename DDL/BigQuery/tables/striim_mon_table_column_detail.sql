-- Table: striim_mon_table_column_detail
-- Purpose: Tracks column-level details and schema information for monitored tables
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Optional table for capturing table schema details including column types and primary keys

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_table_column_detail` (
    montblcoldtlid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    typeName STRING OPTIONS (
        DESCRIPTION="The Striim type name that was produced related to the table."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The predicted app name that utilizes this type. It attempts to match by utilizing the app name + table name → type matching logic."
    ),
    tableName STRING OPTIONS (
        DESCRIPTION="The predicted table name that utilizes this type. It attempts to match by utilizing the app name + table name → type matching logic."
    ),
    createdDate TIMESTAMP OPTIONS (
        DESCRIPTION="When the type was created. By default, StriimWatcher will only produce output entries on first run, and when a type's createdDate has changed."
    ),
    columnName STRING OPTIONS (
        DESCRIPTION="The column name from the table."
    ),
    columnType STRING OPTIONS (
        DESCRIPTION="The column type from the table."
    ),
    isPK BOOL OPTIONS (
        DESCRIPTION="Whether this column is a primary key column."
    ),
    PRIMARY KEY (montblcoldtlid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Tracks column-level details and schema information for monitored tables"
);
