# StriimWatcherV4 — Monitoring Table Data Dictionary

This document catalogs every monitoring table StriimWatcherV4 can produce: what it contains, which setting turns it on, and what you'd use it for. It plays the same role the original Confluence page (*StriimWatcher Monitoring Source OP*) played for earlier versions, but the table and column lists below are **re-derived directly from the current source code**, not carried over from that page — several tables have gained columns since that page was last updated (notably `striim_mon_datawarehouse_detail`, `striim_mon_table_comparison`, and `striim_mon_table_comparison_sli`).

- For setup instructions and what each *setting* does, see [`README_Customer.md`](README_Customer.md).
- For the full technical reference (Java field-level mapping, lifecycle, parameters table), see [`README.md`](README.md).

All tables live in the `mon` namespace (e.g. `mon.striim_mon_appdetail`). Every table also carries these standard fields on every row, stamped automatically by the platform — they're omitted from the per-table column lists below to avoid repetition:

| Field | Meaning |
|---|---|
| `TimeStamp` | When this specific event was created |
| `NextRun` | When the next polling cycle is scheduled |
| `TotalRuns` | How many polling cycles have run so far |
| `TableName` | The `mon.*` table this event belongs to |
| `OperationName` | Always `INSERT` — StriimWatcherV4 never updates or deletes rows |
| `ColumnCount` | Number of data columns in this event |
| `OPERATION_TS` | Epoch timestamp of the operation |
| `RelatedAppName` | The monitored application this row is about (when the table is app-specific) |

Every row also has a `batchdate` column — the timestamp when that polling cycle started. `batchdate` is the key you join every table back to `mon.striim_mon_table_runhistory` on, which is the one table that's always produced regardless of settings.

---

## Tables produced every poll cycle (when enabled)

### `mon.striim_mon_table_runhistory` — Run History
**Always on — cannot be disabled.**

One row per poll cycle. This is the anchor/fact table every other table's `batchdate` ties back to.

| Field | Type | Meaning |
|---|---|---|
| `runid` (PK) | Long | Unique run ID |
| `batchdate` | DateTime | Cycle start timestamp |
| `runtimeEnd` | DateTime | Cycle end timestamp |
| `runtimeDurationMS` | Integer | How long the collection pass took, in milliseconds |
| `clusterName` | String | Striim cluster name |
| `companyName` | String | Striim company name |
| `lastrun` | DateTime | Start time of the previous cycle |
| `nextrun` | DateTime | Scheduled start of the next cycle |

**Use cases:** confirming StriimWatcherV4 is actually running, sizing `Repeat In Seconds` against `runtimeDurationMS`, and as the join key for every other table.

---

### `mon.striim_mon_node_applications` — Node Application Status
**Gated by:** Include Node Monitor

One row per Striim application reported by the platform's node-level monitor.

| Field | Type | Meaning |
|---|---|---|
| `monappid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `command` | String | The command executed (`mon;`) |
| `montype` | String | Entity type reported |
| `appname` | String | Full application name |
| `status` | String | Application status |
| `rate` | Double | Event rate |
| `sourcerate` | Integer | Source read rate |
| `cpurate` | Double | CPU utilization rate (per-core — see note below) |
| `numservers` | Integer | Number of servers running the app |
| `latestActivity` | DateTime | Timestamp of last activity |

**Use cases:** application inventory, cluster-wide status overview, quick health check, application discovery.

> **Note:** CPU rate fields throughout StriimWatcherV4 are reported per-core, not as a percentage of total machine capacity — an 8-core system can show up to 800%.

---

### `mon.striim_mon_node_cluster` — Cluster Node Hardware
**Gated by:** Include Node Cluster (requires Include Node Monitor also on)

One row per cluster node.

| Field | Type | Meaning |
|---|---|---|
| `monnodeclusterid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `command` | String | The command executed |
| `montype` | String | Entity type |
| `nodename` | String | Cluster node name |
| `striimversion` | String | Striim version running on this node |
| `freemem` | String | Free memory (raw string with units) |
| `cpurate` | Double | CPU utilization |
| `uptime` | String | Node uptime (raw string) |

**Use cases:** cluster capacity planning, spotting version skew across nodes, uptime tracking.

