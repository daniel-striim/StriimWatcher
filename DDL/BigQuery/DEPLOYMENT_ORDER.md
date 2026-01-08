# BigQuery DDL Deployment Guide

This document describes the correct deployment order for StriimWatcher BigQuery objects.

## Prerequisites

- Google Cloud SDK installed with `bq` command available
- Authenticated to the correct GCP project
- Dataset `striim_watcher_metadata` exists

## Deployment Order

Objects must be deployed in the following order due to dependencies:

### Phase 1: Tables (No Dependencies)

Deploy all base tables first. These have no dependencies on other objects.

```bash
# Core monitoring tables
bq query --use_legacy_sql=false < tables/striim_mon_appdetail.sql
bq query --use_legacy_sql=false < tables/striim_mon_lee.sql
bq query --use_legacy_sql=false < tables/striim_mon_table_runhistory.sql
bq query --use_legacy_sql=false < tables/striim_mon_node_applications.sql
bq query --use_legacy_sql=false < tables/striim_mon_node_cluster.sql
bq query --use_legacy_sql=false < tables/striim_mon_node_elasticsearch.sql
bq query --use_legacy_sql=false < tables/striim_mon_component_output.sql
bq query --use_legacy_sql=false < tables/striim_mon_table_comparison.sql
bq query --use_legacy_sql=false < tables/striim_mon_table_comparison_sli.sql
bq query --use_legacy_sql=false < tables/striim_mon_table_column_detail.sql
bq query --use_legacy_sql=false < tables/striim_mon_datawarehouse_detail.sql
bq query --use_legacy_sql=false < tables/striim_mon_log_watcher.sql
bq query --use_legacy_sql=false < tables/striim_mon_checkpoint_history.sql
bq query --use_legacy_sql=false < tables/striim_mon_source_information.sql
bq query --use_legacy_sql=false < tables/striim_mon_target_information.sql
bq query --use_legacy_sql=false < tables/striim_mon_file_lineage.sql
bq query --use_legacy_sql=false < tables/striim_mon_oracle_open_trx.sql
bq query --use_legacy_sql=false < tables/striim_mon_system_configuration.sql
```

### Phase 2: Supplemental Tables (Alert Configuration)

These tables store alert thresholds and are required by alert functions.

```bash
bq query --use_legacy_sql=false < Supplemental/ApplicationAlertThresholds.sql
bq query --use_legacy_sql=false < Supplemental/TableAlertThresholds.sql

# Optional: Load sample data
# bq query --use_legacy_sql=false < Supplemental/ApplicationAlertThresholds_sample_data.sql
# bq query --use_legacy_sql=false < Supplemental/TableAlertThresholds_sample_data.sql
```

### Phase 3: Base Views (Depend on Tables Only)

```bash
bq query --use_legacy_sql=false < views/latest_known_deployments.sql
```

### Phase 4: Alert Functions (Depend on Tables + Supplemental)

Deploy in this order:

```bash
# Core alert detection functions
bq query --use_legacy_sql=false < functions/get_terminated_app_alerts.sql
bq query --use_legacy_sql=false < functions/get_backpressure_alerts.sql
bq query --use_legacy_sql=false < functions/get_checkpoint_alerts.sql
bq query --use_legacy_sql=false < functions/get_high_lee_alerts.sql
bq query --use_legacy_sql=false < functions/get_sourceidle_alerts.sql
bq query --use_legacy_sql=false < functions/get_queuedbatches_alerts.sql
bq query --use_legacy_sql=false < functions/get_largebatches_alerts.sql
bq query --use_legacy_sql=false < functions/get_striimwatcher_silence_alerts.sql
bq query --use_legacy_sql=false < functions/get_app_downtime_analysis.sql

# Unified alert function (depends on individual alert functions)
bq query --use_legacy_sql=false < functions/generate_unified_alerts.sql

# Stored procedure for threshold updates
bq query --use_legacy_sql=false < functions/insert_alert_updates.sql
```

### Phase 5: Looker Functions (Depend on Tables)

```bash
bq query --use_legacy_sql=false < functions/looker_alert_trends.sql
bq query --use_legacy_sql=false < functions/looker_app_failure_list.sql
bq query --use_legacy_sql=false < functions/looker_app_failure_drilldown.sql
bq query --use_legacy_sql=false < functions/looker_data_flowing_graph.sql
bq query --use_legacy_sql=false < functions/looker_lag_graph.sql
bq query --use_legacy_sql=false < functions/looker_smart_alert_history.sql
bq query --use_legacy_sql=false < functions/looker_throughput_trends.sql
```

### Phase 6: Dashboard Views (Depend on Functions + Views)

```bash
# Views that depend on base views only
bq query --use_legacy_sql=false < views/looker_apps_down_count.sql
bq query --use_legacy_sql=false < views/looker_backpressure_status.sql
bq query --use_legacy_sql=false < views/looker_batch_processing.sql
bq query --use_legacy_sql=false < views/looker_checkpoint_health.sql
bq query --use_legacy_sql=false < views/looker_cpu_usage_per_app.sql
bq query --use_legacy_sql=false < views/looker_data_integrity.sql
bq query --use_legacy_sql=false < views/looker_files_open_list.sql
bq query --use_legacy_sql=false < views/looker_node_resources.sql
bq query --use_legacy_sql=false < views/looker_oracle_open_trx.sql
bq query --use_legacy_sql=false < views/looker_source_freshness.sql

# Views that depend on functions
bq query --use_legacy_sql=false < views/looker_unified_alerts.sql
bq query --use_legacy_sql=false < views/looker_downtime_analysis.sql
```

## Quick Deploy Script

To deploy everything at once, run from the DDL/BigQuery directory:

```bash
#!/bin/bash
set -e

echo "Phase 1: Deploying tables..."
for f in tables/*.sql; do cat "$f" | bq query --use_legacy_sql=false; done

echo "Phase 2: Deploying supplemental tables..."
for f in Supplemental/Application*.sql Supplemental/Table*.sql; do 
  [[ ! "$f" =~ sample_data ]] && cat "$f" | bq query --use_legacy_sql=false
done

echo "Phase 3-5: Deploying functions..."
for f in functions/*.sql; do cat "$f" | bq query --use_legacy_sql=false; done

echo "Phase 6: Deploying views..."
for f in views/*.sql; do cat "$f" | bq query --use_legacy_sql=false; done

echo "Deployment complete!"
```

## Dependency Diagram

```
Tables (Phase 1)
    │
    ├── Supplemental Tables (Phase 2)
    │       │
    │       └── Alert Functions (Phase 4)
    │               │
    │               └── generate_unified_alerts
    │                       │
    │                       └── looker_unified_alerts (view)
    │
    ├── latest_known_deployments (view, Phase 3)
    │       │
    │       └── looker_downtime_analysis (view)
    │
    ├── Looker Functions (Phase 5)
    │
    └── Dashboard Views (Phase 6)
```

## Notes

- All objects use CREATE OR REPLACE so they can be safely re-deployed
- Views reference striim_watcher_metadata dataset - update if using a different dataset
- The insert_alert_updates is a stored procedure, not a table function
