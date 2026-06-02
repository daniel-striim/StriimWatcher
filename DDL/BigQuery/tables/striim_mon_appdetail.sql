-- Table: striim_mon_appdetail
-- Purpose: Detailed application monitoring including backpressure, recovery, and checkpoint status
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Comprehensive application details including I/O counts, recovery settings, and deployment info

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_appdetail` (
    monid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    command STRING OPTIONS (
        DESCRIPTION="The equivalent console command to gather the necessary data provided here."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The app name."
    ),
    appStatus STRING OPTIONS (
        DESCRIPTION="Indicates the app status. Will not include CREATED or DEPLOYED app details unless Include Created Application Detail or Include Deployed Application Detail are enabled."
    ),
    totalInput INT64 OPTIONS (
        DESCRIPTION="Lists the total input count from the app (what is displayed in the UI)."
    ),
    totalOutput INT64 OPTIONS (
        DESCRIPTION="Lists the total output count from the app (what is displayed in the UI)."
    ),
    isBackpressured BOOL OPTIONS (
        DESCRIPTION="Boolean: indicates if the app is backpressured."
    ),
    isRecoveryEnabled BOOL OPTIONS (
        DESCRIPTION="Boolean: indicates if recovery is enabled."
    ),
    recoverySetting STRING OPTIONS (
        DESCRIPTION="Requires Include App Describe Detail to be detected. If Recovery is enabled, the recovery setting (such as 1 MINUTE INTERVAL) will be listed."
    ),
    checkpointStatus STRING OPTIONS (
        DESCRIPTION="Indicates if the checkpoint is progressing, lagging, etc."
    ),
    checkpointDetail STRING OPTIONS (
        DESCRIPTION="Requires Include App Describe Detail to be detected. Displays the checkpoint detailed information as a nested JSONArray (Converted to String)."
    ),
    isEncryptionEnabled BOOL OPTIONS (
        DESCRIPTION="Requires Include App Describe Detail to be detected. Boolean: indicates if encryption is enabled."
    ),
    deploymentOn STRING OPTIONS (
        DESCRIPTION="Requires Include App Status Detail to be detected. Displays the server(s) the app is deployed in. (i.e. S192_168_1_30)"
    ),
    deploymentIn STRING OPTIONS (
        DESCRIPTION="Requires Include App Status Detail to be detected. Displays the deployment group the app is deployed in. (i.e. default)"
    ),
    appCreatedDate TIMESTAMP OPTIONS (
        DESCRIPTION="Requires Include App Describe Detail to be detected. The datetime the app was created within Striim."
    ),
    latestActivity TIMESTAMP OPTIONS (
        DESCRIPTION="The datetime of the latest activity the app has seen."
    ),
    -- backpressuredComponents STRING OPTIONS (
    --     DESCRIPTION="Comma-separated list of backpressured stream or component names when the app is backpressured. Null if no backpressure detected."
    -- ),
    PRIMARY KEY (monid) NOT ENFORCED
)
PARTITION BY DATE(batchdate)
OPTIONS (
    DESCRIPTION="Detailed application monitoring including backpressure, recovery, and checkpoint status"
);