---

### `mon.striim_mon_node_elasticsearch` — Elasticsearch Node Metrics
**Gated by:** Include Node ES (requires Include Node Monitor also on)

One row per Elasticsearch node entry (only meaningful if your Striim deployment uses Elasticsearch for monitoring data).

| Field | Type | Meaning |
|---|---|---|
| `monnodesid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `command` | String | The command executed |
| `montype` | String | Entity type |
| `elasticsearchReceiveThroughput` | Long | Receive throughput |
| `elasticsearchTransmitThroughput` | Long | Transmit throughput |
| `elasticsearchClusterStorageFree` | Long | Cluster storage free |
| `elasticsearchClusterStorageTotal` | Long | Cluster storage total |

**Use cases:** Elasticsearch cluster health and storage-capacity monitoring.

---

### `mon.striim_mon_appdetail` — Per-Application Detail
**Gated by:** Include App Detail (enriched by Include App Describe Detail / Include App Status Detail)

One row per running application (plus created/deployed-but-stopped apps if those options are enabled).

| Field | Type | Meaning |
|---|---|---|
| `monid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `command` | String | The monitoring command run for this app |
| `appName` | String | Full application name |
| `appStatus` | String | Application status |
| `totalInput` | Integer | Sum of source input event counts |
| `totalOutput` | Integer | Sum of target output event counts |
| `isBackpressured` | Boolean | Whether any stream in the app is backpressured |
| `isRecoveryEnabled` | Boolean | Whether recovery/checkpointing is on |
| `recoverySetting` | String | Recovery setting name |
| `checkpointStatus` | String | Checkpoint status |
| `checkpointDetail` | String | Per-source/per-target checkpoint positions as a JSON array string; `null` until the app records its first checkpoint |
| `isEncryptionEnabled` | Boolean | Whether app encryption is on |
| `deploymentOn` | String | Node(s) the app is deployed on |
| `deploymentIn` | String | Deployment group |
| `appCreatedDate` | DateTime | Application creation timestamp |
| `latestActivity` | DateTime | Last activity timestamp |
| `backpressuredComponents` | String | Comma-separated list of backpressured stream names |

**Use cases:** application health monitoring, throughput tracking, backpressure detection, checkpoint progress monitoring, deployment tracking.

---

### `mon.striim_mon_lee` — Latency End-to-End (LEE)
**Gated by:** Include LEE

One row per source-target pair with latency data. StriimWatcherV4 excludes itself from this table (no self-referential noise).

