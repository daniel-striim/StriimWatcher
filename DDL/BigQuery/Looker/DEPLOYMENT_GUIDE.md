# Looker Dashboard Deployment Guide

This guide walks through the complete deployment process for StriimWatcher Looker dashboards.

## Prerequisites

- GCP Project with BigQuery enabled
- StriimWatcher data already loaded into BigQuery
- Looker instance with BigQuery connection capability
- Service account with BigQuery Data Viewer permissions

## Step 1: Verify BigQuery Schema

### 1.1 Check Table Existence

```bash
# List all tables in the schema
bq ls --max_results=100 striim_watcher_metadata

# Verify key tables exist
bq show striim_watcher_metadata.striim_mon_table_runhistory
bq show striim_watcher_metadata.striim_mon_appdetail
bq show striim_watcher_metadata.striim_mon_lee
bq show striim_watcher_metadata.striim_mon_node_applications
bq show striim_watcher_metadata.striim_mon_log_watcher
bq show striim_watcher_metadata.striim_mon_file_lineage
```

### 1.2 Verify Data Freshness

```sql
-- Check latest data in each table
SELECT 
  'striim_mon_table_runhistory' as table_name,
  MAX(batchdate) as latest_data,
  COUNT(*) as record_count
FROM `striim_watcher_metadata.striim_mon_table_runhistory`

UNION ALL

SELECT 
  'striim_mon_appdetail',
  MAX(batchdate),
  COUNT(*)
FROM `striim_watcher_metadata.striim_mon_appdetail`;
```

## Step 2: Deploy Views and Functions

### 2.1 Deploy Views

```bash
# Navigate to the BigQuery directory
cd DDL/BigQuery

# Deploy CPU Usage view
bq query --use_legacy_sql=false < views/looker_cpu_usage_per_app.sql

# Deploy Files Open view
bq query --use_legacy_sql=false < views/looker_files_open_list.sql

# Deploy Apps Down view
bq query --use_legacy_sql=false < views/looker_apps_down_count.sql
```

### 2.2 Deploy Table Functions

```bash
# Deploy App Failure List function
bq query --use_legacy_sql=false < functions/looker_app_failure_list.sql

# Deploy App Failure Drilldown function
bq query --use_legacy_sql=false < functions/looker_app_failure_drilldown.sql

# Deploy Smart Alert History function
bq query --use_legacy_sql=false < functions/looker_smart_alert_history.sql

# Deploy Lag Graph function
bq query --use_legacy_sql=false < functions/looker_lag_graph.sql

# Deploy Data Flowing Graph function
bq query --use_legacy_sql=false < functions/looker_data_flowing_graph.sql
```

### 2.3 Verify Deployment

```bash
# List all views
bq ls --filter "labels.type:VIEW" striim_watcher_metadata

# List all functions
bq ls --filter "labels.type:ROUTINE" striim_watcher_metadata
```

## Step 3: Test Queries

### 3.1 Test Views

```sql
-- Test CPU Usage view
SELECT COUNT(*) FROM `striim_watcher_metadata.looker_cpu_usage_per_app`;

-- Test Files Open view
SELECT COUNT(*) FROM `striim_watcher_metadata.looker_files_open_list`;

-- Test Apps Down view
SELECT COUNT(*) FROM `striim_watcher_metadata.looker_apps_down_count`;
```

### 3.2 Test Table Functions

```sql
-- Test App Failure List
SELECT COUNT(*) FROM `striim_watcher_metadata.looker_app_failure_list`(30);

-- Test Smart Alert History
SELECT COUNT(*) FROM `striim_watcher_metadata.looker_smart_alert_history`(7);

-- Test Lag Graph
SELECT COUNT(*) FROM `striim_watcher_metadata.looker_lag_graph`(30, NULL, NULL, NULL);

-- Test Data Flowing Graph
SELECT COUNT(*) FROM `striim_watcher_metadata.looker_data_flowing_graph`(7);
```

## Step 4: Configure Looker Connection

### 4.1 Create Service Account

```bash
# Create service account
gcloud iam service-accounts create looker-striim-watcher \
  --display-name="Looker StriimWatcher Reader"

# Grant BigQuery Data Viewer role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:looker-striim-watcher@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataViewer"

# Grant BigQuery Job User role (for running queries)
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:looker-striim-watcher@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.jobUser"

# Create and download key
gcloud iam service-accounts keys create looker-striim-key.json \
  --iam-account=looker-striim-watcher@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### 4.2 Configure Looker Connection

1. Log into Looker as Admin
2. Navigate to **Admin > Connections**
3. Click **Add Connection**
4. Configure:
   - **Name**: `striim_watcher_bq`
   - **Dialect**: Google BigQuery Standard SQL
   - **Billing Project ID**: Your GCP project ID
   - **Dataset**: `striim_watcher_metadata`
   - **Service Account Email**: Upload `looker-striim-key.json`
   - **Max Connections**: 10 (adjust based on usage)
   - **Connection Pool Timeout**: 300 seconds
   - **PDT Overwrite**: Enabled
5. Click **Test** to verify connection
6. Click **Save**

## Step 5: Create LookML Project

### 5.1 Initialize Project

1. In Looker, go to **Develop > Manage LookML Projects**
2. Click **New LookML Project**
3. Configure:
   - **Project Name**: `striim_watcher`
   - **Starting Point**: Blank Project
4. Click **Create Project**

### 5.2 Create Model File

Create `models/striim_watcher.model.lkml`:

```lookml
connection: "striim_watcher_bq"

