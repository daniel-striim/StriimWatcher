-- Script: Upgrade striim_mon_appdetail to add backpressuredComponents column
-- Purpose: StriimWatcher uses positional column mapping; ALTER TABLE ADD COLUMN appends
--          to the end and will misalign columns from position 8 onward. This script
--          backs up existing data, recreates the table with the correct column order,
--          then restores the data with NULL for the new column.
-- Usage: Run steps in order. Verify row counts match before dropping the backup.

-- Step 1: Back up existing data
CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_appdetail_v1_backup`
PARTITION BY DATE(batchdate)
OPTIONS (DESCRIPTION="Pre-upgrade backup of striim_mon_appdetail before backpressuredComponents column was added")
AS SELECT * FROM `striim_watcher_metadata.striim_mon_appdetail`;

-- Step 2: Recreate table with correct column order (backpressuredComponents at position 8)
CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_appdetail` (
    monid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."),
    command STRING OPTIONS (DESCRIPTION="The equivalent console command to gather the necessary data provided here."),
    appName STRING OPTIONS (DESCRIPTION="The app name."),
    appStatus STRING OPTIONS (DESCRIPTION="Indicates the app status."),
    totalInput INT64 OPTIONS (DESCRIPTION="Lists the total input count from the app (what is displayed in the UI)."),
    totalOutput INT64 OPTIONS (DESCRIPTION="Lists the total output count from the app (what is displayed in the UI)."),
    isBackpressured BOOL OPTIONS (DESCRIPTION="Boolean: indicates if the app is backpressured."),
    backpressuredComponents STRING OPTIONS (DESCRIPTION="Comma-separated list of backpressured stream or component names when the app is backpressured. Null if no backpressure detected."),
    isRecoveryEnabled BOOL OPTIONS (DESCRIPTION="Boolean: indicates if recovery is enabled."),
    recoverySetting STRING OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. If Recovery is enabled, the recovery setting (such as 1 MINUTE INTERVAL) will be listed."),
    checkpointStatus STRING OPTIONS (DESCRIPTION="Indicates if the checkpoint is progressing, lagging, etc."),
    checkpointDetail STRING OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. Displays the checkpoint detailed information as a nested JSONArray (Converted to String)."),
    isEncryptionEnabled BOOL OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. Boolean: indicates if encryption is enabled."),
    deploymentOn STRING OPTIONS (DESCRIPTION="Requires Include App Status Detail to be detected. Displays the server(s) the app is deployed in."),
    deploymentIn STRING OPTIONS (DESCRIPTION="Requires Include App Status Detail to be detected. Displays the deployment group the app is deployed in."),
    appCreatedDate TIMESTAMP OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. The datetime the app was created within Striim."),
    latestActivity TIMESTAMP OPTIONS (DESCRIPTION="The datetime of the latest activity the app has seen."),
    PRIMARY KEY (monid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (DESCRIPTION="Detailed application monitoring including backpressure, recovery, and checkpoint status");

-- Step 3: Restore data — backpressuredComponents defaults to NULL for historical rows
INSERT INTO `striim_watcher_metadata.striim_mon_appdetail`
SELECT
    monid, batchdate, command, appName, appStatus,
    totalInput, totalOutput, isBackpressured,
    CAST(NULL AS STRING) AS backpressuredComponents,
    isRecoveryEnabled, recoverySetting,
    checkpointStatus, checkpointDetail,
    isEncryptionEnabled, deploymentOn, deploymentIn,
    appCreatedDate, latestActivity
FROM `striim_watcher_metadata.striim_mon_appdetail_v1_backup`;

-- Step 4: Verify row counts match before dropping backup
SELECT 'new' AS tbl, COUNT(*) AS cnt FROM `striim_watcher_metadata.striim_mon_appdetail`
UNION ALL
SELECT 'backup', COUNT(*) FROM `striim_watcher_metadata.striim_mon_appdetail_v1_backup`;

-- Step 5: Drop backup once verified (uncomment when ready)
-- DROP TABLE `striim_watcher_metadata.striim_mon_appdetail_v1_backup`;
