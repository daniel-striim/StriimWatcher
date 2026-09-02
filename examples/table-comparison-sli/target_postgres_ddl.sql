-- table-comparison-sli — target (mon.*) tables written by StriimWatcher, plus the companion
-- monitored pipeline's target table. Schema + ${TID} keep concurrent runs isolated.

-- Companion monitored pipeline's target table (source→target initial load lands here).
DROP TABLE IF EXISTS ${PG_TARGET_SCHEMA}.${TID}sw_orders CASCADE;
CREATE TABLE ${PG_TARGET_SCHEMA}.${TID}sw_orders (
    id INTEGER PRIMARY KEY,
    val TEXT
);

-- StriimWatcher output: cumulative source-vs-target comparison.
DROP TABLE IF EXISTS ${PG_TARGET_SCHEMA}.${TID}striim_mon_table_comparison CASCADE;
CREATE TABLE ${PG_TARGET_SCHEMA}.${TID}striim_mon_table_comparison (
    tblcompareid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appname TEXT,
    sourcename TEXT,
    targetname TEXT,
    srcnumofdeletes INTEGER,
    tgtnumofdeletes INTEGER,
    diffnumofdeletes INTEGER,
    srcnumofddls INTEGER,
    tgtnumofddls INTEGER,
    diffnumofddls INTEGER,
    srcnumofpkupdates INTEGER,
    tgtnumofpkupdates INTEGER,
    diffnumofpkupdates INTEGER,
    srcnumofupdates INTEGER,
    tgtnumofupdates INTEGER,
    diffnumofupdates INTEGER,
    srcnumofinserts INTEGER,
    tgtnumofinserts INTEGER,
    diffnumofinserts INTEGER,
    sourcecomponentname TEXT,
    targetcomponentname TEXT
);

-- StriimWatcher output: since-last-interval (SLI) delta (appears from the 2nd cycle onward).
DROP TABLE IF EXISTS ${PG_TARGET_SCHEMA}.${TID}striim_mon_table_comparison_sli CASCADE;
CREATE TABLE ${PG_TARGET_SCHEMA}.${TID}striim_mon_table_comparison_sli (
    tblcomparesliid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    timesincelastbatch BIGINT,
    appname TEXT,
    sourcename TEXT,
    targetname TEXT,
    srcnumofdeletes_sli INTEGER,
    tgtnumofdeletes_sli INTEGER,
    diffnumofdeletes_sli INTEGER,
    srcnumofddls_sli INTEGER,
    tgtnumofddls_sli INTEGER,
    diffnumofddls_sli INTEGER,
    srcnumofpkupdates_sli INTEGER,
    tgtnumofpkupdates_sli INTEGER,
    diffnumofpkupdates_sli INTEGER,
    srcnumofupdates_sli INTEGER,
    tgtnumofupdates_sli INTEGER,
    diffnumofupdates_sli INTEGER,
    srcnumofinserts_sli INTEGER,
    tgtnumofinserts_sli INTEGER,
    diffnumofinserts_sli INTEGER,
    sourcecomponentname TEXT,
    targetcomponentname TEXT
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
