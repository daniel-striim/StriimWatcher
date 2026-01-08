-- Table: TableAlertThresholds
-- Purpose: Configuration table for table-level alert thresholds and monitoring settings
-- Dependencies: None (configuration table)
-- Description: Defines table-specific alert thresholds for data freshness, queued batches, and other table-level metrics

CREATE OR REPLACE TABLE `striim_watcher_metadata.TableAlertThresholds` (
    id STRING OPTIONS (
        DESCRIPTION="A unique identifier for the table alert threshold configuration."
    ),
    appName STRING OPTIONS (
        DESCRIPTION="The Striim application name that contains this table."
    ),
    tableName STRING OPTIONS (
        DESCRIPTION="The specific table name this configuration applies to."
    ),
    sourceTableName STRING OPTIONS (
        DESCRIPTION="The source table name (for comparison monitoring)."
    ),
    targetTableName STRING OPTIONS (
        DESCRIPTION="The target table name (for comparison monitoring)."
    ),
    
    -- Data Freshness Monitoring (#5)
    dataFreshnessThresholdMinutes INT64 OPTIONS (
        DESCRIPTION="Threshold in minutes for data freshness alerts. Tables with no data flow for this duration will trigger alerts."
    ),
    dataFreshnessCheckEnabled BOOL OPTIONS (
        DESCRIPTION="Boolean indicating if data freshness monitoring is enabled for this table."
    ),
    
    -- Queued Batches Monitoring (#6)
    queuedBatchesThreshold INT64 OPTIONS (
        DESCRIPTION="Threshold for queued batches. If queued batches exceed this number consistently, an alert will be triggered."
    ),
    queuedBatchesCheckEnabled BOOL OPTIONS (
        DESCRIPTION="Boolean indicating if queued batches monitoring is enabled for this table."
    ),
    queuedBatchesConsistentMinutes INT64 OPTIONS (
        DESCRIPTION="Duration in minutes that queued batches must exceed threshold before triggering alert."
    ),
    
    -- PK Updates Monitoring (related to #6)
    pkUpdatesThreshold INT64 OPTIONS (
        DESCRIPTION="Threshold for primary key updates on target. High PK updates may indicate performance issues."
    ),
    pkUpdatesCheckEnabled BOOL OPTIONS (
        DESCRIPTION="Boolean indicating if primary key updates monitoring is enabled for this table."
    ),
    
    -- General Configuration
    isEnabled BOOL DEFAULT TRUE OPTIONS (
        DESCRIPTION="Boolean indicating if table-level alerts are enabled for this table configuration."
    ),
    createdDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP() OPTIONS (
        DESCRIPTION="Timestamp when this configuration was created."
    ),
    lastModifiedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP() OPTIONS (
        DESCRIPTION="Timestamp when this configuration was last modified."
    ),
    
    PRIMARY KEY (id) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Configuration table for table-level alert thresholds including data freshness, queued batches, and PK update monitoring"
);
