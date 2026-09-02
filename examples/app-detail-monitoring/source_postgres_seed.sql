-- app-detail-monitoring — seed rows for the companion monitored pipeline.
-- Seeded PRE-deploy: the DatabaseReader initial-loads these at start, giving ${APP}_monitored
-- real source-read / target-write activity for the watcher to report.

INSERT INTO ${PG_SOURCE_SCHEMA}.${TID}sw_orders (id, val) VALUES
  (1, 'alpha'),
  (2, 'bravo'),
  (3, 'charlie'),
  (4, 'delta'),
  (5, 'echo');
