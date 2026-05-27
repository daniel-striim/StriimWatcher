-- Script: Upgrade striim_mon_appdetail to add backpressuredcomponents column
-- Purpose: StriimWatcher uses positional column mapping; ALTER TABLE ADD COLUMN appends
--          to the end and will misalign columns from position 8 onward. This script
--          renames the existing table as a backup, recreates it with the correct column
--          order, then restores the data with NULL for the new column.
-- Usage: Run steps in order. Verify row counts match before dropping the backup.

-- Step 1: Rename existing table as backup
ALTER TABLE mon.striim_mon_appdetail RENAME TO striim_mon_appdetail_v1_backup;

-- Step 2: Recreate table with correct column order (backpressuredcomponents at position 8)
CREATE TABLE mon.striim_mon_appdetail (
    monid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    appName TEXT,
    appStatus TEXT,
    totalInput BIGINT,
    totalOutput BIGINT,
    isBackpressured BOOLEAN,
    backpressuredcomponents TEXT,
    isRecoveryEnabled BOOLEAN,
    recoverySetting TEXT,
    checkpointStatus TEXT,
    checkpointDetail TEXT,
    isEncryptionEnabled BOOLEAN,
    deploymentOn TEXT,
    deploymentIn TEXT,
    appCreatedDate TIMESTAMP,
    latestActivity TIMESTAMP
);

-- Step 3: Restore data — backpressuredcomponents defaults to NULL for historical rows
INSERT INTO mon.striim_mon_appdetail
SELECT
    monid, batchdate, command, appName, appStatus,
    totalInput, totalOutput, isBackpressured,
    NULL AS backpressuredcomponents,
    isRecoveryEnabled, recoverySetting,
    checkpointStatus, checkpointDetail,
    isEncryptionEnabled, deploymentOn, deploymentIn,
    appCreatedDate, latestActivity
FROM mon.striim_mon_appdetail_v1_backup;

-- Step 4: Verify row counts match before dropping backup
SELECT 'new' AS tbl, COUNT(*) AS cnt FROM mon.striim_mon_appdetail
UNION ALL
SELECT 'backup', COUNT(*) FROM mon.striim_mon_appdetail_v1_backup;

-- Step 5: Drop backup once verified (uncomment when ready)
-- DROP TABLE mon.striim_mon_appdetail_v1_backup;
