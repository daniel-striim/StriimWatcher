# node-health-to-postgres

The minimal StriimWatcher pipeline: emit **node-level health only** and land it in Postgres.

## What it does

One monitoring application (`${APP}_watcher`) runs `StriimWatcherV4D` with **only** the three node
flags on (`IncludeNodeMonitor`, `IncludeNodeCluster`, `IncludeNodeES`) and everything else off. Each
polling cycle it runs `mon;` and emits:

| Emitted type (`mon` namespace) | Target table | Rows per cycle |
|---|---|---|
| `mon.striim_mon_node_applications` | `striim_mon_node_applications` | one per application on the node (≥1 — always at least this watcher) |
| `mon.striim_mon_node_cluster` | `striim_mon_node_cluster` | one per cluster node |
| `mon.striim_mon_node_elasticsearch` | `striim_mon_node_elasticsearch` | one per Elasticsearch node entry |
| `mon.striim_mon_table_runhistory` | `striim_mon_table_runhistory` | exactly one, always emitted last |

A `DatabaseWriter` maps each `mon.*` type to the matching Postgres table (see
`target_postgres_ddl.sql`).

## Pipeline

- **`${APP}_watcher`** — `StriimWatcherV4D` source → `WatcherStream` → `DatabaseWriter` (Postgres).

No companion pipeline is needed: node health does not depend on any monitored application's
activity, and the cluster always has ≥1 running app (this watcher), so `mon;` always returns rows.

## Files

- `app.tql` — the pipeline, in tokenized (placeholder) form.
- `target_postgres_ddl.sql` — the four `striim_mon_*` output tables this example writes.

## Run

See the library [`../README.md`](../README.md) *How to run any sample*. Build + upload
`StriimWatcherV4D-5.4.jar`, create the target tables, deploy, then:

```sql
SELECT count(*) FROM striim_mon_table_runhistory;   -- ≥1 after the first cycle
SELECT appname, status, rate FROM striim_mon_node_applications;
```

## Notes

- `RepeatInSeconds: '30'` is a demo value — the module minimum recommendation is **120 s**.
- To also capture per-application detail or metrics, start from the `app-detail-monitoring` or
  `table-comparison-sli` samples instead of turning flags on here.
