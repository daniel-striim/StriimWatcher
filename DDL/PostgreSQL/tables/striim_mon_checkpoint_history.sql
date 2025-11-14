-- Table: striim_mon_checkpoint_history
-- Purpose: Checkpoint history tracking for Striim applications with recovery enabled
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures checkpoint history entries for applications, tracking only new checkpoints to provide historical audit trail

CREATE TABLE mon.striim_mon_checkpoint_history (
    monchkpthistid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appName TEXT,
    serialNo BIGINT,
    sourcePositionSummary TEXT,
    targetPositionSummary TEXT,
    checkpointType TEXT,
    checkpointRecordedTime TIMESTAMP
);

