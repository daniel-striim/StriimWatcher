# table-comparison-sli

Cumulative source-vs-target event counts **and** the since-last-interval (SLI) delta, scoped to a
companion application.

## What it does

Ships as a pair (same companion shape as `app-detail-monitoring`):

1. **`${APP}_monitored`** — a Postgres→Postgres initial load (pre-seeded `${TID}sw_orders` source →
   same-named target) giving the watcher a real source→target pair with non-zero counts.
2. **`${APP}_watcher`** — `StriimWatcherV4D` with `IncludeTableComparisonDetail` and
   `IncludeTableComparisonDetail_SinceLastInterval` on (and `IncludeAppDetail` on, since the
   comparison maps are built from the per-app `mon` data), scoped with
   `AppNameFilter: '${APP_BARE}_monitored'`.

Each cycle it emits:

| Emitted type | Target table | When |
|---|---|---|
| `mon.striim_mon_table_comparison` | `striim_mon_table_comparison` | every cycle — cumulative src/tgt counts per pair |
| `mon.striim_mon_table_comparison_sli` | `striim_mon_table_comparison_sli` | **2nd cycle onward** — delta vs the previous cycle |
| `mon.striim_mon_table_runhistory` | `striim_mon_table_runhistory` | every cycle, emitted last |

## The SLI two-cycle requirement

The `_sli` rows are the delta between the current and the *previous* cycle, so they only appear from
the **second** polling cycle onward — the first cycle has no prior interval to diff against (this is
by design; see the module README *Troubleshooting*). `RepeatInSeconds: '20'` keeps two cycles close
together; the live test's `timeout` is set generously so both fire.

## Files

- `app.tql` — the pipeline pair, in tokenized (placeholder) form.
- `source_postgres_ddl.sql` / `source_postgres_seed.sql` — the companion source table + seed.
- `target_postgres_ddl.sql` — the companion target table + the three `striim_mon_*` output tables.

## Run

Build + upload the jar, create + seed the source table, create the target tables, deploy both apps
(monitored first), wait for ≥2 watcher cycles, then:

```sql
SELECT appname, sourcename, targetname, srcnumofinserts, tgtnumofinserts
FROM striim_mon_table_comparison;                 -- cumulative counts for the monitored app
SELECT appname, timesincelastbatch, srcnumofinserts_sli
FROM striim_mon_table_comparison_sli;             -- delta rows (2nd cycle onward)
SELECT count(*) FROM striim_mon_table_runhistory; -- ≥2 after two cycles
```

## Notes

- `RepeatInSeconds: '20'` is a demo value — the module minimum recommendation is **120 s**.
- SLI rows can legitimately be all-zero deltas (an idle interval still emits one row per prior
  matching pair) — the row's *presence* is what certifies the SLI path ran.
