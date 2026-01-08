-- Sample Data for TableAlertThresholds
-- Purpose: Example configurations for table-level alert thresholds
-- Usage: Insert these sample configurations to get started with table-level monitoring

-- Insert sample configurations for different table monitoring scenarios
INSERT INTO `striim_watcher_metadata.TableAlertThresholds` (
    id,
    appName,
    tableName,
    sourceTableName,
    targetTableName,
    dataFreshnessThresholdMinutes,
    dataFreshnessCheckEnabled,
    queuedBatchesThreshold,
    queuedBatchesCheckEnabled,
    queuedBatchesConsistentMinutes,
    pkUpdatesThreshold,
    pkUpdatesCheckEnabled,
    isEnabled
) VALUES 
-- High-volume transaction table - strict monitoring
(
    'txn-001',
    'TransactionProcessor',
    'transactions',
    'source_transactions',
    'target_transactions',
    5,      -- 5 minutes data freshness threshold
    TRUE,   -- Enable data freshness monitoring
    7,      -- 7 queued batches threshold
    TRUE,   -- Enable queued batches monitoring
    10,     -- 10 minutes consistent threshold
    1000,   -- 1000 PK updates threshold
    TRUE,   -- Enable PK updates monitoring
    TRUE    -- Configuration enabled
),

-- Customer data table - moderate monitoring
(
    'cust-001',
    'CustomerSync',
    'customers',
    'source_customers',
    'target_customers',
    15,     -- 15 minutes data freshness threshold
    TRUE,   -- Enable data freshness monitoring
    10,     -- 10 queued batches threshold
    TRUE,   -- Enable queued batches monitoring
    20,     -- 20 minutes consistent threshold
    500,    -- 500 PK updates threshold
    TRUE,   -- Enable PK updates monitoring
    TRUE    -- Configuration enabled
),

-- Reference data table - relaxed monitoring
(
    'ref-001',
    'ReferenceDataSync',
    'product_catalog',
    'source_products',
    'target_products',
    60,     -- 60 minutes data freshness threshold (reference data changes less frequently)
    TRUE,   -- Enable data freshness monitoring
    15,     -- 15 queued batches threshold
    TRUE,   -- Enable queued batches monitoring
    30,     -- 30 minutes consistent threshold
    100,    -- 100 PK updates threshold
    FALSE,  -- Disable PK updates monitoring (reference data has fewer updates)
    TRUE    -- Configuration enabled
),

-- Log data table - focus on queued batches only
(
    'log-001',
    'LogProcessor',
    'application_logs',
    'source_logs',
    'target_logs',
    NULL,   -- No data freshness monitoring (logs are continuous)
    FALSE,  -- Disable data freshness monitoring
    20,     -- 20 queued batches threshold (logs can queue more)
    TRUE,   -- Enable queued batches monitoring
    15,     -- 15 minutes consistent threshold
    NULL,   -- No PK updates monitoring (logs typically don't have PK updates)
    FALSE,  -- Disable PK updates monitoring
    TRUE    -- Configuration enabled
),

-- Critical financial data - very strict monitoring
(
    'fin-001',
    'FinancialDataProcessor',
    'financial_transactions',
    'source_financial_txn',
    'target_financial_txn',
    2,      -- 2 minutes data freshness threshold (very strict)
    TRUE,   -- Enable data freshness monitoring
    3,      -- 3 queued batches threshold (very strict)
    TRUE,   -- Enable queued batches monitoring
    5,      -- 5 minutes consistent threshold
    2000,   -- 2000 PK updates threshold
    TRUE,   -- Enable PK updates monitoring
    TRUE    -- Configuration enabled
);

-- Query to verify the inserted data
SELECT 
    id,
    appName,
    tableName,
    CASE 
        WHEN dataFreshnessCheckEnabled THEN CONCAT(CAST(dataFreshnessThresholdMinutes AS STRING), ' min')
        ELSE 'Disabled'
    END as DataFreshnessMonitoring,
    CASE 
        WHEN queuedBatchesCheckEnabled THEN CONCAT(CAST(queuedBatchesThreshold AS STRING), ' batches (', CAST(queuedBatchesConsistentMinutes AS STRING), ' min)')
        ELSE 'Disabled'
    END as QueuedBatchesMonitoring,
    CASE 
        WHEN pkUpdatesCheckEnabled THEN CONCAT(CAST(pkUpdatesThreshold AS STRING), ' updates')
        ELSE 'Disabled'
    END as PKUpdatesMonitoring,
    isEnabled
FROM `striim_watcher_metadata.TableAlertThresholds`
ORDER BY appName, tableName;
