CREATE TABLE mon.striim_mon_table_column_detail (
    montblcoldtlid BIGINT PRIMARY KEY,
    batchdate TIMESTAMP,
    typeName TEXT,
    appName TEXT,
    tableName TEXT,
    createdDate TIMESTAMP,
    columnName TEXT,
    columnType TEXT,
    isPK BOOLEAN
);

