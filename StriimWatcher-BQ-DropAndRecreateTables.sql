CREATE OR REPLACE TABLE public.striim_mon_table_runhistory (
    runid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference, datetime of when this was batch was run."),
    runtimeEnd TIMESTAMP OPTIONS (DESCRIPTION="The time when the StriimWatcher app finished all its internal calls."),
    runtimeDurationMS NUMERIC OPTIONS (DESCRIPTION="The length of time, in milliseconds, for how long it took StriimWatcher from start to finish."),
    clusterName STRING OPTIONS (DESCRIPTION="The ‘clustername’ from the startUp.properties file."),
    companyName STRING OPTIONS (DESCRIPTION="The ‘companyname’ from the startUp.properties file."),
    lastrun TIMESTAMP OPTIONS (DESCRIPTION="Either a default start value, or the actual last run of the StriimWatcher app."),
    nextrun TIMESTAMP OPTIONS (DESCRIPTION="The next planned run, based on configured value ‘RepeatInSeconds’."),
    PRIMARY KEY (runid) NOT ENFORCED
);

CREATE OR REPLACE TABLE public.striim_mon_node_applications (
    monappid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),
    command STRING OPTIONS (DESCRIPTION="The equivalent console command to gather the necessary data provided here."),
    montype STRING OPTIONS (DESCRIPTION="What type of monitoring command was run."),
    appname STRING OPTIONS (DESCRIPTION="The Striim namespace.appName of the app on the node."),
    status STRING OPTIONS (DESCRIPTION="The application state (such as: CREATED, DEPLOYED, RUNNING)"),
    rate NUMERIC OPTIONS (DESCRIPTION="The rate provided from the mon command for each app."),
    sourcerate NUMERIC OPTIONS (DESCRIPTION="The source rate provided from the mon command for each app."),
    cpurate NUMERIC OPTIONS (DESCRIPTION="The cpu rate provided from the mon command for each app."),
    numservers INT OPTIONS (DESCRIPTION="List the number of servers this application is running on. Normally, this should indicate 1 or 0."),
    latestActivity TIMESTAMP OPTIONS (DESCRIPTION="The latest activity seen by the application overall."),
    PRIMARY KEY (monappid) NOT ENFORCED
);
CREATE OR REPLACE TABLE public.striim_mon_node_cluster (
    monnodeclusterid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),
    command STRING OPTIONS (DESCRIPTION="The equivalent console command to gather the necessary data provided here."),
    montype STRING OPTIONS (DESCRIPTION="What type of monitoring command was run."),
    nodename STRING OPTIONS (DESCRIPTION="The name of the node."),
    striimversion STRING OPTIONS (DESCRIPTION="The Striim version number of the node."),
    freemem STRING OPTIONS (DESCRIPTION="The amount of free memory on the server."),
    cpurate NUMERIC OPTIONS (DESCRIPTION="The current CPU rate. NOTE: it is usually a 100%/core based; this means that an 8 core system can utilize 800% cpurate."),
    uptime STRING OPTIONS (DESCRIPTION="Indicates how long the Striim Server has been up for."),
    PRIMARY KEY (monnodeclusterid) NOT ENFORCED
);

CREATE OR REPLACE TABLE public.striim_mon_node_elasticsearch (
    monnodesid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),
    command STRING OPTIONS (DESCRIPTION="The equivalent console command to gather the necessary data provided here."),
    montype STRING OPTIONS (DESCRIPTION="What type of monitoring command was run."),
    elasticsearchReceiveThroughput INT64 OPTIONS (DESCRIPTION="Receive throughput of Elasticsearch"),
    elasticsearchTransmitThroughput INT64 OPTIONS (DESCRIPTION="Transmit throughput of Elasticsearch"),
    elasticsearchClusterStorageFree INT64 OPTIONS (DESCRIPTION="Free storage in Elasticsearch cluster"),
    elasticsearchClusterStorageTotal INT64 OPTIONS (DESCRIPTION="Total storage in Elasticsearch cluster"),
    PRIMARY KEY (monnodesid) NOT ENFORCED
);

