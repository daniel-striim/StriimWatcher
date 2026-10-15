-- Table: striim_mon_ojet_ext_metrics
-- Purpose: Extended OJet metrics from Striim Oracle CDC sources
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: One row per OJet source per batch with reader status/memory values and checkpoint
--              SCNs from that source's stored checkpoint.

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_ojet_ext_metrics` (
    monojetextid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The full name of the Striim application (e.g., 'admin.OracleCDC')."
    ),
    componentName STRING OPTIONS (
        DESCRIPTION="The name of the source component being monitored."
    ),
    -- SHOW <source> STATUS
    serverStatus STRING OPTIONS (
        DESCRIPTION="ServerStatus from SHOW <source> STATUS."
    ),
    enqueue STRING OPTIONS (
        DESCRIPTION="Enqueue from SHOW <source> STATUS."
    ),
    dequeue STRING OPTIONS (
        DESCRIPTION="Dequeue from SHOW <source> STATUS."
    ),
    captureStatus STRING OPTIONS (
        DESCRIPTION="CaptureStatus from SHOW <source> STATUS."
    ),
    captureState STRING OPTIONS (
        DESCRIPTION="CaptureState from SHOW <source> STATUS."
    ),
    spillCount STRING OPTIONS (
        DESCRIPTION="SpillCount from SHOW <source> STATUS."
    ),
    progress STRING OPTIONS (
        DESCRIPTION="Progress from SHOW <source> STATUS."
    ),
    error STRING OPTIONS (
        DESCRIPTION="Error from SHOW <source> STATUS."
    ),
    -- SHOW <source> STATUS details
    firstScn STRING OPTIONS (
        DESCRIPTION="FIRST_SCN from SHOW <source> STATUS details."
    ),
    startScn STRING OPTIONS (
        DESCRIPTION="START_SCN from SHOW <source> STATUS details."
    ),
    appliedScn STRING OPTIONS (
        DESCRIPTION="APPLIED_SCN from SHOW <source> STATUS details."
    ),
    capturedScn STRING OPTIONS (
        DESCRIPTION="CAPTURED_SCN from SHOW <source> STATUS details."
    ),
    oldestScn STRING OPTIONS (
        DESCRIPTION="OLDEST_SCN from SHOW <source> STATUS details."
    ),
    filteredScn STRING OPTIONS (
        DESCRIPTION="FILTERED_SCN from SHOW <source> STATUS details."
    ),
    messagesCaptured STRING OPTIONS (
        DESCRIPTION="MESSAGES_CAPTURED from SHOW <source> STATUS details."
    ),
    messagesEnqueued STRING OPTIONS (
        DESCRIPTION="MESSAGES_ENQUEUED from SHOW <source> STATUS details."
    ),
    captureTime STRING OPTIONS (
        DESCRIPTION="CAPTURE_TIME from SHOW <source> STATUS details."
    ),
    ruleTime STRING OPTIONS (
        DESCRIPTION="RULE_TIME from SHOW <source> STATUS details."
    ),
    enqueueTime STRING OPTIONS (
        DESCRIPTION="ENQUEUE_TIME from SHOW <source> STATUS details."
    ),
    lcrTime STRING OPTIONS (
        DESCRIPTION="LCR_TIME from SHOW <source> STATUS details."
    ),
    redoWaitTime STRING OPTIONS (
        DESCRIPTION="REDO_WAIT_TIME from SHOW <source> STATUS details."
    ),
    redoMined STRING OPTIONS (
        DESCRIPTION="REDO_MINED from SHOW <source> STATUS details."
    ),
    restartScn STRING OPTIONS (
        DESCRIPTION="RESTART_SCN from SHOW <source> STATUS details."
    ),
    -- SHOW <source> memory
    logMinerSession STRING OPTIONS (
        DESCRIPTION="LogMinerSession from SHOW <source> memory."
    ),
    captureSession STRING OPTIONS (
        DESCRIPTION="CaptureSession from SHOW <source> memory."
    ),
    applySession STRING OPTIONS (
        DESCRIPTION="ApplySession from SHOW <source> memory."
    ),
    streamsPool STRING OPTIONS (
        DESCRIPTION="StreamsPool from SHOW <source> memory."
    ),
    -- SHOW <source> memory details
    logMinerUsed STRING OPTIONS (
        DESCRIPTION="LOG_MINER_USED from SHOW <source> memory details."
    ),
    logMinerMax STRING OPTIONS (
        DESCRIPTION="LOG_MINER_MAX from SHOW <source> memory details."
    ),
    captureUsed STRING OPTIONS (
        DESCRIPTION="CAPTURE_USED from SHOW <source> memory details."
    ),
    captureAllocated STRING OPTIONS (
        DESCRIPTION="CAPTURE_ALLOCATED from SHOW <source> memory details."
    ),
    applyUsed STRING OPTIONS (
        DESCRIPTION="APPLY_USED from SHOW <source> memory details."
    ),
    applyAllocated STRING OPTIONS (
        DESCRIPTION="APPLY_ALLOCATED from SHOW <source> memory details."
    ),
    streamsUsed STRING OPTIONS (
        DESCRIPTION="STREAMS_USED from SHOW <source> memory details."
    ),
    streamsAllocated STRING OPTIONS (
        DESCRIPTION="STREAMS_ALLOCATED from SHOW <source> memory details."
    ),
    msgsInMem STRING OPTIONS (
        DESCRIPTION="MSGS_IN_MEM from SHOW <source> memory details."
    ),
    msgsSpilled STRING OPTIONS (
        DESCRIPTION="MSGS_SPILLED from SHOW <source> memory details."
    ),
    txnsRollback STRING OPTIONS (
        DESCRIPTION="TXNS_ROLLBACK from SHOW <source> memory details."
    ),
    propagationState STRING OPTIONS (
        DESCRIPTION="PROPAGATION_STATE from SHOW <source> memory details."
    ),
    -- Per-source stored checkpoint positions
    restartPositionCommitScn STRING OPTIONS (
        DESCRIPTION="CommitSCN from this source stored restart checkpoint position."
    ),
    restartPositionCurrentScn STRING OPTIONS (
        DESCRIPTION="CurrentSCN from this source stored restart checkpoint position."
    ),
    restartPositionRecoveryScn STRING OPTIONS (
        DESCRIPTION="RecoverySCN from this source stored restart checkpoint position."
    ),
    currentPositionCommitScn STRING OPTIONS (
        DESCRIPTION="CommitSCN from this source stored current checkpoint position."
    ),
    currentPositionCurrentScn STRING OPTIONS (
        DESCRIPTION="CurrentSCN from this source stored current checkpoint position."
    ),
    currentPositionRecoveryScn STRING OPTIONS (
        DESCRIPTION="RecoverySCN from this source stored current checkpoint position."
    ),
    PRIMARY KEY (monojetextid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="Extended OJet reader status and memory values plus checkpoint SCNs from each source stored checkpoint"
);
