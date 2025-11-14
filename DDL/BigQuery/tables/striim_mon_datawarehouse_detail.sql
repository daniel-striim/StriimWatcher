-- Table: striim_mon_datawarehouse_detail
-- Purpose: Tracks detailed data warehouse target metrics and batch processing statistics
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Comprehensive metrics for data warehouse targets including batch processing, merge operations, and performance

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_datawarehouse_detail` (
    dwdid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    
    -- Application and Target Information
    appName STRING OPTIONS (
        DESCRIPTION="The app which has this source/target."
    ),
    sourceName STRING OPTIONS (
        DESCRIPTION="Source table name"
    ),
    targetName STRING OPTIONS (
        DESCRIPTION="Target table name"
    ),
    target_adaptername STRING OPTIONS (
        DESCRIPTION="Target adapter name, like BQ"
    ),
    
    -- Configuration Settings
    projectId STRING OPTIONS (
        DESCRIPTION="ProjectID"
    ),
    Mode STRING OPTIONS (
        DESCRIPTION="Target Mode type (APPENDONLY or MERGE)"
    ),
    streamingUpload BOOL OPTIONS (
        DESCRIPTION="Boolean: indicates if the app property has streamingUpload enabled."
    ),
    StreamingConfiguration STRING OPTIONS (
        DESCRIPTION="Target StreamingConfiguration"
    ),
    optimizedMerge BOOL OPTIONS (
        DESCRIPTION="Boolean: indicates if the app property has optimizedMerge enabled."
    ),
    
    -- Batch Configuration
    batch_event_count INT OPTIONS (
        DESCRIPTION="Configured batch event count"
    ),
    batch_interval INT OPTIONS (
        DESCRIPTION="Configured batch interval"
    ),
    
    -- Overall Statistics
    total_batches_created INT OPTIONS (
        DESCRIPTION="Total number of batches created"
    ),
    partition_pruned_batches INT OPTIONS (
        DESCRIPTION="Number of batches that were partition pruned"
    ),
    last_successful_merge_time TIMESTAMP OPTIONS (
        DESCRIPTION="Timestamp of last successful merge operation"
    ),
    total_batches_ignored INT OPTIONS (
        DESCRIPTION="Total number of batches ignored"
    ),
    max_integration_time_ms INT OPTIONS (
        DESCRIPTION="Maximum integration time in milliseconds"
    ),
    avg_in_mem_compaction_time_ms NUMERIC OPTIONS (
        DESCRIPTION="Average in-memory compaction time in milliseconds"
    ),
    avg_batch_size_bytes INT64 OPTIONS (
        DESCRIPTION="Average batch size in bytes"
    ),
    avg_event_count_per_batch NUMERIC OPTIONS (
        DESCRIPTION="Average number of events per batch"
    ),
    min_integration_time_ms INT OPTIONS (
        DESCRIPTION="Minimum integration time in milliseconds"
    ),
    total_batches_queued INT OPTIONS (
        DESCRIPTION="Total number of batches queued"
    ),
    avg_compaction_time_ms NUMERIC OPTIONS (
        DESCRIPTION="Average compaction time in milliseconds"
    ),
    avg_waiting_time_in_queue_ms NUMERIC OPTIONS (
        DESCRIPTION="Average waiting time in queue in milliseconds"
    ),
    avg_integration_time_ms NUMERIC OPTIONS (
        DESCRIPTION="Average integration time in milliseconds"
    ),
    total_batches_uploaded INT OPTIONS (
        DESCRIPTION="Total number of batches uploaded"
    ),
    avg_merge_time_ms NUMERIC OPTIONS (
        DESCRIPTION="Average merge time in milliseconds"
    ),
    avg_stage_resources_mgmt_time_ms NUMERIC OPTIONS (
        DESCRIPTION="Average stage resources management time in milliseconds"
    ),
    avg_upload_time_ms NUMERIC OPTIONS (
        DESCRIPTION="Average upload time in milliseconds"
    ),

    -- Last Batch Information
    last_batch_updates INT OPTIONS (
        DESCRIPTION="Number of updates in last batch"
    ),
    last_batch_event_count INT OPTIONS (
        DESCRIPTION="Number of events in last batch"
    ),
    last_batch_inserts INT OPTIONS (
        DESCRIPTION="Number of inserts in last batch"
    ),
    last_batch_max_record_size_bytes INT64 OPTIONS (
        DESCRIPTION="Maximum record size in bytes for last batch"
    ),
    last_batch_total_events_merged INT OPTIONS (
        DESCRIPTION="Total events merged in last batch"
    ),
    last_batch_ddls INT OPTIONS (
        DESCRIPTION="Number of DDLs in last batch"
    ),
    last_batch_sequence_number INT OPTIONS (
        DESCRIPTION="Sequence number of last batch"
    ),
    last_batch_size_bytes INT64 OPTIONS (
        DESCRIPTION="Size in bytes of last batch"
    ),
    last_batch_deletes INT OPTIONS (
        DESCRIPTION="Number of deletes in last batch"
    ),
    last_batch_pk_updates INT OPTIONS (
        DESCRIPTION="Number of primary key updates in last batch"
    ),
    last_batch_accumulation_time_ms INT OPTIONS (
        DESCRIPTION="Accumulation time in milliseconds for last batch"
    ),

    -- Last Batch Integration Task Times
    last_batch_compaction_time_ms INT OPTIONS (
        DESCRIPTION="Compaction time in milliseconds for last batch"
    ),
    last_batch_stage_resources_mgmt_time_ms INT OPTIONS (
        DESCRIPTION="Stage resources management time in milliseconds for last batch"
    ),
    last_batch_upload_time_ms INT OPTIONS (
        DESCRIPTION="Upload time in milliseconds for last batch"
    ),
    last_batch_merge_time_ms INT OPTIONS (
        DESCRIPTION="Merge time in milliseconds for last batch"
    ),
    last_batch_in_mem_compaction_time_ms INT OPTIONS (
        DESCRIPTION="In-memory compaction time in milliseconds for last batch"
    ),
    last_batch_pk_update_time_ms INT OPTIONS (
        DESCRIPTION="Primary key update time in milliseconds for last batch"
    ),
    last_batch_ddl_execution_time_ms INT OPTIONS (
        DESCRIPTION="DDL execution time in milliseconds for last batch"
    ),
    last_batch_total_integration_time_ms INT OPTIONS (
        DESCRIPTION="Total integration time in milliseconds for last batch"
    ),

    -- Target Component Information
    targetComponentName STRING OPTIONS (
        DESCRIPTION="Target component name from monitoring command (e.g., admin.BigQuerySWTarget)"
    ),

    PRIMARY KEY (dwdid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Tracks detailed data warehouse target metrics and batch processing statistics"
);
