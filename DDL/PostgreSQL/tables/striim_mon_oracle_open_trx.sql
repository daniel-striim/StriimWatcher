-- Copyright © 2024 Striim Inc.
-- Licensed under Striim License Agreement
-- https://www.striim.com/striim-software-license-agreement/
-- Table: striim_mon_oracle_open_trx

CREATE TABLE mon.striim_mon_oracle_open_trx (
    monopentrxid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    appName TEXT,
    componentName TEXT,
    transactionId TEXT,
    numOfOps TEXT,
    sequenceNum TEXT,
    startscn TEXT,
    rbaBlock TEXT,
    threadNum TEXT,
    timestamp TIMESTAMP
);

