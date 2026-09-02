# StriimWatcher BigQuery Alerting Functions

BigQuery routines that turn StriimWatcher's monitoring data (in `striim_watcher_metadata`) into
alerts and manage the thresholds those alerts fire on.

## Alert detector functions

Each of these is a table function that scans recent monitoring history and returns rows for
apps currently in a qualifying problem state. All share the same output shape:

`clusterName, entity_name, deploymentOn, alert_type, alert_trigger_time, duration_of_problem_state_minutes, configured_threshold_minutes`

| Function | Alert type | Fires when |
|---|---|---|
| `get_terminated_app_alerts()` | `TERMINATED` | An app's status is `HALT`, `CRASH`, or `UNKNOWN` for longer than `terminatedThresholdMinutes`. |
| `get_backpressure_alerts()` | `BACKPRESSURE` | An app has been backpressured continuously for longer than `backpressureThresholdMinutes`. |
| `get_checkpoint_alerts()` | `CHECKPOINT_NOT_PROGRESSING` | An app has recovery enabled but its checkpoint hasn't progressed for longer than `checkpointNotProgressingThresholdMin` (apps still in `CREATED`/`DEPLOYED` are excluded — they haven't started yet). |
| `get_high_lee_alerts()` | `HIGH_AVG_LEE` | A source→target pair's average latency (LEE) exceeds `avgLeeThresholdMinutes` continuously. |
| `get_largebatches_alerts()` | `LARGE_BATCHES` | An app's last or average batch size exceeds `maxBatchSizeBytes` for at least 5 minutes. |
| `get_queuedbatches_alerts()` | `QUEUED_BATCHES` | An app's queued-batch count on target exceeds `maxQueuedBatchesOnTarget` for at least 5 minutes. |
| `get_sourceidle_alerts()` | `SOURCE_IDLE` | A source has logged a WARN-level `Source_Idle` message with idle time exceeding `sourceInactivityThresholdMinutes`. |
| `get_striimwatcher_silence_alerts(threshold_minutes)` | `STRIIMWATCHER_SILENCE` | A cluster hasn't reported any monitoring data for longer than `threshold_minutes` (default 60 if `NULL`). |

All eight read `ApplicationAlertThresholds` for their thresholds and skip apps where
`isEnabled = FALSE` (or the relevant per-alert-type check flag is off). Each looks back only a
recent window of history (10 days for app-state/latency alerts, 5 days for batch/source-idle
alerts) for performance.

`generate_unified_alerts(striimwatcher_threshold_minutes)` calls all eight detectors, keeps only
the highest-priority alert per entity (silence > terminated > checkpoint > backpressure >
source-idle > queued-batches > large-batches > high-LEE), and suppresses every non-silence alert
for a cluster that is itself silent (no point alerting on an app's backpressure if the whole
cluster stopped reporting). This is the function dashboards should query.

## Threshold management

| Function | Purpose |
|---|---|
| `get_alert_thresholds(appName)` | Reads one app's `isEnabled` flag and its four tunable thresholds. |
| `toggle_alert(appName, isEnabled)` | Enables or disables alerting for one app. |
| `tune_alert_thresholds(appName, terminated, checkpoint, backpressure, sourceIdle)` | Manually overrides those four thresholds for one app. Does **not** set `retainStaticValueFlag`, so a manual override can be replaced by the next auto-tune run unless `retainStaticValueFlag` is also set on the row. |
| `update_alert_thresholds()` | Auto-tunes thresholds for all active CDC apps by MERGE-ing recommendations from the `StriimIntelligentThresholdRecommendations` view (../views/) into `ApplicationAlertThresholds`. Skips any app with `retainStaticValueFlag = TRUE`. Run this on a schedule (e.g. daily) to keep thresholds current as usage patterns change. |
| `insert_alert_updates()` | **Deprecated** — the original monolithic version of the auto-tune logic now in `update_alert_thresholds()`. Kept for reference/rollback only; do not schedule it. |

## Downtime analysis

| Function | Purpose |
|---|---|
| `get_app_downtime_analysis(days_back)` | Returns downtime metrics per app over a lookback window (transition counts, longest outage, most recent outage). Useful for a 30-day trend view. |

## Looker/dashboard queries

These support the Leadership and Operational dashboards and aren't called by the alerting
pipeline itself:

| Function | Dashboard | Purpose |
|---|---|---|
| `looker_alert_trends.sql` | Leadership | Alert frequency/patterns over time. |
| `looker_throughput_trends.sql` | Leadership | Source/target throughput trends. |
| `looker_data_flowing_graph.sql` | Leadership | Cumulative data flow and rate for RUNNING apps. |
| `looker_lag_graph.sql` | Leadership | Lag with a 7-day rolling average. |
| `looker_app_failure_list.sql` | Operational | Apps that went TERMINATED within a time window. |
| `looker_app_failure_drilldown.sql` | Operational | Log entries around a specific app failure, for root-cause analysis. |
| `looker_smart_alert_history.sql` | Operational | Recent WARN-level log entries. |
