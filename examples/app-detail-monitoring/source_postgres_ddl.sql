-- app-detail-monitoring — companion (monitored) pipeline SOURCE table.
-- The demo ${APP}_monitored app initial-loads this table into a same-named target table so the
-- watcher has a real application (with a source + target component) to report on.

DROP TABLE IF EXISTS ${PG_SOURCE_SCHEMA}.${TID}sw_orders CASCADE;
CREATE TABLE ${PG_SOURCE_SCHEMA}.${TID}sw_orders (
    id INTEGER PRIMARY KEY,
    val TEXT
);
