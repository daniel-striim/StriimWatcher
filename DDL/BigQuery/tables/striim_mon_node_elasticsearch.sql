-- Table: striim_mon_node_elasticsearch
-- Purpose: Tracks Elasticsearch cluster metrics and throughput
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Records Elasticsearch throughput and storage metrics

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_node_elasticsearch` (
    monnodesid INT64 OPTIONS (
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
    elasticsearchReceiveThroughput INT64 OPTIONS (
        DESCRIPTION="Receive throughput of Elasticsearch"
    ),
    elasticsearchTransmitThroughput INT64 OPTIONS (
        DESCRIPTION="Transmit throughput of Elasticsearch"
    ),
    elasticsearchClusterStorageFree INT64 OPTIONS (
        DESCRIPTION="Free storage in Elasticsearch cluster"
    ),
    elasticsearchClusterStorageTotal INT64 OPTIONS (
        DESCRIPTION="Total storage in Elasticsearch cluster"
    ),
    PRIMARY KEY (monnodesid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Tracks Elasticsearch cluster metrics and throughput"
);
