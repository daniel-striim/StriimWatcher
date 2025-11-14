-- Table: striim_mon_checkpoint_history
-- Purpose: Checkpoint history tracking for Striim applications with recovery enabled
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Captures checkpoint history entries for applications, tracking only new checkpoints to provide historical audit trail

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_checkpoint_history` (
    monchkpthistid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The full name of the Striim application (e.g., 'admin.SQLCDC'). This is the application for which checkpoint history is being tracked."
    ),
    serialNo INT64 OPTIONS (
        DESCRIPTION="The serial number of the checkpoint entry. Lower numbers indicate more recent checkpoints. This is assigned by Striim and increments with each new checkpoint."
    ),
    sourcePositionSummary STRING OPTIONS (
        DESCRIPTION="Summary of the source position at the time of checkpoint. Contains details about SOURCE RESTART POSITION and SOURCE CURRENT POSITION, including table names, commit SCNs, sequence values, or other source-specific position markers. Format varies by source type (Oracle CDC, SQL Server CDC, PostgreSQL, etc.)."
    ),
    targetPositionSummary STRING OPTIONS (
        DESCRIPTION="Summary of the target position at the time of checkpoint. Contains details about TARGET ACKNOWLEDGED POSITION, showing what data has been successfully written and acknowledged by the target. May be NULL if target position is not available. Format varies by target type."
    ),
    checkpointType STRING OPTIONS (
        DESCRIPTION="The type of checkpoint. Common values include 'normal' for regular checkpoints. May include other types like 'manual' or 'recovery' depending on how the checkpoint was created."
    ),
    checkpointRecordedTime TIMESTAMP OPTIONS (
        DESCRIPTION="The timestamp when this checkpoint was recorded by Striim. This is the actual time the checkpoint was created, not when it was discovered by StriimWatcher."
    ),
    PRIMARY KEY (monchkpthistid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="Checkpoint history tracking for Striim applications - only new checkpoints are recorded to provide historical audit trail"
);

