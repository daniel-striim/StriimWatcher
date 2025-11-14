-- Table: striim_mon_system_configuration
-- Purpose: System configuration and resource monitoring including configuration files, memory metrics, and disk space
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures system-level configuration and resource metrics for monitoring Striim server health and configuration changes

CREATE TABLE mon.striim_mon_system_configuration (
    monsysconfigid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    configType TEXT,
    parameterName TEXT,
    parameterValue TEXT,
    valueChanged BOOLEAN,
    jsonDetail TEXT
);

