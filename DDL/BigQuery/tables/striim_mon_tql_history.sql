-- Table: striim_mon_tql_history
-- Purpose: TQL change tracking history for application component properties
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Tracks property-level changes detected across all app components (SOURCE, TARGET, STREAM, CQ, WINDOW, CACHE, TYPE)

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_tql_history` (
    montqlhistid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The full name of the Striim application (e.g., 'admin.SQLCDC')."
    ),
    componentType STRING OPTIONS (
        DESCRIPTION="The type of the component where the change was detected (SOURCE, TARGET, STREAM, CQ, WINDOW, CACHE, TYPE)."
    ),
    componentName STRING OPTIONS (
        DESCRIPTION="The full name of the component where the property change was detected."
    ),
    propertyName STRING OPTIONS (
        DESCRIPTION="The name of the property that changed."
    ),
    changeType STRING OPTIONS (
        DESCRIPTION="The type of change detected (ADDED, REMOVED, MODIFIED)."
    ),
    propertyValue STRING OPTIONS (
        DESCRIPTION="The current value of the changed property."
    ),
    detectedAt TIMESTAMP OPTIONS (
        DESCRIPTION="The timestamp when this property change was first detected by StriimWatcher."
    ),
    PRIMARY KEY (montqlhistid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="TQL change tracking history for application component properties — captures additions, removals, and modifications"
);
