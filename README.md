# StriimWatcher — Monitor Your Striim Pipelines From Inside Striim

StriimWatcher is a Striim source component that automatically collects monitoring data about your Striim deployment — application health, throughput, latency, log alerts, and more — and delivers it into your pipeline so you can store, visualize, and alert on it without any external scripts or tools.

> **What kind of component is this?** StriimWatcher is a **Field-Developed component** — built and maintained by Striim's Field Engineering / Customer Success Engineering team, not a core, generally-available product feature. Your Striim Field Engineer is the right point of contact for version compatibility, upgrades, and anything that looks like a bug.

---

## What It Does

StriimWatcher runs inside Striim as a data source. On a schedule you control (every 5 minutes by default), it interrogates the Striim server to gather a comprehensive snapshot of your deployment:

- How each application is performing (event rates, CPU, backpressure)
- How many events each source has read and each target has written — and whether they match
- End-to-end latency (how far behind is the target relative to the source)
- System configuration (config files, memory, disk space) and whether it changed
- Errors and warnings from the Striim server log, plus Smart Alerts
- Checkpoint history, open Oracle transactions, Oracle JET (OJet) metrics, data-warehouse batch statistics, file lineage, and more

Everything is emitted as typed Striim records (technically called WAEvents) — one record per metric, all flowing into a single output stream. You connect that stream to any Striim target — PostgreSQL, BigQuery, Snowflake, MySQL — to build a monitoring database you can query and dashboard. Striim Watcher exists so you don't have to write external Python/curl scripts to poll Striim's own monitoring APIs.

In testing, StriimWatcher has been optimized to use minimal resources with default settings. However, the more data categories you enable, the more data is held in memory between polls — monitor its resource usage like you would any other application, and work with your Field Engineer if you're scaling to a very large deployment.

---

## When To Use It

**Use StriimWatcher when you want to:**
- Build a centralized monitoring database for all your Striim applications without writing external scripts
- Alert on pipeline lag, event-count divergence, or log errors and Smart Alerts
- Track data-quality metrics (source inserts vs. target inserts over time, including initial-load progress)
- Audit application configuration changes (TQL change tracking) or detect configuration drift
- Store checkpoint history for compliance, recovery-point analysis, or troubleshooting
- Monitor Oracle LogMiner open transactions, Oracle JET (OJet) memory/SCN metrics, or data-warehouse batch performance
- Track file-lineage for file-based sources or trail-file generation

