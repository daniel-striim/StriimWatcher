-- Sample Data: ApplicationAlertThresholds
-- Purpose: Insert sample configurations for application-level monitoring including StriimWatcher silence monitoring
-- Usage: Customize these values for your environment before running

-- Insert sample configurations for different application monitoring scenarios
INSERT INTO `striim_watcher_metadata.ApplicationAlertThresholds` (
    id,
    appName,
    isCdcApp,
    terminatedCheckEnabled,
    terminatedThresholdMinutes,
    backpressureThresholdMinutes,
    checkpointNotProgressingThresholdMin,
    avgLeeThresholdMinutes,
    isEnabled
) VALUES

-- =============================================================================
-- APPLICATION MONITORING CONFIGURATIONS
-- =============================================================================

-- High-volume transaction processing app - strict monitoring
(
    'app-txn-001',
    'TransactionProcessor',
    TRUE,                   -- CDC application
    TRUE,                   -- Enable terminated monitoring
    10,                     -- 10 minutes terminated threshold
    15,                     -- 15 minutes backpressure threshold
    20,                     -- 20 minutes checkpoint threshold
    5,                      -- 5 minutes LEE threshold

    TRUE                    -- Configuration enabled
),

-- Customer data sync app - moderate monitoring
(
    'app-cust-001',
    'CustomerSync',
    TRUE,                   -- CDC application
    TRUE,                   -- Enable terminated monitoring
    15,                     -- 15 minutes terminated threshold
    30,                     -- 30 minutes backpressure threshold
    45,                     -- 45 minutes checkpoint threshold
    10,                     -- 10 minutes LEE threshold
    TRUE                    -- Configuration enabled
),

-- Batch processing app - relaxed monitoring
(
    'app-batch-001',
    'BatchProcessor',
    FALSE,                  -- Not a CDC app
    TRUE,                   -- Enable terminated monitoring
    30,                     -- 30 minutes terminated threshold
    60,                     -- 60 minutes backpressure threshold
    90,                     -- 90 minutes checkpoint threshold
    15,                     -- 15 minutes LEE threshold
    TRUE                    -- Configuration enabled
),

-- Reference data app - very relaxed monitoring
(
    'app-ref-001',
    'ReferenceDataSync',
    FALSE,                  -- Not a CDC app
    TRUE,                   -- Enable terminated monitoring
    60,                     -- 60 minutes terminated threshold
    120,                    -- 120 minutes backpressure threshold
    180,                    -- 180 minutes checkpoint threshold
    30,                     -- 30 minutes LEE threshold
    TRUE                    -- Configuration enabled
);

-- Query to verify the inserted data
SELECT 
    id,
    appName,
    CASE 
        WHEN appName LIKE 'STRIIMWATCHER-%' THEN 'System Monitoring'
        WHEN isCdcApp THEN 'CDC Application'
        ELSE 'Batch Application'
    END as ApplicationType,
    CASE 
        WHEN terminatedCheckEnabled THEN CONCAT(CAST(terminatedThresholdMinutes AS STRING), ' min')
        ELSE 'Disabled'
    END as TerminatedMonitoring,
    CASE 
        WHEN backpressureThresholdMinutes IS NOT NULL THEN CONCAT(CAST(backpressureThresholdMinutes AS STRING), ' min')
        ELSE 'Disabled'
    END as BackpressureMonitoring,
    CASE 
        WHEN striimWatcherSilenceThresholdMinutes IS NOT NULL THEN CONCAT(CAST(striimWatcherSilenceThresholdMinutes AS STRING), ' min')
        ELSE 'N/A'
    END as StriimWatcherSilenceMonitoring,
    isEnabled
FROM `striim_watcher_metadata.ApplicationAlertThresholds`
ORDER BY 
    CASE WHEN appName LIKE 'STRIIMWATCHER-%' THEN 0 ELSE 1 END,  -- System monitoring first
    CASE WHEN appName = 'STRIIMWATCHER-GLOBAL' THEN 0 ELSE 1 END,  -- Global config first
    appName;
