

CREATE TABLE mon.striim_mon_lee (
    monleeid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    sourceApp TEXT,
    sourceName TEXT,
    sourceType TEXT,
    targetApp TEXT,
    targetName TEXT,
    targetType TEXT,
    lagEndToEnd NUMERIC,
    measuredAt TIMESTAMP,
    sourceTime TEXT,
    minLEE NUMERIC,
    maxLEE NUMERIC,
    avgLEE NUMERIC,
    sampleSize INTEGER
);

