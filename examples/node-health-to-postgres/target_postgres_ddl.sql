-- node-health-to-postgres — target (mon.*) tables written by StriimWatcher.
-- Only the tables this node-only example populates. Schema + ${TID} prefix keep concurrent
-- parallel runs isolated; ${TID} renders "" on a single run and a distinct id per parallel run.

DROP TABLE IF EXISTS ${PG_TARGET_SCHEMA}.${TID}striim_mon_node_applications CASCADE;
CREATE TABLE ${PG_TARGET_SCHEMA}.${TID}striim_mon_node_applications (
    monappid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    montype TEXT,
    appname TEXT,
    status TEXT,
    rate DOUBLE PRECISION,
    sourcerate INTEGER,
    cpurate DOUBLE PRECISION,
    numservers INTEGER,
    latestactivity TIMESTAMP
);

DROP TABLE IF EXISTS ${PG_TARGET_SCHEMA}.${TID}striim_mon_node_cluster CASCADE;
CREATE TABLE ${PG_TARGET_SCHEMA}.${TID}striim_mon_node_cluster (
    monnodeclusterid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    montype TEXT,
    nodename TEXT,
    striimversion TEXT,
    freemem TEXT,
    cpurate DOUBLE PRECISION,
    uptime TEXT
);

DROP TABLE IF EXISTS ${PG_TARGET_SCHEMA}.${TID}striim_mon_node_elasticsearch CASCADE;
CREATE TABLE ${PG_TARGET_SCHEMA}.${TID}striim_mon_node_elasticsearch (
    monnodesid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    montype TEXT,
    elasticsearchreceivethroughput BIGINT,
    elasticsearchtransmitthroughput BIGINT,
    elasticsearchclusterstoragefree BIGINT,
    elasticsearchclusterstoragetotal BIGINT
);

DROP TABLE IF EXISTS ${PG_TARGET_SCHEMA}.${TID}striim_mon_table_runhistory CASCADE;
CREATE TABLE ${PG_TARGET_SCHEMA}.${TID}striim_mon_table_runhistory (
    runid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    runtimeend TIMESTAMP,
    runtimedurationms INTEGER,
    clustername TEXT,
    companyname TEXT,
    lastrun TIMESTAMP,
    nextrun TIMESTAMP
);
