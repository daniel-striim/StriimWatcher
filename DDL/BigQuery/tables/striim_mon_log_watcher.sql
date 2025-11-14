-- Table: striim_mon_log_watcher
-- Purpose: Tracks Striim server log errors and messages for monitoring and alerting
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures log entries from Striim server logs for error tracking and analysis

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_log_watcher` (
    errorid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    log_date TIMESTAMP OPTIONS (
        DESCRIPTION="The timestamp when the log entry was created."
    ),
    server STRING OPTIONS (
        DESCRIPTION="The server name where the log entry originated."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The application name associated with the log entry, if applicable."
    ),
    log_level STRING OPTIONS (
        DESCRIPTION="The log level (ERROR, WARN, INFO, DEBUG, etc.)."
    ),
    message STRING OPTIONS (
        DESCRIPTION="The log message content."
    ),
    contextbuffertext STRING OPTIONS (
        DESCRIPTION="Additional context buffer text associated with the log entry."
    ),
    PRIMARY KEY (errorid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Tracks Striim server log errors and messages for monitoring and alerting"
);
