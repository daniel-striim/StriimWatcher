-- Table: striim_mon_component_output
-- Purpose: Stores raw JSON output from monitoring commands for detailed component analysis
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Optional table for capturing raw API responses for sources, targets, and other components

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_component_output` (
    moncomoutid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The related application name for the json monitor data output."
    ),
    componentName STRING OPTIONS (
        DESCRIPTION="The name of the component monitored."
    ),
    command STRING OPTIONS (
        DESCRIPTION="Type type of command (mon or describe)."
    ),
    type STRING OPTIONS (
        DESCRIPTION="The type of component (APP, SOURCE, STREAM, TARGET, TYPE)."
    ),
    jsondata JSON OPTIONS (
        DESCRIPTION="The raw JSON output of the API response. This can be useful in instances where we need to track properties of sources or targets, by capturing the DESCRIBE data."
    ),
    PRIMARY KEY (moncomoutid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Stores raw JSON output from monitoring commands for detailed component analysis"
);
