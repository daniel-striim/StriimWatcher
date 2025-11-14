

CREATE TABLE mon.striim_mon_node_applications (
    monappid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    montype TEXT,
    appname TEXT,
    status TEXT,
    rate NUMERIC,
    sourcerate NUMERIC,
    cpurate NUMERIC,
    numservers INTEGER,
    latestActivity TIMESTAMP
);

