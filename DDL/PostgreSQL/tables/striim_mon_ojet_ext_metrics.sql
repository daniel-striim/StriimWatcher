-- StriimWatcher PostgreSQL DDL
-- Table: striim_mon_ojet_ext_metrics
-- Extended OJet reader status/memory values and checkpoint SCNs from the source's stored checkpoint.

DROP TABLE IF EXISTS mon.striim_mon_ojet_ext_metrics CASCADE;

CREATE TABLE mon.striim_mon_ojet_ext_metrics (
    monojetextid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appname TEXT,
    componentname TEXT,
    -- SHOW <source> STATUS
    serverstatus TEXT,
    enqueue TEXT,
    dequeue TEXT,
    capturestatus TEXT,
    capturestate TEXT,
    spillcount TEXT,
    progress TEXT,
    error TEXT,
    -- SHOW <source> STATUS details
    firstscn TEXT,
    startscn TEXT,
    appliedscn TEXT,
    capturedscn TEXT,
    oldestscn TEXT,
    filteredscn TEXT,
    messagescaptured TEXT,
    messagesenqueued TEXT,
    capturetime TEXT,
    ruletime TEXT,
    enqueuetime TEXT,
    lcrtime TEXT,
    redowaittime TEXT,
    redomined TEXT,
    restartscn TEXT,
    -- SHOW <source> memory
    logminersession TEXT,
    capturesession TEXT,
    applysession TEXT,
    streamspool TEXT,
    -- SHOW <source> memory details
    logminerused TEXT,
    logminermax TEXT,
    captureused TEXT,
    captureallocated TEXT,
    applyused TEXT,
    applyallocated TEXT,
    streamsused TEXT,
    streamsallocated TEXT,
    msgsinmem TEXT,
    msgsspilled TEXT,
    txnsrollback TEXT,
    propagationstate TEXT,
    -- Per-source stored checkpoint positions
    restartpositioncommitscn TEXT,
    restartpositioncurrentscn TEXT,
    restartpositionrecoveryscn TEXT,
    currentpositioncommitscn TEXT,
    currentpositioncurrentscn TEXT,
    currentpositionrecoveryscn TEXT
);

COMMENT ON TABLE mon.striim_mon_ojet_ext_metrics IS 'Extended OJet reader status and memory values plus checkpoint SCNs from each source stored checkpoint';