| Field | Type | Meaning |
|---|---|---|
| `monleeid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `sourceApp` | String | Application containing the source |
| `sourceName` | String | Source component name |
| `sourceType` | String | Source adapter type |
| `targetApp` | String | Application containing the target |
| `targetName` | String | Target component name |
| `targetType` | String | Target adapter type |
| `lagEndToEnd` | String | Current end-to-end lag |
| `measuredAt` | DateTime | When the measurement was taken |
| `sourceTime` | String | Source-side time reference |
| `minLEE` | Double | Minimum lag over the sample |
| `maxLEE` | Double | Maximum lag over the sample |
| `avgLEE` | Double | Average lag over the sample |
| `sampleSize` | Double | Number of samples in the measurement |

**Use cases:** end-to-end latency monitoring, SLA compliance tracking, performance analysis, latency trend detection.

---

### `mon.striim_mon_table_comparison` — Cumulative Table Comparison
**Gated by:** Include Table Comparison

One row per unique application/source/target combination, with all-time cumulative counts.

| Field | Type | Meaning |
|---|---|---|
| `tblcompareid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` | String | Application name |
| `sourceName` | String | Source table/stream name |
| `targetName` | String | Target table name |
| `srcNumOfDeletes` / `tgtNumOfDeletes` / `diffNumOfDeletes` | Integer | Cumulative deletes — source, target, and the difference |
| `srcNumOfDdls` / `tgtNumOfDdls` / `diffNumOfDdls` | Integer | Cumulative DDLs — source, target, and the difference |
| `srcNumOfPkupdates` / `tgtNumOfPkupdates` / `diffNumOfPkupdates` | Integer | Cumulative primary-key updates — source, target, and the difference |
| `srcNumOfUpdates` / `tgtNumOfUpdates` / `diffNumOfUpdates` | Integer | Cumulative updates — source, target, and the difference |
| `srcNumOfInserts` / `tgtNumOfInserts` / `diffNumOfInserts` | Integer | Cumulative inserts — source, target, and the difference |
| `sourceComponentName` | String | Source adapter component name |
| `targetComponentName` | String | Target adapter component name |

**Use cases:** replication progress tracking, lag detection, data-consistency validation, initial-load monitoring.

> A negative `diff*` value (target count higher than source count) can happen when a target is catching up on a backlog — it isn't necessarily an error.

---

### `mon.striim_mon_table_comparison_sli` — Delta Table Comparison (Since Last Interval)
**Gated by:** Include SLI Table Comparison — requires a prior cycle's data, so it's empty on the very first run.

Same dimensions as Table Comparison above, but showing the *change* since the previous poll rather than the all-time total.

| Field | Type | Meaning |
|---|---|---|
| `tblcomparesliid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `timesincelastbatch` | Long | Seconds since the previous cycle |
| `appName` / `sourceName` / `targetName` | String | Application, source, and target names |
| `srcNumOfDeletes_sli` / `tgtNumOfDeletes_sli` / `diffNumOfDeletes_sli` | Integer | Delta deletes since last poll |
| `srcNumOfDdls_sli` / `tgtNumOfDdls_sli` / `diffNumOfDdls_sli` | Integer | Delta DDLs since last poll |
| `srcNumOfPkupdates_sli` / `tgtNumOfPkupdates_sli` / `diffNumOfPkupdates_sli` | Integer | Delta PK-updates since last poll |
| `srcNumOfUpdates_sli` / `tgtNumOfUpdates_sli` / `diffNumOfUpdates_sli` | Integer | Delta updates since last poll |
| `srcNumOfInserts_sli` / `tgtNumOfInserts_sli` / `diffNumOfInserts_sli` | Integer | Delta inserts since last poll |
| `sourceComponentName` / `targetComponentName` | String | Source/target adapter component names |

**Use cases:** per-interval throughput tracking, spotting sudden drops or spikes in replication activity — complements the cumulative Table Comparison table above.

---

### `mon.striim_mon_target_information` — Target Component Metrics
**Gated by:** Include Target Information (full raw JSON added by Include Target Info Detail)

One row per target component.

| Field | Type | Meaning |
|---|---|---|
| `montgtinfoid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` / `componentName` | String | Application and target component name |
| `accepted` | Long | Total events accepted |
| `noOfEventsAcceptedPerInterval` | Long | Events accepted in the monitoring interval |
| `acceptedRate` | Double | Acceptance rate |
| `input_count` / `inputRate` | Long / Double | Input event count and rate |
| `output_count` / `event_rate` | Long / Double | Output event count and throughput rate |
| `targetAcked` / `targetOutput` / `targetRate` | Long / Long / Double | Target-side acknowledged count, output count, write rate |
| `cpu` / `cpuRatePerNode` / `cpuRate` | Double | CPU usage (overall, per-node, overall rate) |
| `discardedEventCount` | Long | Events discarded — a non-zero value is an early signal of target table-mapping issues |
| `numberOfEventsSeenPerMonitorSnapshotInterval` | Long | Events seen per snapshot interval |
| `lastEventWriteAge` | String | Age of last write |
| `latestActivity` | DateTime | Last activity timestamp |
| `maxLeeFromAllSources` | String | Max latency across all sources feeding this target |
| `numServers` | Long | Number of servers |
| `montimestamp` | DateTime | Monitoring snapshot timestamp |
| `writeBytes` | String | Write throughput in bytes |
| `jsonoutput` | String | Full raw JSON (only populated when Include Target Info Detail is on) |

**Use cases:** target-adapter performance tuning, write-rate and CPU monitoring, catching discarded events early.

---

### `mon.striim_mon_source_information` — Source Component Metrics
**Gated by:** Include Source Information (full raw JSON added by Include Source Info Detail)

One row per source component.

