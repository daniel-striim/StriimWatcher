# StriimWatcher — Use-Case Sample Library

Runnable, copy-paste samples for the **StriimWatcherV4D** source Open Processor, one folder per
use case. StriimWatcher is a *self-monitoring source*: it runs inside a Striim deployment, polls the
platform on an interval, and emits monitoring telemetry as `WAEvent`s (typed in the `mon` namespace)
into a downstream pipeline — here, a `DatabaseWriter` into Postgres `striim_mon_*` tables.

Each folder is self-contained: the pipeline **`app.tql`**, a **`README.md`**, and the role-split
Postgres **DDL** (`target_postgres_ddl.sql` for the `mon.*` output tables; `source_postgres_ddl.sql`
+ `source_postgres_seed.sql` for the companion *monitored* pipeline where a case needs live activity
to observe).

Every `app.tql` ships in **parameterised form**: the connection and naming values are
placeholders, not literals. Before running a sample, replace them with your own
namespace / application / operator names and your Postgres connection details, and use the shipped
`*_ddl.sql` / `*_seed.sql` files as the table shapes. These exact files are run against a real
cluster before each release, so they are known-good once the tokens are filled in.

## How to run any sample

1. Upload `StriimWatcherV4D-5.4.jar` to your Striim server's `UploadedFiles/` directory and load it
   once per cluster: `LOAD OPEN PROCESSOR 'UploadedFiles/StriimWatcherV4D-5.4.jar';`. See
   [`README.md`](../README.md) for the full first-time and upgrade steps,
   including unloading a previous version.
2. Create the `mon.*` **target** tables from the sample's `target_postgres_ddl.sql`; for the
   app-detail / table-comparison samples, also create + seed the companion **source** tables from
   `source_postgres_ddl.sql` + `source_postgres_seed.sql`.
3. Edit the `DatabaseWriter` (and companion `DatabaseReader`) connection in the sample's `app.tql`
   for your environment, then deploy + start it in Striim.
4. Verify by querying the `striim_mon_*` tables the sample writes.

> **Parallel-safety / scoping.** The app-detail and table-comparison samples ship a companion
> `${APP}_monitored` pipeline and set `AppNameFilter: '${APP_BARE}_monitored'` so only that app gets
> the deep per-application treatment — this keeps the emitted rows deterministic on a shared cluster
> (StriimWatcher otherwise monitors *every* app on the node). In production, drop `AppNameFilter` to
> monitor everything.

## Catalog

| Sample | What it shows |
|---|---|
| [`node-health-to-postgres`](node-health-to-postgres/) | Minimal node-health telemetry: `mon;` node/cluster/Elasticsearch status + run history → Postgres. No companion app; the starting point. |
| [`app-detail-monitoring`](app-detail-monitoring/) | Per-application detail (`mon <app>;`) scoped to a companion Postgres→Postgres pipeline via **`AppNameFilter`** — the V3 fan-out bound. |
| [`table-comparison-sli`](table-comparison-sli/) | Source-vs-target event-count comparison **and** the since-last-interval (SLI) delta across two polling cycles, scoped to the companion app. |

## "I want to…" → sample

| Goal | Start with |
|---|---|
| Land basic node / cluster / ES health into a monitoring DB | `node-health-to-postgres` |
| Watch one specific application's status + recovery/checkpoint detail | `app-detail-monitoring` |
| Bound the (expensive) per-app monitoring to named apps with `AppNameFilter` | `app-detail-monitoring` |
| Track cumulative source-vs-target counts and per-interval deltas | `table-comparison-sli` |

## Not shipped (intentional)

- **log-and-alerts** (log-watcher / `MonitorProcessNames` / API event harvesting → `mon.striim_mon_log_watcher`)
  is **intentionally not shipped as a runnable example.** Those paths are **on-prem/native only**
  (they read Striim log files and reflect into private server internals) and are not exercisable on
  the StriimCloud / dockerized live cluster. Configure them per the module `README.md` Parameters
  (API Event Harvesting + Runtime groups) on an on-prem deployment.

## Output convention (all samples)

Every emitted event is a `WAEvent` bound to a dynamically-created type in the `mon` namespace
(`mon.striim_mon_<table>`) and carries `batchdate` = the collection-pass start time. A
`mon.striim_mon_table_runhistory` event is always emitted **last** in each cycle. See the module
[`README.md`](../README.md) *Output* section for the full column-by-column breakdown of every table.
