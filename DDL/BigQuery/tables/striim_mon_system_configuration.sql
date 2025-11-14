-- Table: striim_mon_system_configuration
-- Purpose: System configuration and resource monitoring including configuration files, memory metrics, and disk space
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures system-level configuration and resource metrics for monitoring Striim server health and configuration changes

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_system_configuration` (
    monsysconfigid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    configType STRING OPTIONS (
        DESCRIPTION="Type of configuration entry: CONFIG_FILE (configuration files like startUp.properties, agent.conf), MEMORY (JVM and physical memory metrics), or DISK_SPACE (filesystem space metrics)."
    ),
    parameterName STRING OPTIONS (
        DESCRIPTION="The parameter name, metric name, filename, or filesystem path depending on configType. For CONFIG_FILE: filename (e.g., 'startUp.properties'). For MEMORY: metric name (e.g., 'JVM Max Memory (bytes)'). For DISK_SPACE: filesystem path (e.g., '/', 'C:\\')."
    ),
    parameterValue STRING OPTIONS (
        DESCRIPTION="The value of the parameter or metric. For CONFIG_FILE: JSON object with key-value pairs from the config file. For MEMORY: numeric value in bytes. For DISK_SPACE: JSON object with total_bytes, free_bytes, usable_bytes, used_bytes."
    ),
    valueChanged BOOLEAN OPTIONS (
        DESCRIPTION="Indicates whether this value changed from the previous monitoring run. True if changed or first time seen, false if unchanged. Used for change detection when IncludeOnlyNoticedConfChanges is enabled."
    ),
    jsonDetail STRING OPTIONS (
        DESCRIPTION="Full JSON output from the system configuration collection methods (getConfDetails, getSystemMemory, getSystemSpace). Only populated if IncludeSystemConfigurationDetail flag is enabled, otherwise NULL."
    ),
    PRIMARY KEY (monsysconfigid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="System configuration and resource monitoring including configuration files, memory metrics, and disk space"
);

