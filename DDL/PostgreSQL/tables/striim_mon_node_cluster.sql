CREATE TABLE mon.striim_mon_node_cluster (
    monnodeclusterid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    montype TEXT,
    nodename TEXT,
    striimversion TEXT,
    freemem TEXT,
    cpurate NUMERIC,
    uptime TEXT
);

