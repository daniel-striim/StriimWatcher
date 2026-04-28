# StriimWatcher

StriimWatcher is a custom Striim Source adapter that collects monitoring metadata and operational metrics from a running Striim platform and emits them as WAEvents to a downstream DatabaseWriter target. It runs on a configurable interval, querying the Striim API and Metadata Repository directly, and writes to a set of structured monitoring tables (e.g. `mon.striim_mon_appdetail`, `mon.striim_mon_lee`, `mon.striim_mon_table_runhistory`).

It is designed to feed a monitoring data warehouse (BigQuery, PostgreSQL, Snowflake, Databricks, MS-SQL, or Oracle) for dashboarding, alerting, and operational intelligence.

---

## Available Versions

| JAR | Striim Version | Notes |
|---|---|---|
| `StriimWatcher-5-4.jar` | **5.4.x** (latest) | Direct in-process API — no HTTP calls to Tungsten. Classloader-safe refactor, atomic ID generation, byte-offset log tracking. |
| `Striim5.2_JAR/StriimWatcher-5.2.5.jar` | 5.2.x | Source/Target information tables, checkpoint history, Oracle open transaction table, file lineage, system configuration tracking, log watcher (debug + command logs), autoheal monitoring apps. See [5.2.5 release notes](5.2.5-release-notes.md). |
| `Striim5.0_JAR/StriimWatcher-5.0.5.jar` | 5.0.x | Initial release. Core app monitoring, LEE, table comparison, and log watcher. |

> Always use the JAR that matches your Striim platform major.minor version.

---

## Installation

### Load

In the Striim console, upload the JAR and load it:

```sql
LOAD OPEN PROCESSOR 'UploadedFiles/StriimWatcher-5-4.jar';
```

### Unload

```sql
UNLOAD OPEN PROCESSOR 'UploadedFiles/StriimWatcher-5-4.jar';
```

### Debug Logging

Enable at runtime without restarting:

```sql
set loglevel = {com.striim.util.StriimWatcher: debug};
```

Disable:

```sql
set loglevel = {com.striim.util.StriimWatcher: info};
```

Debug output goes to `logs/striim.server.clidebug.log`.

---

## DDL

Target database schemas are in the `DDL/` directory. Deploy the tables for your database before starting a StriimWatcher application.

| Target | Location |
|---|---|
| BigQuery | `DDL/BigQuery/` |
| PostgreSQL | `DDL/PostgreSQL/` |

Each target directory contains:
- `tables/` — core monitoring tables
- `tables/upgrade/` — ALTER scripts for upgrading from prior versions
- `tables/Supplemental/` — alert threshold tables and sample data
- `views/` — convenience views
- `functions/` — alert and analytics functions

---

## Other Processors

The `Other/` directory contains additional Striim custom processors:

| Processor | File | Notes |
|---|---|---|
| AdvFormat | `AdvFormat-5.0.2.jar` | Advanced string formatting UDF |
| AdvRouter | `AdvRouter-5.0.2.jar` | Content-based routing processor |
| EventChanger | `EventChanger/` | Modify event field values at runtime. See [EventChanger README](Other/EventChanger/README.md). |
