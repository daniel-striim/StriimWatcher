# app-detail-monitoring

Per-application detail (`mon <app>;`) for a **named** application, using the V3 **`AppNameFilter`**
to bound the expensive per-app fan-out.

## What it does

Ships as a pair:

1. **`${APP}_monitored`** — a demo Postgres→Postgres initial-load pipeline (`DatabaseReader` over a
   pre-seeded `${TID}sw_orders` → `DatabaseWriter` into a same-named target table). It gives the
   watcher a real application — with a source and a target component — to report on. Replace it with
   your own application(s) in production.
2. **`${APP}_watcher`** — `StriimWatcherV4D` with `IncludeAppDetail`/`IncludeAppDescribeDetail`/
   `IncludeAppStatusDetail` on and **`AppNameFilter: '${APP_BARE}_monitored'`**, so only the
   companion app gets the deep `mon <app>;` treatment.

Each cycle it emits:

| Emitted type | Target table | Rows per cycle |
|---|---|---|
| `mon.striim_mon_appdetail` | `striim_mon_appdetail` | one per app matching `AppNameFilter` (here: exactly the monitored app) |
| `mon.striim_mon_table_runhistory` | `striim_mon_table_runhistory` | exactly one, emitted last |

## Why AppNameFilter

Without a filter, StriimWatcher runs `mon <app>;` (and per-component describe/monitor, source/target
maps, TQL tracking, `%app-…%` command expansion) for **every** application on the node — the dominant
CPU/memory cost of a pass, and non-deterministic on a shared cluster. `AppNameFilter` is a
comma-separated list of names or Java regexes matched case-insensitively against both the fully
qualified name and the bare name; only matches get the deep treatment. **Empty = monitor everything**
(the production default).

## Files

- `app.tql` — the pipeline pair, in tokenized (placeholder) form.
- `source_postgres_ddl.sql` / `source_postgres_seed.sql` — the companion pipeline's source table + seed.
- `target_postgres_ddl.sql` — the companion's target table + the two `striim_mon_*` output tables.

## Run

Build + upload the jar, create + seed the source table, create the target tables, deploy both apps
(monitored first), then:

```sql
SELECT appname, appstatus, totalinput, totaloutput, isrecoveryenabled
FROM striim_mon_appdetail;          -- one row: the monitored app
SELECT count(*) FROM striim_mon_table_runhistory;   -- ≥1
```

## Notes

- `checkpointdetail` is `null` on the direct-MDR describe path (see the module README *Notes*).
- `RepeatInSeconds: '30'` is a demo value — the module minimum recommendation is **120 s**.
