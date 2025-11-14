CREATE TABLE mon.striim_mon_node_elasticsearch (
    monnodesid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    montype TEXT,
    elasticsearchReceiveThroughput BIGINT,
    elasticsearchTransmitThroughput BIGINT,
    elasticsearchClusterStorageFree BIGINT,
    elasticsearchClusterStorageTotal BIGINT
);