| Field | Type | Meaning |
|---|---|---|
| `monsrcinfoid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` / `componentName` | String | Application and source component name |
| `input_count` / `inputRate` | Long / Double | Input event count and rate |
| `sourceInput` / `sourceRate` | Long / Double | Source-side input count and read rate |
| `event_rate` | Double | Event throughput rate |
| `numberOfEventsSeenPerMonitorSnapshotInterval` | Long | Events per snapshot interval |
| `cpu` / `cpuRatePerNode` / `cpuRate` | Double | CPU usage (overall, per-node, overall rate) |
| `lastEventReadAge` | String | Age of last read |
| `latestActivity` | DateTime | Last activity timestamp |
| `readLag` | Long | Read lag in milliseconds |
| `readTimestamp` | DateTime | Timestamp of last read |
| `sourceFreshness` / `sourceFreshnessMinutes` | String / Long | Source freshness, as text and in minutes |
| `numServers` | Long | Number of servers |
| `montimestamp` | DateTime | Monitoring snapshot timestamp |
| `jsonoutput` | String | Full raw JSON (only populated when Include Source Info Detail is on) |

**Use cases:** source-adapter performance tuning, read-lag and freshness monitoring.

---

### `mon.striim_mon_system_configuration` — System Configuration
**Gated by:** Include System Configuration (filtered to only-changed values by Include Only Config Changes; full JSON added by Include System Config Detail)

One row per configuration parameter, across three sub-categories each cycle: configuration files, JVM/OS memory, and disk space.

