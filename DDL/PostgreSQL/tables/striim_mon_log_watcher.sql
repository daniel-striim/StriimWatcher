CREATE TABLE mon.striim_mon_log_watcher (
    errorid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    log_date TIMESTAMP,
    server TEXT,
    appName TEXT,
    log_level TEXT,
    message TEXT,
    contextbuffertext TEXT
);

