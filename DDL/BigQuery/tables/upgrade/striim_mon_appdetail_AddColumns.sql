-- Script: Migrate striim_mon_appdetail — move backpressuredComponents to last column
-- Purpose: backpressuredComponents moved from position 9 (after isBackpressured) to last
--          (after latestActivity) to match StriimWatcher positional output order.
--          BQ does not support ALTER TABLE ... ALTER COLUMN ORDER, so full recreate required.
-- Usage: Run steps in order. Verify row counts match before dropping the backup.
-- Note: If upgrading from a schema that has NO backpressuredComponents column at all,
--       replace `backpressuredComponents` in the INSERT with CAST(NULL AS STRING) AS backpressuredComponents.

-- Step 1: Back up existing data
CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_appdetail_v2_backup`
PARTITION BY DATE(batchdate)
OPTIONS (DESCRIPTION="Pre-migration backup of striim_mon_appdetail before backpressuredComponents moved to last column")
AS SELECT * FROM `striim_watcher_metadata.striim_mon_appdetail`;

-- Step 2: Recreate table with correct column order (backpressuredComponents last)
CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_appdetail` (
    monid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."),
    command STRING OPTIONS (DESCRIPTION="The equivalent console command to gather the necessary data provided here."),
    appName STRING OPTIONS (DESCRIPTION="The app name."),
    appStatus STRING OPTIONS (DESCRIPTION="Indicates the app status."),
    totalInput INT64 OPTIONS (DESCRIPTION="Lists the total input count from the app (what is displayed in the UI)."),
    totalOutput INT64 OPTIONS (DESCRIPTION="Lists the total output count from the app (what is displayed in the UI)."),
    isBackpressured BOOL OPTIONS (DESCRIPTION="Boolean: indicates if the app is backpressured."),
    isRecoveryEnabled BOOL OPTIONS (DESCRIPTION="Boolean: indicates if recovery is enabled."),
    recoverySetting STRING OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. If Recovery is enabled, the recovery setting (such as 1 MINUTE INTERVAL) will be listed."),
    checkpointStatus STRING OPTIONS (DESCRIPTION="Indicates if the checkpoint is progressing, lagging, etc."),
    checkpointDetail STRING OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. Displays the checkpoint detailed information as a nested JSONArray (Converted to String)."),
    isEncryptionEnabled BOOL OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. Boolean: indicates if encryption is enabled."),
    deploymentOn STRING OPTIONS (DESCRIPTION="Requires Include App Status Detail to be detected. Displays the server(s) the app is deployed in."),
    deploymentIn STRING OPTIONS (DESCRIPTION="Requires Include App Status Detail to be detected. Displays the deployment group the app is deployed in."),
    appCreatedDate TIMESTAMP OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. The datetime the app was created within Striim."),
    latestActivity TIMESTAMP OPTIONS (DESCRIPTION="The datetime of the latest activity the app has seen."),
    backpressuredComponents STRING OPTIONS (DESCRIPTION="Comma-separated list of backpressured stream or component names when the app is backpressured. Null if no backpressure detected."),
    PRIMARY KEY (monid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (DESCRIPTION="Detailed application monitoring including backpressure, recovery, and checkpoint status");

-- Step 3: Restore data — backpressuredComponents preserved from backup (was at old position 9)
INSERT INTO `striim_watcher_metadata.striim_mon_appdetail`
SELECT
    monid, batchdate, command, appName, appStatus,
    totalInput, totalOutput, isBackpressured,
    isRecoveryEnabled, recoverySetting,
    checkpointStatus, checkpointDetail,
    isEncryptionEnabled, deploymentOn, deploymentIn,
    appCreatedDate, latestActivity,
    backpressuredComponents
FROM `striim_watcher_metadata.striim_mon_appdetail_v2_backup`;

-- Step 4: Verify row counts match before dropping backup
SELECT 'new' AS tbl, COUNT(*) AS cnt FROM `striim_watcher_metadata.striim_mon_appdetail`
UNION ALL
SELECT 'backup', COUNT(*) FROM `striim_watcher_metadata.striim_mon_appdetail_v2_backup`;

-- Step 5: Drop backup once verified (uncomment when ready)
-- DROP TABLE `striim_watcher_metadata.striim_mon_appdetail_v2_backup`;
