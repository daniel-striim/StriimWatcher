-- table-comparison-sli — companion (monitored) pipeline SOURCE table.
-- The demo ${APP}_monitored app initial-loads this table into a same-named target so the watcher
-- observes a real source→target pair with non-zero comparison counts.

DROP TABLE IF EXISTS ${PG_SOURCE_SCHEMA}.${TID}sw_orders CASCADE;
CREATE TABLE ${PG_SOURCE_SCHEMA}.${TID}sw_orders (
    id INTEGER PRIMARY KEY,
    val TEXT
);
