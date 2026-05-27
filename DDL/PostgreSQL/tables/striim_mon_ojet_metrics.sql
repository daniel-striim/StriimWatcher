-- StriimWatcher PostgreSQL DDL
-- Table: striim_mon_ojet_metrics

DROP TABLE IF EXISTS mon.striim_mon_ojet_metrics CASCADE;

CREATE TABLE mon.striim_mon_ojet_metrics (
    monojetid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appname TEXT,
    componentname TEXT,
    memusagelogminer DOUBLE PRECISION,
    memusagecapture DOUBLE PRECISION,
    memusageapply DOUBLE PRECISION,
    memusagestreamspool DOUBLE PRECISION,
    txnspillingtodisk BOOLEAN,
    lastobservedscn TEXT,
    currentscn TEXT,
    redoswitchcount TEXT,
    logmnrrecordcount TEXT,
    lastobservedtimestamp TIMESTAMP
);

COMMENT ON TABLE mon.striim_mon_ojet_metrics IS 'OJet (Oracle Java Edition Tracker) metrics from Striim CDC sources';
