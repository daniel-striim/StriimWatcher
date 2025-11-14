-- Table: striim_mon_node_cluster
-- Purpose: Tracks cluster node information and system resource metrics
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Records node details, Striim versions, memory, CPU, and uptime

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_node_cluster` (
    monnodeclusterid INT64 OPTIONS (
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
    nodename STRING OPTIONS (
        DESCRIPTION="The name of the node."
    ),
    striimversion STRING OPTIONS (
        DESCRIPTION="The Striim version number of the node."
    ),
    freemem STRING OPTIONS (
        DESCRIPTION="The amount of free memory on the server."
    ),
    cpurate NUMERIC OPTIONS (
        DESCRIPTION="The current CPU rate. NOTE: it is usually a 100%/core based; this means that an 8 core system can utilize 800% cpurate."
    ),
    uptime STRING OPTIONS (
        DESCRIPTION="Indicates how long the Striim Server has been up for."
    ),
    PRIMARY KEY (monnodeclusterid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Tracks cluster node information and system resource metrics"
);
