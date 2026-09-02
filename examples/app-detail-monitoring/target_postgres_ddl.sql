-- app-detail-monitoring — target (mon.*) tables written by StriimWatcher.
-- Also creates the companion monitored pipeline's TARGET table (${TID}sw_orders) so the demo
-- Postgres→Postgres initial load has somewhere to land. Schema + ${TID} keep concurrent runs isolated.

-- Companion monitored pipeline's target table (source→target initial load lands here).
DROP TABLE IF EXISTS ${PG_TARGET_SCHEMA}.${TID}sw_orders CASCADE;
CREATE TABLE ${PG_TARGET_SCHEMA}.${TID}sw_orders (
    id INTEGER PRIMARY KEY,
    val TEXT
);

-- StriimWatcher output: per-application detail.
DROP TABLE IF EXISTS ${PG_TARGET_SCHEMA}.${TID}striim_mon_appdetail CASCADE;
CREATE TABLE ${PG_TARGET_SCHEMA}.${TID}striim_mon_appdetail (
    monid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    appname TEXT,
    appstatus TEXT,
    totalinput INTEGER,
    totaloutput INTEGER,
    isbackpressured BOOLEAN,
    isrecoveryenabled BOOLEAN,
    recoverysetting TEXT,
    checkpointstatus TEXT,
    checkpointdetail TEXT,
    isencryptionenabled BOOLEAN,
    deploymenton TEXT,
    deploymentin TEXT,
    appcreateddate TIMESTAMP,
    latestactivity TIMESTAMP
);

-- StriimWatcher output: run history (always emitted last each cycle).
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
