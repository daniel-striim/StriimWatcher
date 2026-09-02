-- table-comparison-sli — seed rows for the companion monitored pipeline.
-- Seeded PRE-deploy: the DatabaseReader initial-loads these at start, so ${APP}_monitored records
-- a non-zero source-read / target-write count that the watcher's table-comparison section reports.

INSERT INTO ${PG_SOURCE_SCHEMA}.${TID}sw_orders (id, val) VALUES
  (1, 'alpha'),
  (2, 'bravo'),
  (3, 'charlie'),
  (4, 'delta'),
  (5, 'echo'),
  (6, 'foxtrot');
