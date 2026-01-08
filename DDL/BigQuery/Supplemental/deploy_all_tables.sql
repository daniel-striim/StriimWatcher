-- Deployment Script: All BigQuery Tables
-- Purpose: Deploy all StriimWatcher monitoring tables in correct dependency order
-- Run this script to create all required tables for the monitoring system

-- =============================================================================
-- DEPLOYMENT ORDER (Based on Dependencies)
-- =============================================================================
-- 1. Core tables (no dependencies)
-- 2. Tables that depend on core tables
-- 3. Optional/supplementary tables

-- =============================================================================
-- STEP 1: Core Table (Base dependency for all others)
-- =============================================================================

-- Run: striim_mon_table_runhistory.sql
-- This is the base table that all others reference via batchdate FK

-- =============================================================================
-- STEP 2: Primary Monitoring Tables
-- =============================================================================

-- Run these in any order (all depend only on runhistory):
-- - striim_mon_node_applications.sql
-- - striim_mon_node_cluster.sql  
-- - striim_mon_node_elasticsearch.sql
-- - striim_mon_appdetail.sql
-- - striim_mon_lee.sql
-- - striim_mon_table_comparison.sql
-- - striim_mon_table_comparison_sli.sql
-- - striim_mon_datawarehouse_detail.sql
-- - striim_mon_log_watcher.sql

-- =============================================================================
-- STEP 3: Optional Tables
-- =============================================================================

-- Run these if detailed component monitoring is needed:
-- - striim_mon_component_output.sql
-- - striim_mon_table_column_detail.sql

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- After deployment, verify tables exist:
/*
SELECT 
  table_name,
  table_type,
  creation_time
FROM `striim_watcher_metadata.INFORMATION_SCHEMA.TABLES`
WHERE table_name LIKE 'striim_mon_%'
ORDER BY table_name;
*/

-- Check table descriptions:
/*
SELECT 
  table_name,
  option_value as description
FROM `striim_watcher_metadata.INFORMATION_SCHEMA.TABLE_OPTIONS`
WHERE option_name = 'description'
  AND table_name LIKE 'striim_mon_%'
ORDER BY table_name;
*/

-- =============================================================================
-- TABLE CATEGORIES
-- =============================================================================

-- CORE TABLES (Required):
-- ├── striim_mon_table_runhistory      (Execution tracking)
-- ├── striim_mon_node_applications     (App status & performance)
-- ├── striim_mon_appdetail             (Detailed app metrics)
-- └── striim_mon_lee                   (Latency measurements)

-- INFRASTRUCTURE TABLES:
-- ├── striim_mon_node_cluster          (Node/cluster info)
-- └── striim_mon_node_elasticsearch    (Elasticsearch metrics)

-- DATA QUALITY TABLES:
-- ├── striim_mon_table_comparison      (Source/target comparison)
-- ├── striim_mon_table_comparison_sli  (Incremental comparison)
-- └── striim_mon_datawarehouse_detail  (DW target metrics)

-- DIAGNOSTIC TABLES:
-- ├── striim_mon_log_watcher           (Log monitoring)
-- ├── striim_mon_component_output      (Raw component data)
-- └── striim_mon_table_column_detail   (Schema tracking)

-- =============================================================================
-- DEPLOYMENT COMMANDS
-- =============================================================================

-- To deploy all tables, run each SQL file in this order:

-- 1. Core dependency:
-- bq query --use_legacy_sql=false < striim_mon_table_runhistory.sql

-- 2. Primary tables (any order):
-- bq query --use_legacy_sql=false < striim_mon_node_applications.sql
-- bq query --use_legacy_sql=false < striim_mon_node_cluster.sql
-- bq query --use_legacy_sql=false < striim_mon_node_elasticsearch.sql
-- bq query --use_legacy_sql=false < striim_mon_appdetail.sql
-- bq query --use_legacy_sql=false < striim_mon_lee.sql
-- bq query --use_legacy_sql=false < striim_mon_table_comparison.sql
-- bq query --use_legacy_sql=false < striim_mon_table_comparison_sli.sql
-- bq query --use_legacy_sql=false < striim_mon_datawarehouse_detail.sql
-- bq query --use_legacy_sql=false < striim_mon_log_watcher.sql

-- 3. Optional tables:
-- bq query --use_legacy_sql=false < striim_mon_component_output.sql
-- bq query --use_legacy_sql=false < striim_mon_table_column_detail.sql

SELECT 'BigQuery table deployment script ready. Run individual table files in the order specified above.' as status;
