

INSERT INTO mon.TableAlertThresholds (
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

(
    'txn-001',
    'TransactionProcessor',
    'transactions',
    'source_transactions',
    'target_transactions',
    5,
    TRUE,
    7,
    TRUE,
    10,
    1000,
    TRUE,
    TRUE
),

(
    'cust-001',
    'CustomerSync',
    'customers',
    'source_customers',
    'target_customers',
    15,
    TRUE,
    10,
    TRUE,
    20,
    500,
    TRUE,
    TRUE
),

(
    'ref-001',
    'ReferenceDataSync',
    'product_catalog',
    'source_products',
    'target_products',
    60,
    TRUE,
    15,
    TRUE,
    30,
    100,
    FALSE,
    TRUE
),

(
    'log-001',
    'LogProcessor',
    'application_logs',
    'source_logs',
    'target_logs',
    NULL,
    FALSE,
    20,
    TRUE,
    15,
    NULL,
    FALSE,
    TRUE
),

(
    'fin-001',
    'FinancialDataProcessor',
    'financial_transactions',
    'source_financial_txn',
    'target_financial_txn',
    2,
    TRUE,
    3,
    TRUE,
    5,
    2000,
    TRUE,
    TRUE
);

SELECT 
    id,
    appName,
    tableName,
    CASE 
        WHEN dataFreshnessCheckEnabled THEN CONCAT(dataFreshnessThresholdMinutes::TEXT, ' min')
        ELSE 'Disabled'
    END as DataFreshnessMonitoring,
    CASE 
        WHEN queuedBatchesCheckEnabled THEN CONCAT(queuedBatchesThreshold::TEXT, ' batches (', queuedBatchesConsistentMinutes::TEXT, ' min)')
        ELSE 'Disabled'
    END as QueuedBatchesMonitoring,
    CASE 
        WHEN pkUpdatesCheckEnabled THEN CONCAT(pkUpdatesThreshold::TEXT, ' updates')
        ELSE 'Disabled'
    END as PKUpdatesMonitoring,
    isEnabled
FROM mon.TableAlertThresholds
ORDER BY appName, tableName;