| Field | Type | Meaning |
|---|---|---|
| `monsysconfigid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `configType` | String | `CONFIG_FILE`, `MEMORY`, or `DISK_SPACE` |
| `parameterName` | String | Parameter name |
| `parameterValue` | String | Current parameter value |
| `valueChanged` | Boolean | Whether the value changed since the last poll |
| `jsonDetail` | String | Full JSON detail (only populated when Include System Config Detail is on) |

**Use cases:** configuration drift detection, capacity monitoring (disk/memory), system health tracking.

---

### `mon.striim_mon_datawarehouse_detail` — Data Warehouse Target Batch Detail
**Gated by:** Include DW Details

One row per target that maps to a data-warehouse adapter (BigQuery, Snowflake, Databricks-class targets).

| Field | Type | Meaning |
|---|---|---|
| `dwdid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` / `sourceName` / `targetName` | String | Application, source, and target names |
| `target_adaptername` | String | Target adapter type |
| `projectId` | String | Cloud project ID (BigQuery) |
| `Mode` | String | Write mode (`APPENDONLY`, `MERGE`) |
| `streamingUpload` / `StreamingConfiguration` | Boolean / String | Streaming upload setting and configuration |
| `optimizedMerge` | Boolean | Whether optimized merge is enabled |
| `batch_event_count` / `batch_interval` | Integer | Configured batch policy |
| `total_batches_created` / `total_batches_ignored` / `total_batches_queued` / `total_batches_uploaded` | Integer | Batch lifecycle counts |
| `partition_pruned_batches` | Integer | Partition-pruned batches |
| `last_successful_merge_time` | DateTime | Timestamp of the last successful merge |
| `max_integration_time_ms` / `min_integration_time_ms` / `avg_integration_time_ms` | Integer / Integer / Double | Integration time stats |
| `avg_in_mem_compaction_time_ms` / `avg_compaction_time_ms` / `avg_merge_time_ms` / `avg_upload_time_ms` / `avg_waiting_time_in_queue_ms` / `avg_stage_resources_mgmt_time_ms` | Double | Per-stage timing averages |
| `avg_batch_size_bytes` / `avg_event_count_per_batch` | Integer / Double | Batch size and event-count averages |
| `last_batch_inserts` / `last_batch_updates` / `last_batch_deletes` / `last_batch_ddls` / `last_batch_pk_updates` | Integer | Operation counts in the most recent batch |
| `last_batch_event_count` / `last_batch_size_bytes` / `last_batch_max_record_size_bytes` / `last_batch_total_events_merged` / `last_batch_sequence_number` | Integer | Most-recent-batch sizing/sequencing |
| `last_batch_accumulation_time_ms` / `last_batch_compaction_time_ms` / `last_batch_upload_time_ms` / `last_batch_merge_time_ms` / `last_batch_in_mem_compaction_time_ms` / `last_batch_pk_update_time_ms` / `last_batch_ddl_execution_time_ms` / `last_batch_stage_resources_mgmt_time_ms` / `last_batch_total_integration_time_ms` | Integer | Most-recent-batch timing breakdown |
| `targetComponentName` | String | Target component full name |

**Use cases:** data-warehouse performance tuning, batch optimization, queue monitoring, throughput analysis, bottleneck identification.

---

### `mon.striim_mon_oracle_open_trx` — Oracle Open Transactions
**Gated by:** Include Oracle Open Trx — produces no rows for non-Oracle sources.

One row per open Oracle LogMiner transaction.

| Field | Type | Meaning |
|---|---|---|
| `monopentrxid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` / `componentName` | String | Application and source component name |
| `transactionId` | String | Oracle transaction ID |
| `numOfOps` | String | Number of operations in the transaction |
| `sequenceNum` | String | Redo log sequence number |
| `startscn` | String | Transaction start SCN |
| `rbaBlock` | String | Redo Byte Address block |
| `threadNum` | String | Redo thread number |
| `montimestamp` | DateTime | Monitoring snapshot timestamp |

**Use cases:** monitoring long-running transactions that could be contributing to source lag.

---

### `mon.striim_mon_ojet_metrics` — Oracle JET (OJet) Metrics
**Gated by:** Include OJet Metrics — produces no rows for non-OJet sources.

One row per Oracle source using the OJet reader.

| Field | Type | Meaning |
|---|---|---|
| `monojetid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` / `componentName` | String | Application and source component name |
| `memUsageLogminer` / `memUsageCapture` / `memUsageApply` / `memUsageStreamsPool` | Double | Memory usage by subsystem |
| `txnSpillingToDisk` | Boolean | Whether transactions are spilling to disk |
| `lastObservedScn` / `currentScn` | String | SCN progress |
| `redoSwitchCount` | String | Redo log switch count |
| `logmnrRecordCount` | String | LogMiner record count |
| `lastObservedTimestamp` | DateTime | Timestamp of last observation |

**Use cases:** Oracle CDC capacity planning — watching LogMiner/Capture/Apply memory usage and SCN progress.

---

### `mon.striim_mon_tql_history` — TQL Change History
**Gated by:** Include TQL Change Tracking

One row per detected property-level configuration change.

| Field | Type | Meaning |
|---|---|---|
| `montqlhistid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` | String | Application full name |
| `componentType` | String | Component type (SOURCE, TARGET, etc.) |
| `componentName` | String | Component full name |
| `propertyName` | String | Property that changed |
| `changeType` | String | `INITIAL` (first time seen), `ADDED`, `MODIFIED`, or `REMOVED` |
| `propertyValue` | String | Current property value (`null` for `REMOVED`) |
| `detectedAt` | DateTime | Timestamp when the change was detected |

**Use cases:** configuration audit trail and change history — who/what changed and when, for compliance or for tracking down unexpected behavior changes. This history is kept in memory only and does not survive a StriimWatcherV4 restart.

---

## Incremental tables (only new entries after the first run)

### `mon.striim_mon_checkpoint_history` — Checkpoint History
**Gated by:** Include Checkpoint History

On the first run, all known checkpoints for recovery-enabled apps are emitted as a baseline (silently). On every run after that, only checkpoints not seen in the prior pass are emitted.

| Field | Type | Meaning |
|---|---|---|
| `monchkpthistid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` | String | Application name |
| `serialNo` | Integer | Checkpoint serial number |
| `sourcePositionSummary` / `targetPositionSummary` | String | Source/target position at the checkpoint |
| `checkpointType` | String | Checkpoint type (e.g. `NORMAL`, `RECOVERY`) |
| `checkpointRecordedTime` | DateTime | When the checkpoint was recorded |

**Use cases:** recovery-point monitoring, checkpoint-frequency analysis, source-target lag detection.

---

### `mon.striim_mon_file_lineage` — File Lineage
**Gated by:** Include File Lineage

On the first run, all known file-lineage entries (for both sources and targets) are emitted as a baseline. On every run after that, only new or status-changed entries are emitted.

| Field | Type | Meaning |
|---|---|---|
| `monfilelineageid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` / `componentName` | String | Application and component name |
| `fileName` / `directoryName` | String | File name and containing directory |
| `file_status` | String | File processing status |
| `fileCreationTime` | DateTime | File creation timestamp |
| `numberOfEvents` | Long | Number of events read from the file |
| `firstEventTimestamp` / `lastEventTimestamp` | DateTime | Timestamp of the first and last event in the file |
| `wrapNumber` | Integer | Log wrap number |
| `sequenceNumber` | String | Log sequence number |

**Use cases:** monitoring file-processing lag, detecting stuck files, tracking when new trail files are generated.

---

## Per-event tables (one row per log line, alert, or API-harvested event)

### `mon.striim_mon_log_watcher` — Log and Alert Events
**Gated by:** any of Include Log Watcher / Include Debug Log / Include Command Log / Include Vault Health Check / Monitor Process Names / Include Monitor Log Events / Include Exception Store / Include Notification Events / Include Health Events / Include User Commands

One row per log entry, Smart Alert, process-check failure, vault-health failure, or API-harvested event — all sharing this one table, distinguished by `log_level` and the `AlertType` metadata tag.

| Field | Type | Meaning |
|---|---|---|
| `errorid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `log_date` | DateTime | Timestamp of the log entry or alert |
| `server` | String | Server name where the entry originated |
| `appName` | String | Related application name |
| `log_level` | String | Log level, or for Smart Alerts: `<alertName>:<sourceOrTarget>` |
| `message` | String | Log message or alert text |
| `contextbuffertext` | String | Surrounding log lines (errors) or the matched alert pattern (Smart Alerts) |

