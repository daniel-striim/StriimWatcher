-- Script: Migrate striim_mon_appdetail — move backpressuredcomponents to last column
-- Purpose: backpressuredcomponents moved from position 9 (after isbackpressured) to last
--          (after latestactivity) to match StriimWatcher positional output order.
--          PostgreSQL does not support ALTER TABLE ... ALTER COLUMN ORDER, so full recreate required.
-- Usage: Run steps in order. Verify row counts match before dropping the backup.
-- Note: If upgrading from a schema that has NO backpressuredcomponents column at all,
--       replace backpressuredcomponents in the INSERT SELECT with NULL AS backpressuredcomponents.

-- Step 1: Rename existing table as backup
ALTER TABLE mon.striim_mon_appdetail RENAME TO striim_mon_appdetail_v2_backup;

-- Step 2: Recreate table with correct column order (backpressuredcomponents last)
CREATE TABLE mon.striim_mon_appdetail (
    monid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    command TEXT,
    appName TEXT,
    appStatus TEXT,
    totalInput BIGINT,
    totalOutput BIGINT,
    isBackpressured BOOLEAN,
    isRecoveryEnabled BOOLEAN,
    recoverySetting TEXT,
    checkpointStatus TEXT,
    checkpointDetail TEXT,
    isEncryptionEnabled BOOLEAN,
    deploymentOn TEXT,
    deploymentIn TEXT,
    appCreatedDate TIMESTAMP,
    latestActivity TIMESTAMP,
    backpressuredcomponents TEXT
);

-- Step 3: Restore data — backpressuredcomponents preserved from backup (was at old position 9)
INSERT INTO mon.striim_mon_appdetail
SELECT
    monid, batchdate, command, appName, appStatus,
    totalInput, totalOutput, isBackpressured,
    isRecoveryEnabled, recoverySetting,
    checkpointStatus, checkpointDetail,
    isEncryptionEnabled, deploymentOn, deploymentIn,
    appCreatedDate, latestActivity,
    backpressuredcomponents
FROM mon.striim_mon_appdetail_v2_backup;

-- Step 4: Verify row counts match before dropping backup
SELECT 'new' AS tbl, COUNT(*) AS cnt FROM mon.striim_mon_appdetail
UNION ALL
SELECT 'backup', COUNT(*) FROM mon.striim_mon_appdetail_v2_backup;

-- Step 5: Drop backup once verified (uncomment when ready)
-- DROP TABLE mon.striim_mon_appdetail_v2_backup;
