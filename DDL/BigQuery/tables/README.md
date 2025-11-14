# BigQuery Tables

This directory contains individual table creation scripts for the StriimWatcher monitoring system, replacing the monolithic `StriimWatcher-BQ-DropAndRecreateTables.sql` file.

## Directory Structure

```
tables/
├── striim_mon_table_runhistory.sql          # Core execution tracking
├── striim_mon_node_applications.sql         # Application status & performance
├── striim_mon_node_cluster.sql              # Cluster node information
├── striim_mon_node_elasticsearch.sql        # Elasticsearch metrics
├── striim_mon_appdetail.sql                 # Detailed application metrics
├── striim_mon_lee.sql                       # Lag End-to-End measurements
├── striim_mon_table_comparison.sql          # Source/target comparison
├── striim_mon_table_comparison_sli.sql      # Incremental comparison
├── striim_mon_datawarehouse_detail.sql      # Data warehouse metrics
├── striim_mon_log_watcher.sql               # Log monitoring
├── striim_mon_component_output.sql          # Raw component data (optional)
├── striim_mon_table_column_detail.sql       # Schema tracking (optional)
├── deploy_all_tables.sql                    # Deployment script
└── README.md                                # This file
```

## Table Categories

### Core Tables (Required)
- **`striim_mon_table_runhistory`** - Base table tracking StriimWatcher execution runs
- **`striim_mon_node_applications`** - Application status and performance metrics
- **`striim_mon_appdetail`** - Detailed application monitoring (backpressure, recovery, checkpoints)
- **`striim_mon_lee`** - Lag End-to-End latency measurements

### Infrastructure Tables
- **`striim_mon_node_cluster`** - Cluster node information and system resources
- **`striim_mon_node_elasticsearch`** - Elasticsearch cluster metrics

### Data Quality Tables
- **`striim_mon_table_comparison`** - Cumulative source/target comparison
- **`striim_mon_table_comparison_sli`** - Incremental comparison (since last interval)
- **`striim_mon_datawarehouse_detail`** - Data warehouse target metrics and batch processing

### Diagnostic Tables
- **`striim_mon_log_watcher`** - Striim server log monitoring
- **`striim_mon_component_output`** - Raw JSON component data (optional)
- **`striim_mon_table_column_detail`** - Table schema tracking (optional)

## Dependencies

All tables depend on `striim_mon_table_runhistory` via the `batchdate` foreign key:

```
striim_mon_table_runhistory (base)
├── striim_mon_node_applications
├── striim_mon_node_cluster
├── striim_mon_node_elasticsearch
├── striim_mon_appdetail
├── striim_mon_lee
├── striim_mon_table_comparison
├── striim_mon_table_comparison_sli
├── striim_mon_datawarehouse_detail
├── striim_mon_log_watcher
├── striim_mon_component_output (optional)
└── striim_mon_table_column_detail (optional)
```

## Deployment

### Option 1: Individual Files
Deploy tables in dependency order:

1. **Core dependency:**
   ```bash
   bq query --use_legacy_sql=false < striim_mon_table_runhistory.sql
   ```

2. **Primary tables (any order):**
   ```bash
   bq query --use_legacy_sql=false < striim_mon_node_applications.sql
   bq query --use_legacy_sql=false < striim_mon_appdetail.sql
   bq query --use_legacy_sql=false < striim_mon_lee.sql
   # ... etc
   ```

### Option 2: Batch Deployment
Use the deployment script for guidance:
```bash
# Review deploy_all_tables.sql for complete deployment instructions
```

### Option 3: Automated Script
Create a deployment script:
```bash
#!/bin/bash
for table in striim_mon_table_runhistory striim_mon_node_applications striim_mon_appdetail striim_mon_lee striim_mon_node_cluster striim_mon_node_elasticsearch striim_mon_table_comparison striim_mon_table_comparison_sli striim_mon_datawarehouse_detail striim_mon_log_watcher; do
  echo "Deploying $table..."
  bq query --use_legacy_sql=false < ${table}.sql
done
```

## Key Improvements Over Monolithic Approach

### 1. **Modularity**
- Each table is in its own file
- Easy to modify individual tables without affecting others
- Clear separation of concerns

### 2. **Maintainability**
- Individual table changes don't require understanding entire schema
- Easier code reviews and change tracking
- Simplified debugging of table-specific issues

### 3. **Deployment Flexibility**
- Deploy only needed tables
- Incremental deployments
- Easy rollback of individual table changes

### 4. **Documentation**
- Each table file includes purpose and dependencies
- Clear descriptions for all columns
- Table-level options for better metadata

### 5. **Version Control**
- Granular change tracking
- Easier to see what changed in each table
- Better merge conflict resolution

## Usage Examples

### Check Table Status
```sql
SELECT 
  table_name,
  table_type,
  creation_time,
  row_count
FROM `striim_watcher_metadata.INFORMATION_SCHEMA.TABLES`
WHERE table_name LIKE 'striim_mon_%'
ORDER BY table_name;
```

### Verify Table Relationships
```sql
-- Check foreign key relationships via batchdate
SELECT 
  t1.table_name,
  COUNT(*) as record_count
FROM `striim_watcher_metadata.INFORMATION_SCHEMA.TABLES` t1
JOIN `striim_watcher_metadata.striim_mon_table_runhistory` t2
  ON t1.table_name LIKE 'striim_mon_%'
GROUP BY t1.table_name;
```

### Table Size Analysis
```sql
SELECT 
  table_name,
  size_bytes,
  num_rows
FROM `striim_watcher_metadata.INFORMATION_SCHEMA.TABLE_STORAGE`
WHERE table_name LIKE 'striim_mon_%'
ORDER BY size_bytes DESC;
```

## Migration from Monolithic Schema

1. **Backup existing data** if tables already exist
2. **Deploy new modular tables** using individual files
3. **Verify table structure** matches requirements
4. **Test data ingestion** with StriimWatcher
5. **Remove old deployment scripts** once confirmed working

## Adding New Tables

To add a new monitoring table:

1. **Create new SQL file** following naming convention
2. **Include proper documentation** (purpose, dependencies, description)
3. **Add to deployment script** in appropriate order
4. **Update this README** with table information
5. **Test deployment** in development environment