**Not ideal for:**
- Very short polling intervals (do not go below 120 seconds — Striim's internal monitoring calls have overhead, and running more often than 5 minutes is not recommended)
- Environments where the monitoring database is unavailable (StriimWatcher requires a downstream target to be useful — it does not visualize anything on its own)

---

## Prerequisites

- The StriimWatcher module loaded into your Striim deployment by your administrator
- A target database (PostgreSQL, BigQuery, Snowflake, etc.) with a schema/dataset to receive the monitoring tables (the `mon.*` tables are auto-created by Striim's DatabaseWriter with `CDDLAction: Process`) — if your target type's DDL isn't available yet, ask Field Engineering to help create it
- Access to create a Striim application (or ask your Striim administrator to create one for you)
- **The StriimWatcher version must match your Striim version.** Ask your Field Engineer for the correct build for your Striim release before installing.

---

## Installing and Upgrading StriimWatcher

1. **Download** the StriimWatcher jar that matches your Striim version from Field Engineering.
2. **If StriimWatcher is already loaded**, check `list libraries;` in the console. If it's listed, unload the existing version first — referencing the exact jar filename shown, e.g. `UNLOAD OPEN PROCESSOR 'UploadedFiles/StriimWatcher-5.2.4.jar';`. The jar must still exist in `UploadedFiles/` for the unload to succeed, so don't delete it before unloading.
3. **Upload the new jar** through the Striim UI's Files page (under "Manage Striim"). Do not place the jar directly on the Striim server's filesystem, the `lib` directory, or the `modules` directory — doing so can cause file-permission issues and make it harder to unload or replace later.
4. **Load it**: `LOAD OPEN PROCESSOR 'UploadedFiles/StriimWatcherV2.jar';`, then confirm with `list libraries;`.
5. If "StriimWatcher" doesn't show up yet when you search for it as a Source in the Flow Designer, refresh your browser and try again.

**Major version upgrades are not in-place.** Moving between major StriimWatcher versions typically requires exporting your application, dropping it, unloading the old StriimWatcher version, and reloading the new one (some upgrades also need DDL changes — new columns — on your monitoring tables). Always check with your Field Engineer before a major-version upgrade rather than assuming a simple reload will work.

---

## Adding It To Your Application

1. In the Striim Flow Designer, create a new application (e.g. `StriimMonitoring`).
2. Drag a **Source** component onto the canvas and select **StriimWatcher** from the source picker.
3. Fill in the settings (see below). Most settings are on/off toggles — enable the data categories you want.
4. Add an output stream (e.g. `MonitoringStream`).
5. Add a **Target** component (e.g. DatabaseWriter for PostgreSQL, or BigQueryWriter for BigQuery).
6. Connect the stream to the target. For DatabaseWriter, set **Tables** to `mon.%,public.%` and **CDDLAction** to `Process` so all monitoring tables are created automatically.
7. Deploy and start the application.

---

## Settings You'll Configure

### How Often to Collect

| Setting | What it's for | Example |
|---|---|---|
| Repeat In Seconds | How many seconds between each monitoring snapshot. Should be longer than the value you see in `runtimeDurationMS` (how long a collection pass actually takes) so runs don't pile up. Minimum recommended: 120; not recommended below 300 (5 minutes). | `300` |
| Start On | Date and time for the first snapshot. The default value is a special placeholder that means "start immediately" — leave it as-is unless you genuinely need a delayed start. | `2023-11-10T1:20:00` |
| End On | Optional stop time. Leave blank to run indefinitely (this is the normal case). | *(leave blank)* |
| Preserve Position | Remember cumulative counts and log-file positions across restarts so delta-per-interval calculations and log reading stay accurate. **Note:** this only survives a restart on the same Striim node — it does not currently survive an application failover to a different node in a cluster. | `false` |

### Node and Cluster Health

| Setting | What it's for | Example |
|---|---|---|
| Include Node Monitor | Capture per-application event rates and CPU. This is the master switch for all three settings in this group — turning it off disables the other two below regardless of their own setting. | `true` |
| Include Node Cluster | Capture cluster-node memory, CPU, uptime, and Striim version. | `true` |
| Include Node ES | Capture Elasticsearch node throughput and storage metrics. | `true` |

### Application Detail

| Setting | What it's for | Example |
|---|---|---|
| Include App Detail | Capture per-application status (backpressure, recovery, encryption, input/output totals). | `true` |
| Include App Describe Detail | Include recovery mode and encryption status from application metadata. | `true` |
| Include App Status Detail | Include which servers the application is deployed on. | `true` |
| Include Created App Detail | Also report on applications that exist but are not yet deployed. Not commonly needed. | `false` |
| Include Deployed App Detail | Also report on deployed-but-stopped applications. Not commonly needed. | `false` |

### Metrics and Counts

| Setting | What it's for | Example |
|---|---|---|
| Include LEE | Capture end-to-end latency statistics for each source-to-target path — useful for SLA tracking and spotting latency trends. | `true` |
| Include Table Comparison | Capture cumulative insert/update/delete/DDL/PK-update counts for each source-target pair and the difference between them — useful for replication-progress and data-consistency tracking. | `true` |
| Include SLI Table Comparison | Capture the *change* in those counts since the previous snapshot (useful for per-interval throughput). Empty on the very first run — there's nothing to compare against yet. | `true` |
| Include Target Information | Capture detailed per-target component metrics (accepted rate, write rate, CPU, discarded-event count, etc.). | `true` |
| Include Target Info Detail | Include the full raw JSON monitoring output for each target. | `false` |
| Include Source Information | Capture detailed per-source component metrics (read rate, lag, freshness, etc.). | `true` |
| Include Source Info Detail | Include the full raw JSON monitoring output for each source. | `false` |
| Include DW Details | Capture data-warehouse target batch statistics (BigQuery/Snowflake/Databricks-class target batch timing, merge metrics, queue depth) — useful for tuning batch policies. | `false` |
| Include System Configuration | Capture Striim system configuration parameters (config files, JVM/OS memory, disk space) and flag any that changed. | `true` |
| Include Only Config Changes | When on, only emit system-configuration entries where the value changed since last snapshot, instead of every parameter every time. | `false` |
| Include System Config Detail | Include full JSON detail for each configuration entry (does not affect *whether* a row appears, only whether the verbose detail column is filled in). | `false` |
| Include Checkpoint History | Capture new checkpoint records (useful for audit, recovery-point analysis, and source-target lag detection). The first run records a starting point silently; only later runs report genuinely new checkpoints. | `false` |
| Include Oracle Open Trx | Capture open Oracle LogMiner transactions (helps diagnose long-running transactions causing lag). Produces nothing for non-Oracle sources. | `false` |
| Include File Lineage | Capture file-lineage records for file-based sources and targets (new files, status changes, trail-file generation) — useful for spotting stuck files. | `false` |
| Include OJet Metrics | Capture Oracle JET memory and SCN metrics for Oracle CDC sources using the OJet reader. Produces nothing for non-OJet sources. | `false` |

### Log and Alert Monitoring

> **On-premises only.** The three log-file settings below read Striim's own log files directly from disk and are **not available on Striim Cloud.**

| Setting | What it's for | Example |
|---|---|---|
| Include Log Watcher | Parse the Striim server log for ERROR entries (with surrounding context lines) and Smart Alert matches. On-prem only. | `true` |
| Include Debug Log | Also parse the Striim debug log. On-prem only. | `false` |
| Include Command Log | Also parse the Striim command log. On-prem only. | `false` |
| Include System Commands | When Command Log is on, also include commands issued by the system itself (including StriimWatcher's own activity) rather than only user-issued commands. | `false` |
| Include Vault Health Check | Each cycle, read from every configured Vault to confirm it's reachable; failures produce log-watcher events. This also has the side effect of keeping each vault's connection/auth alive during quiet periods. | `false` |
| Monitor Process Names | Comma-separated OS process names to check for liveness; missing processes generate alerts. Because this checks real operating-system processes on the Striim server, treat it as an operational setting rather than something to populate from untrusted input. | `striim-server,nginx` |
| Autoheal Monitoring Apps | Automatically restart any of Striim's own monitoring applications (alerting, notification, health-event apps) that are found not running. Only takes effect when Include Node Monitor is also on. | `false` |

### API Event Harvesting

These settings pull events from Striim's internal monitoring APIs (rather than reading log files), so they work the same way on-prem and on Striim Cloud.

| Setting | What it's for | Example |
|---|---|---|
| Include Monitor Log Events | Harvest ERROR/WARN events from Striim's monitoring API (complements file-based log watching, and works where file-based watching can't). | `false` |
| Include Exception Store | Harvest exception events from the Striim exception manager. | `false` |
| Include Notification Events | Harvest notification events from the Striim notification store. | `false` |
| Include Health Events | Harvest health events from the Striim health event publisher. | `false` |
| Include User Commands | Harvest user-issued commands from the Striim command history. | `false` |

### Advanced

| Setting | What it's for | Example |
|---|---|---|
| Additional Command List | Semicolon-separated Striim console commands to run each cycle, with an optional per-command interval in `{}` (must be a multiple of Repeat In Seconds). Supports wildcards `%source-all%`, `%target-all%`, `%app-all%` (loop over every matching entity) and `%source-running%`, `%target-running%`, `%app-running%` (loop over only running ones — **prefer the `-all` variants**, as the `-running` filters have a known matching bug that can cause them to silently return nothing). | `mon %source-all% memorysize{900};usage;` |
| Include Component Details | Emit raw JSON monitoring output for every component into the component-output table. **Can significantly increase output volume** — enable only when you need it. | `false` |
| Include Type Details | Emit column-level schema information for all user-defined Striim types, by actively inspecting every type in your metadata repository each cycle. **Can significantly increase output and execution time** — this is the heaviest setting in StriimWatcher; enable with care. | `false` |
| Include TQL Change Tracking | Detect and emit an event whenever any application property value changes between snapshots (property-level granularity). This history is kept in memory only — it does not survive a StriimWatcher restart even with Preserve Position enabled. | `false` |

> **Want to know exactly what ends up in each monitoring table?** Every setting above corresponds to one or more output tables (e.g. enabling Include LEE produces `mon.striim_mon_lee`). For a full column-by-column breakdown of every table — what each field means and what you'd use it for — see [`readme_datastructure.md`](readme_datastructure.md).

---

## Example Walkthrough

The following creates a StriimWatcher application that polls every 5 minutes and writes all monitoring data to a PostgreSQL database:

```sql
CREATE APPLICATION StriimWatcherTestApp;

CREATE SOURCE StriimWatcherSourceA USING Global.StriimWatcherV2 (
  RepeatInSeconds: '300',
  IncludeNodeMonitor: true,
  IncludeNodeCluster: true,
  IncludeNodeES: true,
  IncludeAppDetail: true,
  IncludeAppDescribeDetail: true,
  IncludeAppStatusDetail: true,
  IncludeLee: true,
  IncludeTableComparisonDetail: true,
  IncludeTableComparisonDetail_SinceLastInterval: true,
  IncludeTargetInformation: true,
  IncludeSourceInformation: true,
  IncludeSystemConfiguration: true,
  IncludeLogWatcher: true,
  IncludeMonitorLogEvents: true,
  IncludeExceptionStore: true,
  IncludeNotificationEvents: true,
  IncludeHealthEvents: true,
  IncludeUserCommands: true,
  AutohealMonitoringApps: true,
  StartOn: '2020-12-31T08:00' )
OUTPUT TO StriimWatcherTestAppOutputStream;

CREATE TARGET PostgreSQLTarget USING Global.DatabaseWriter (
  DatabaseProviderType: 'Postgres',
  ConnectionURL: 'jdbc:postgresql://your-db-host:5432/striimwatcher',
  Username: 'striim',
  Password: 'your-password',
  Tables: 'mon.%,public.%',
  BatchPolicy: 'EventCount:1000,Interval:60',
  CommitPolicy: 'EventCount:1000,Interval:60',
  CheckPointTable: 'CHKPOINT',
  CDDLAction: 'Process' )
INPUT FROM StriimWatcherTestAppOutputStream;

END APPLICATION StriimWatcherTestApp;
```

(Adapted from this project's `test_app.tql` — with the legacy `StriimAPIHttpProtocol`/`StriimAPIHttpHostname`/`StriimAPIHttpPort`/`DisableSSLValidation` settings removed; they're leftover from an older version of StriimWatcher and no longer do anything.)

After starting the application, the monitoring database will contain tables such as `mon.striim_mon_appdetail`, `mon.striim_mon_lee`, `mon.striim_mon_table_comparison`, and so on — one table per data category. Each table is automatically created by Striim's DatabaseWriter on first use.

### A sample Additional Command List walkthrough

To check memory usage for every source every 15 minutes, and run the standard `usage;` command on every regular collection cycle:

```
mon %source-all% memorysize{900};usage;
```

To check the status of every running application every 5 minutes:

```
status %app-running%{300};
```

### What a Log Watcher event looks like

A plain log error looks roughly like this once it reaches your monitoring table:

```json
{
  "appName": "admin.OracleInitialLoadApp",
  "log_level": "ERROR",
  "message": "BatchTimer ... Error code {23000} is not in {[...]}, not considering it as ConnectionException",
  "contextbuffertext": "<surrounding log lines for context>"
}
```

A Smart Alert (e.g. a source or target going idle) looks similar but with `log_level` formatted as `<AlertName>:<componentName>`:

```json
{
  "appName": "admin.OracleInitialLoadApp",
  "log_level": "Target_Idle:admin.OracleIL_Target",
  "message": "Target admin.OracleIL_Target: No new event delivered in last 65.97 (>60) seconds.",
  "contextbuffertext": "Target_Idle, Medium: WEB, Message: Target admin.OracleIL_Target: No new event delivered in last 65.97 (>60) seconds."
}
```

---

## FAQ / Tips

**Q: How do I know it's working?**
After starting the application, check the `mon.striim_mon_table_runhistory` table — a new row appears at the end of each polling cycle, every cycle, regardless of which other settings are on. The `runtimeDurationMS` column shows how long the collection pass took — make sure your `Repeat In Seconds` is comfortably longer than this value.

**Q: Why don't I see SLI (since-last-interval) data on the first run?**
The `striim_mon_table_comparison_sli` table shows *changes* between consecutive snapshots. It is empty on the first run because there is no prior snapshot to compare against. Data appears from the second poll onward.

**Q: Why are there no events after I start the application?**
Check that **Start On** is not set to a real future date. The default value is a placeholder that means "start immediately" — if you've typed in an actual datetime, make sure it's in the past.

**Q: Can the source/target difference in Table Comparison go negative?**
Yes. A negative difference (target count higher than source count) can happen when a target is still processing a backlog and catches up past where the source's counter currently sits — it isn't necessarily an error.

**Q: My CPU rate looks impossibly high (e.g. 800%) — is that a bug?**
No — CPU rate fields are reported per-core, not as a percentage of total machine capacity. An 8-core system can show up to 800%.

**Q: Can I run multiple StriimWatcher instances?**
Yes. Run one instance per monitored Striim cluster. Each instance should write to a separate schema or database to avoid table conflicts.

**Q: How do I reduce the number of events?**
Disable the data categories you don't need. In particular, disabling **Include Log Watcher**, **Include Source Info Detail**, **Include Target Info Detail**, **Include Component Details**, and especially **Include Type Details** can significantly reduce volume and execution time. Also increase **Repeat In Seconds**.

**Q: What is the minimum polling interval?**
120 seconds is the technical floor; 300 seconds (5 minutes) or longer is the practical recommendation. Lower values increase load on the Striim server and on StriimWatcher's own memory footprint.

**Q: Will StriimWatcher monitor itself?**
No — StriimWatcher excludes its own source and target from LEE and table-comparison output to avoid self-referential noise.

**Q: What does "Preserve Position" actually protect against?**
A same-node restart of the StriimWatcher application. It does **not** currently protect against the application failing over to a different node in a cluster — full cluster-safe position recovery is implemented but disabled due to a known platform limitation, so treat "Preserve Position" as same-node-only for now. Note also that TQL Change Tracking history is never preserved across a restart, with or without this setting.

**Q: Should I worry about `discardedEventCount` in the target information table?**
Yes — a non-zero value there is a useful early signal of target table-mapping issues worth investigating.

**Q: I see old TQL with `StriimAPIHttpProtocol`/`StriimAPIHttpHostname`/`StriimAPIHttpPort`/`DisableSSLValidation` — should I set those?**
No. These were used by an older version of StriimWatcher that called the Striim console over HTTP. The current version talks to Striim internally and no longer needs them — setting them is harmless but does nothing. Leave them out of new applications.

**Q: Does enabling Vault Health Check do anything besides checking health?**
Yes — running it also keeps each vault's connection/authentication "warm" during quiet periods, in addition to reporting failures.

**Q: Field Engineering asked me to turn on debug logging — how do I do that?**
Run the following in the Striim console:

```sql
set loglevel = {com.striim.util.StriimWatcherV2: debug};
```

Debug output goes to `logs/striim.server.clidebug.log`. Turn it back off once you (or your Field Engineer) have what's needed — debug logging is verbose and isn't meant to be left on indefinitely:

```sql
set loglevel = {com.striim.util.StriimWatcherV2: info};
```

A good rule of thumb is to turn it off again after about 10 minutes, or after one full polling interval has elapsed (whichever is longer).

---

## Getting Help

For assistance configuring or troubleshooting StriimWatcher, contact **Field Engineering and Striim Support**.