include: "/views/**/*.view.lkml"
include: "/dashboards/**/*.dashboard.lookml"

datagroup: striim_watcher_default {
  sql_trigger: SELECT MAX(batchdate) FROM `striim_watcher_metadata.striim_mon_table_runhistory` ;;
  max_cache_age: "1 hour"
}

persist_with: striim_watcher_default
```

### 5.3 Create View Files

See `LOOKML_EXAMPLES.md` for complete view definitions. Create these files:

- `views/looker_cpu_usage_per_app.view.lkml`
- `views/looker_app_failure_list.view.lkml`
- `views/looker_smart_alert_history.view.lkml`
- `views/looker_files_open_list.view.lkml`
- `views/looker_lag_graph.view.lkml`
- `views/looker_data_flowing_graph.view.lkml`
- `views/looker_apps_down_count.view.lkml`

### 5.4 Commit Changes

1. Click **Validate LookML**
2. Fix any errors
3. Click **Commit Changes & Push**
4. Enter commit message: "Initial StriimWatcher dashboard setup"
5. Click **Commit**

## Step 6: Create Dashboards

### 6.1 Operational Dashboard

1. Go to **Dashboards > New Dashboard**
2. Name: "StriimWatcher - Operational Dashboard"
3. Add tiles using the explores:
   - CPU Usage chart (from `cpu_usage_per_app`)
   - App Failures table (from `app_failures`)
   - Smart Alerts table (from `smart_alerts`)
   - Files Open table (from `files_open`)

### 6.2 Leadership Dashboard

1. Go to **Dashboards > New Dashboard**
2. Name: "StriimWatcher - Leadership Dashboard"
3. Add tiles:
   - Apps Down KPI (from `apps_down`)
   - Lag Trend chart (from `lag_metrics`)
   - Data Flow chart (from `data_flow`)
   - Apps Down drill-in table (from `apps_down`)

## Step 7: Configure Alerts (Optional)

### 7.1 Create Alert for Apps Down

1. Open Leadership Dashboard
2. Click on "Apps Down" KPI tile
3. Click **⋮ > Alerts**
4. Configure:
   - **Alert Name**: Apps Down Alert
   - **Condition**: Value is greater than 0
   - **Frequency**: Every 15 minutes
   - **Destinations**: Email, Slack, etc.

### 7.2 Create Alert for High CPU

1. Open Operational Dashboard
2. Click on CPU Usage chart
3. Click **⋮ > Alerts**
4. Configure:
   - **Alert Name**: High CPU Alert
   - **Condition**: Any app CPU > 500%
   - **Frequency**: Every 30 minutes

## Troubleshooting

### Issue: "Table not found" errors

**Solution**: Verify schema name in queries matches your BigQuery dataset:
```sql
-- Check current schema
SELECT table_schema, table_name 
FROM `YOUR_PROJECT.INFORMATION_SCHEMA.TABLES`
WHERE table_name LIKE 'striim_mon%';
```

### Issue: Slow query performance

**Solutions**:
1. Enable query caching in Looker connection settings
2. Use PDTs for expensive aggregations
3. Add filters to reduce data scanned

### Issue: NULL values in nodename

**Solution**: This is expected if `deploymentOn` is not populated. Update queries to use COALESCE:
```sql
COALESCE(deploymentOn, 'Unknown') as nodename
```

## Maintenance

### Regular Tasks

1. **Monitor data freshness**: Check that batchdate is updating regularly
2. **Review query performance**: Use BigQuery console to identify slow queries
3. **Update PDTs**: Rebuild PDTs if data changes significantly
4. **Review alerts**: Adjust thresholds based on operational experience

### Updating Queries

When updating views or functions:

```bash
# Update the SQL file
vim views/looker_cpu_usage_per_app.sql

# Redeploy
bq query --use_legacy_sql=false < views/looker_cpu_usage_per_app.sql

# Clear Looker cache
# In Looker: Admin > Cache > Clear Cache
```

## Next Steps

1. Review `OPERATIONAL_DASHBOARD.md` for detailed usage of operational queries
2. Review `LEADERSHIP_DASHBOARD.md` for detailed usage of leadership queries
3. Customize dashboards based on your specific requirements
4. Set up scheduled reports and alerts
5. Train users on dashboard usage
