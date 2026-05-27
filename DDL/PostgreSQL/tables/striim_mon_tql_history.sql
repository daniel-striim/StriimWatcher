-- StriimWatcher PostgreSQL DDL
-- Table: striim_mon_tql_history

DROP TABLE IF EXISTS mon.striim_mon_tql_history CASCADE;

CREATE TABLE mon.striim_mon_tql_history (
    montqlhistid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appname TEXT,
    componenttype TEXT,
    componentname TEXT,
    propertyname TEXT,
    changetype TEXT,
    propertyvalue TEXT,
    detectedat TIMESTAMP
);

COMMENT ON TABLE mon.striim_mon_tql_history IS 'TQL change tracking history for applications';