CREATE OR REPLACE TABLE public.striim_mon_appdetail (
    monid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),
    command STRING OPTIONS (DESCRIPTION="The equivalent console command to gather the necessary data provided here."),
    appName STRING OPTIONS (DESCRIPTION="The app name."),
    appStatus STRING OPTIONS (DESCRIPTION="Indicates the app status. Will not include CREATED or DEPLOYED app details unless Include Created Application Detail or Include Deployed Application Detail are enabled."),
    totalInput INT64 OPTIONS (DESCRIPTION="Lists the total input count from the app (what is displayed in the UI)."),
    totalOutput INT64 OPTIONS (DESCRIPTION="Lists the total output count from the app (what is displayed in the UI)."),
    isBackpressured BOOL OPTIONS (DESCRIPTION="Boolean: indicates if the app is backpressured."),
    isRecoveryEnabled BOOL OPTIONS (DESCRIPTION="Boolean: indicates if recovery is enabled."),
    recoverySetting STRING OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. If Recovery is enabled, the recovery setting (such as 1 MINUTE INTERVAL) will be listed."),
    checkpointStatus STRING OPTIONS (DESCRIPTION="Indicates if the checkpoint is progressing, lagging, etc."),
    checkpointDetail STRING OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. Displays the checkpoint detailed information as a nested JSONArray (Converted to String)."),
    isEncryptionEnabled BOOL OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. Boolean: indicates if encryption is enabled."),
    deploymentOn STRING OPTIONS (DESCRIPTION="Requires Include App Status Detail to be detected. Displays the server(s) the app is deployed in. (i.e. S192_168_1_30)"),
    deploymentIn STRING OPTIONS (DESCRIPTION="Requires Include App Status Detail to be detected. Displays the deployment group the app is deployed in. (i.e. default)"),
    appCreatedDate TIMESTAMP OPTIONS (DESCRIPTION="Requires Include App Describe Detail to be detected. The datetime the app was created within Striim."),
    latestActivity TIMESTAMP OPTIONS (DESCRIPTION="The datetime of the latest activity the app has seen."),
    PRIMARY KEY (monid) NOT ENFORCED
);

CREATE OR REPLACE TABLE public.striim_mon_table_comparison (
    tblcompareid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),
    appName STRING OPTIONS (DESCRIPTION="The app which has this source/target."),
    sourceName STRING OPTIONS (DESCRIPTION="The table name of the source."),
    targetName STRING OPTIONS (DESCRIPTION="The table name of the target."),
    srcNumOfDeletes INT64 OPTIONS (DESCRIPTION="Number of deletes in source table"),
    tgtNumOfDeletes INT64 OPTIONS (DESCRIPTION="Number of deletes in target table"),
    diffNumOfDeletes INT64 OPTIONS (DESCRIPTION="Difference in number of deletes"),
    srcNumOfDdls INT64 OPTIONS (DESCRIPTION="Number of DDLs in source table"),
    tgtNumOfDdls INT64 OPTIONS (DESCRIPTION="Number of DDLs in target table"),
    diffNumOfDdls INT64 OPTIONS (DESCRIPTION="Difference in number of DDLs"),
    srcNumOfPkupdates INT64 OPTIONS (DESCRIPTION="Number of primary key updates in source table"),
    tgtNumOfPkupdates INT64 OPTIONS (DESCRIPTION="Number of primary key updates in target table"),
    diffNumOfPkupdates INT64 OPTIONS (DESCRIPTION="Difference in number of primary key updates"),
    srcNumOfUpdates INT64 OPTIONS (DESCRIPTION="Number of updates in source table"),
    tgtNumOfUpdates INT64 OPTIONS (DESCRIPTION="Number of updates in target table"),
    diffNumOfUpdates INT64 OPTIONS (DESCRIPTION="Difference in number of updates"),
    srcNumOfInserts INT64 OPTIONS (DESCRIPTION="Number of inserts in source table"),
    tgtNumOfInserts INT64 OPTIONS (DESCRIPTION="Number of inserts in target table"),
    diffNumOfInserts INT64 OPTIONS (DESCRIPTION="Difference in number of inserts"),
    PRIMARY KEY (tblcompareid) NOT ENFORCED
);

