

CREATE TABLE mon.striim_mon_table_runhistory (
    runid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    runtimeEnd TIMESTAMP,
    runtimeDurationMS NUMERIC,
    clusterName TEXT,
    companyName TEXT,
    lastrun TIMESTAMP,
    nextrun TIMESTAMP
);

