-- Table: striim_mon_node_applications
-- Purpose: Tracks application status and performance metrics across Striim nodes
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Records application states, rates, CPU usage, and activity timestamps

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_node_applications` (
    monappid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    command STRING OPTIONS (
        DESCRIPTION="The equivalent console command to gather the necessary data provided here."
    ),
    montype STRING OPTIONS (
        DESCRIPTION="What type of monitoring command was run."
    ),
    appname STRING OPTIONS (
        DESCRIPTION="The Striim namespace.appName of the app on the node."
    ),
    status STRING OPTIONS (
        DESCRIPTION="The application state (such as: CREATED, DEPLOYED, RUNNING)"
    ),
    rate NUMERIC OPTIONS (
        DESCRIPTION="The rate provided from the mon command for each app."
    ),
    sourcerate NUMERIC OPTIONS (
        DESCRIPTION="The source rate provided from the mon command for each app."
    ),
    cpurate NUMERIC OPTIONS (
        DESCRIPTION="The cpu rate provided from the mon command for each app."
    ),
    numservers INT OPTIONS (
        DESCRIPTION="List the number of servers this application is running on. Normally, this should indicate 1 or 0."
    ),
    latestActivity TIMESTAMP OPTIONS (
        DESCRIPTION="The latest activity seen by the application overall."
    ),
    PRIMARY KEY (monappid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Tracks application status and performance metrics across Striim nodes"
);