CREATE OR REPLACE TABLE public.striim_mon_table_comparison_sli (
    tblcomparehistoryid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),
    timesincelastbatch INT64 OPTIONS (DESCRIPTION="How many seconds have passed since the last run."),
    appName STRING OPTIONS (DESCRIPTION="The app which has this source/target."),
    sourceName STRING OPTIONS (DESCRIPTION="Source table name"),
    targetName STRING OPTIONS (DESCRIPTION="Target table name"),
    srcNumOfDeletes_sli INT64 OPTIONS (DESCRIPTION="Number of deletes in source table since last interval"),
    tgtNumOfDeletes_sli INT64 OPTIONS (DESCRIPTION="Number of deletes in target table since last interval"),
    diffNumOfDeletes_sli INT64 OPTIONS (DESCRIPTION="Difference in number of deletes since last interval"),
    srcNumOfDdls_sli INT64 OPTIONS (DESCRIPTION="Number of DDLs in source table since last interval"),
    tgtNumOfDdls_sli INT64 OPTIONS (DESCRIPTION="Number of DDLs in target table since last interval"),
    diffNumOfDdls_sli INT64 OPTIONS (DESCRIPTION="Difference in number of DDLs since last interval"),
    srcNumOfPkupdates_sli INT64 OPTIONS (DESCRIPTION="Number of primary key updates in source table since last interval"),
    tgtNumOfPkupdates_sli INT64 OPTIONS (DESCRIPTION="Number of primary key updates in target table since last interval"),
    diffNumOfPkupdates_sli INT64 OPTIONS (DESCRIPTION="Difference in number of primary key updates since last interval"),
    srcNumOfUpdates_sli INT64 OPTIONS (DESCRIPTION="Number of updates in source table since last interval"),
    tgtNumOfUpdates_sli INT64 OPTIONS (DESCRIPTION="Number of updates in target table since last interval"),
    diffNumOfUpdates_sli INT64 OPTIONS (DESCRIPTION="Difference in number of updates since last interval"),
    srcNumOfInserts_sli INT64 OPTIONS (DESCRIPTION="Number of inserts in source table since last interval"),
    tgtNumOfInserts_sli INT64 OPTIONS (DESCRIPTION="Number of inserts in target table since last interval"),
    diffNumOfInserts_sli INT64 OPTIONS (DESCRIPTION="Difference in number of inserts since last interval"),
    PRIMARY KEY (tblcomparehistoryid) NOT ENFORCED
);

CREATE OR REPLACE TABLE public.striim_mon_lee (
    monleeid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),
    sourceApp STRING OPTIONS (DESCRIPTION="(If detectable) The App name related to the Type. App name is not provided in the Lee report; however, by using the sourceName, we can attempt to find the App."),
    sourceName STRING OPTIONS (DESCRIPTION="The Source Name as reported by the Lee report."),
    sourceType STRING OPTIONS (DESCRIPTION="The Source Type as reported by the Lee report."),
    targetApp STRING OPTIONS (DESCRIPTION="(If detectable) The App name related to the Type. App name is not provided in the Lee report; however, by using the targetName, we can attempt to find the App."),
    targetName STRING OPTIONS (DESCRIPTION="The Target Name as reported by the Lee report."),
    targetType STRING OPTIONS (DESCRIPTION="The Target Type as reported by the Lee report."),
    lagEndToEnd NUMERIC OPTIONS (DESCRIPTION="The currently measured LAG returned from lee;"),
    measuredAt TIMESTAMP OPTIONS (DESCRIPTION="The time the lag was measured at."),
    sourceTime STRING OPTIONS (DESCRIPTION="The source time returned by report lee;"),
    minLEE NUMERIC OPTIONS (DESCRIPTION="The min lee reported by lee. This represents the fastest end-to-end record creation and delivery, from the samplesize provided."),
    maxLEE NUMERIC OPTIONS (DESCRIPTION="The max lee reported by lee. This represents the slowest end-to-end record creation and delivery, from the samplesize provided."),
    avgLEE NUMERIC OPTIONS (DESCRIPTION="The average lee reported by lee. Based on the sample size, this represents the average time for the end-to-end record creation and delivery, from the samplesize."),
    sampleSize INT OPTIONS (DESCRIPTION="The sample size used to calculate the lee statistics.")
);

CREATE OR REPLACE TABLE public.striim_mon_component_output (
    moncomoutid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),
    appName STRING OPTIONS (DESCRIPTION="The related application name for the json monitor data output."),
    componentName STRING OPTIONS (DESCRIPTION="The name of the component monitored."),
    command STRING OPTIONS (DESCRIPTION="Type type of command (mon or describe)."),
    type STRING OPTIONS (DESCRIPTION="The type of component (APP, SOURCE, STREAM, TARGET, TYPE)."),
    jsondata JSON OPTIONS (DESCRIPTION="The raw JSON output of the API response. This can be useful in instances where we need to track properties of sources or targets, by capturing the DESCRIBE data.")
);

