# Looker Dashboard Queries for StriimWatcher

This directory contains BigQuery views and table functions optimized for GCP Looker dashboards to visualize StriimWatcher monitoring data.

## Overview

The queries are organized into two main dashboards:

1. **Operational Dashboard** - Real-time monitoring for operations teams
2. **Leadership Dashboard** - High-level metrics and trends for leadership

All queries are designed to work with BigQuery's performance optimizations including:
- Partitioning by `batchdate`
- Clustering on key fields
- Efficient window functions for time-series analysis
- Table functions for parameterized queries

## Data Model

### Hierarchy
```
striim_mon_table_runhistory (clusterName, batchdate)
    ↓ (joined via batchdate)
striim_mon_node_cluster (nodename)
    ↓
striim_mon_appdetail (appName, deploymentOn)
    ↓
striim_mon_node_applications (cpurate, status)
```

### Key Concepts
- **batchdate**: Point-in-time snapshot timestamp (FK to all tables)
- **clusterName**: From `striim_mon_table_runhistory`, identifies the Striim cluster
- **nodename**: From `striim_mon_appdetail.deploymentOn`, identifies the node
- **appName**: Application identifier across multiple tables

## Schema

All queries use the `striim_watcher_metadata` schema in BigQuery.

## Query Types

### Views
Static queries that return the latest/current state:
- `looker_cpu_usage_per_app` - Latest CPU usage per application
- `looker_files_open_list` - Files currently being processed
- `looker_apps_down_count` - Current down applications with duration

### Table Functions
Parameterized queries for flexible time windows and filtering:
- `looker_app_failure_list(days_back)` - App failures within time window
- `looker_app_failure_drilldown(app_name, failure_batchdate, minutes_window)` - Logs near failure
- `looker_smart_alert_history(days_back)` - WARN level alerts
- `looker_lag_graph(days_back, filter_app_name, filter_source_type, filter_target_type)` - Lag metrics with rolling average
- `looker_data_flowing_graph(days_back)` - Data flow metrics and rates

## Quick Start

### 1. Deploy Queries to BigQuery

```bash
# Deploy all views
bq query --use_legacy_sql=false < views/looker_cpu_usage_per_app.sql
bq query --use_legacy_sql=false < views/looker_files_open_list.sql
bq query --use_legacy_sql=false < views/looker_apps_down_count.sql

# Deploy all table functions
bq query --use_legacy_sql=false < functions/looker_app_failure_list.sql
bq query --use_legacy_sql=false < functions/looker_app_failure_drilldown.sql
bq query --use_legacy_sql=false < functions/looker_smart_alert_history.sql
bq query --use_legacy_sql=false < functions/looker_lag_graph.sql
bq query --use_legacy_sql=false < functions/looker_data_flowing_graph.sql
```

### 2. Connect Looker to BigQuery

1. In Looker, go to **Admin > Connections**
2. Create a new BigQuery connection
3. Set the dataset to `striim_watcher_metadata`
4. Test the connection

### 3. Create LookML Models

See `LOOKML_EXAMPLES.md` for detailed LookML model definitions.

## Documentation Files

- **README.md** (this file) - Overview and quick start
- **OPERATIONAL_DASHBOARD.md** - Operational dashboard queries and usage
- **LEADERSHIP_DASHBOARD.md** - Leadership dashboard queries and usage
- **LOOKML_EXAMPLES.md** - LookML model and view definitions
- **QUERY_EXAMPLES.md** - SQL query examples and testing

## Performance Considerations

### BigQuery Optimization
- All queries leverage partitioning on `batchdate`
- Window functions are optimized for time-series analysis
- Table functions allow Looker to push down filters to BigQuery

### Looker Best Practices
- Use persistent derived tables (PDTs) for expensive aggregations
- Set appropriate caching policies based on data freshness requirements
- Use incremental PDTs for historical data that doesn't change

## Support

For questions or issues:
1. Review the dashboard-specific documentation
2. Check query examples in `QUERY_EXAMPLES.md`
3. Verify BigQuery table structure matches expected schema

## Version History

- **v1.0** - Initial release with Operational and Leadership dashboards