**Use cases:** centralized error and alert triage across every application, without tailing log files by hand.

---

## On-demand tables (custom commands or schema inspection)

### `mon.striim_mon_component_output` — Component Raw Output
**Gated by:** Include Component Details, or a non-empty Additional Command List

One row per component or custom command result.

| Field | Type | Meaning |
|---|---|---|
| `moncomoutid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `appName` | String | Application name (may be empty for custom commands) |
| `componentName` | String | Component name or the literal command text |
| `command` | String | The command that produced the output |
| `type` | String | Component type, or `CUSTOM` for Additional Command List results |
| `jsondata` | String | Raw JSON output |

**Use cases:** configuration-change tracking, advanced diagnostics, custom monitoring, schema-evolution investigation.

---

### `mon.striim_mon_table_column_detail` — Type Column Detail
**Gated by:** Include Type Details

One row per column, for every user-defined Striim type. All types are emitted on the first run; on later runs, only types created or changed since the last run are re-emitted.

| Field | Type | Meaning |
|---|---|---|
| `montblcoldtlid` (PK) | Long | Unique event ID |
| `batchdate` | DateTime | Cycle start |
| `typeName` | String | Full Striim type name |
| `appName` / `tableName` | String | Application and table name |
| `createdDate` | DateTime | When the type was created |
| `columnName` / `columnType` | String | Column name and Java type |
| `isPK` | Boolean | Whether this column is a primary key |

**Use cases:** schema documentation, type inventory, schema-change detection, data lineage, metadata management.

---

## Document history

This data dictionary was generated by cross-referencing the legacy Confluence page (*StriimWatcher Monitoring Source OP*, last updated for app version 5.2.5) against the current source code. Differences found and corrected here:

- `striim_mon_datawarehouse_detail`, `striim_mon_table_comparison`, and `striim_mon_table_comparison_sli` have more columns than the Confluence page described.
- The Confluence page didn't document `mon_node_cluster`, `mon_node_elasticsearch`, `mon_table_comparison_sli`, `mon_target_information`, `mon_source_information`, `mon_log_watcher`, `mon_ojet_metrics`, or `mon_tql_history` with explicit "use cases" — those use-case lines above were written fresh from the verified column semantics rather than carried over.

If you find a discrepancy between this document and what actually lands in your monitoring database, trust the database and flag it to Field Engineering — this file should be regenerated from source whenever the schema changes.