CREATE OR REPLACE TABLE public.striim_mon_table_column_detail (
    montblcoldtlid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),
    typeName STRING OPTIONS (DESCRIPTION="The Striim type name that was produced related to the table."),
    appName STRING OPTIONS (DESCRIPTION="The predicted app name that utilizes this type. It attempts to match by utilizing the app name + table name → type matching logic."),
    tableName STRING OPTIONS (DESCRIPTION="The predicted table name that utilizes this type. It attempts to match by utilizing the app name + table name → type matching logic."),
    createdDate TIMESTAMP OPTIONS (DESCRIPTION="When the type was created. By default, StriimWatcher will only produce output entries on first run, and when a type’s createdDate has changed."),
    columnName STRING OPTIONS (DESCRIPTION="The column name from the table."),
    columnType STRING OPTIONS (DESCRIPTION="The column type from the table."),
    isPK BOOL OPTIONS (DESCRIPTION="Whether this column is a primary key column.")
);

CREATE OR REPLACE TABLE public.striim_mon_datawarehouse_detail (
    dwdid INT64 OPTIONS (DESCRIPTION="A unique bigint value for PK of the row."),
    batchdate TIMESTAMP OPTIONS (DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this was batch was run."),

    appName STRING OPTIONS (DESCRIPTION="The app which has this source/target."),
    sourceName STRING OPTIONS (DESCRIPTION="Source table name"),
    targetName STRING OPTIONS (DESCRIPTION="Target table name"),
    target_adaptername STRING OPTIONS (DESCRIPTION="Target adapter name, like BQ"),

    projectId STRING OPTIONS (DESCRIPTION="ProjectID"),
    Mode STRING OPTIONS (DESCRIPTION="Target Mode type (APPENDONLY or MERGE)"),
    streamingUpload BOOL OPTIONS (DESCRIPTION="Boolean: indicates if the app property has streamingUpload enabled."),
    StreamingConfiguration STRING OPTIONS (DESCRIPTION="Target StreamingConfiguration"),
    optimizedMerge BOOL OPTIONS (DESCRIPTION="Boolean: indicates if the app property has optimizedMerge enabled."),

    batch_event_count INT,
    batch_interval INT,

    total_batches_created INT,
    partition_pruned_batches INT,
    last_successful_merge_time TIMESTAMP,
    total_batches_ignored INT,
    max_integration_time_ms INT,
    avg_in_mem_compaction_time_ms NUMERIC,
    avg_batch_size_bytes INT64,
    avg_event_count_per_batch NUMERIC,
    min_integration_time_ms INT,
    total_batches_queued INT,
    avg_compaction_time_ms NUMERIC,
    avg_waiting_time_in_queue_ms NUMERIC,
    avg_integration_time_ms NUMERIC,
    total_batches_uploaded INT,
    avg_merge_time_ms NUMERIC,
    avg_stage_resources_mgmt_time_ms NUMERIC,
    avg_upload_time_ms NUMERIC,

    -- Fields from "Last batch info"
    last_batch_updates INT,
    last_batch_event_count INT,
    last_batch_inserts INT,
    last_batch_max_record_size_bytes INT64,
    last_batch_total_events_merged INT,
    last_batch_ddls INT,
    last_batch_sequence_number INT,
    last_batch_size_bytes INT64,
    last_batch_deletes INT,
    last_batch_pk_updates INT,
    last_batch_accumulation_time_ms INT,

    -- Fields from "Integration Task Time" (within "Last batch info")
    last_batch_compaction_time_ms INT,
    last_batch_stage_resources_mgmt_time_ms INT,
    last_batch_upload_time_ms INT,
    last_batch_merge_time_ms INT,
    last_batch_in_mem_compaction_time_ms INT,
    last_batch_pk_update_time_ms INT,
    last_batch_ddl_execution_time_ms INT,
    last_batch_total_integration_time_ms INT
);


CREATE OR REPLACE TABLE public.striim_mon_log_watcher (
    errorid INT64,
    batchdate TIMESTAMP,
    log_date TIMESTAMP,
    server STRING,
    appName STRING,
    log_level STRING,
    message STRING,
    contextbuffertext STRING
);
