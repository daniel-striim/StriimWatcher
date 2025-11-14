CREATE TABLE mon.striim_mon_component_output (
    moncomoutid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appName TEXT,
    componentName TEXT,
    command TEXT,
    type TEXT,
    jsondata JSONB
);

