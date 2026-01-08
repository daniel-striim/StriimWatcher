

INSERT INTO mon.ApplicationAlertThresholds (
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

(
    'app-txn-001',
    'TransactionProcessor',
    TRUE,
    TRUE,
    10,
    15,
    20,
    5,

    TRUE
),

(
    'app-cust-001',
    'CustomerSync',
    TRUE,
    TRUE,
    15,
    30,
    45,
    10,
    TRUE
),

(
    'app-batch-001',
    'BatchProcessor',
    FALSE,
    TRUE,
    30,
    60,
    90,
    15,
    TRUE
),

(
    'app-ref-001',
    'ReferenceDataSync',
    FALSE,
    TRUE,
    60,
    120,
    180,
    30,
    TRUE
);
