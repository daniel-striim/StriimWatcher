-- Script: Add new columns to existing striim_mon_datawarehouse_detail table
-- Purpose: Add targetComponentName column for component tracking
-- Usage: Run this script to update existing BigQuery table structure

-- Add Target Component Name column
ALTER TABLE `striim_watcher_metadata.striim_mon_datawarehouse_detail`
ADD COLUMN targetComponentName STRING OPTIONS (
    DESCRIPTION="Target component name from monitoring command (e.g., admin.BigQuerySWTarget)"
);

-- Verify the changes
SELECT column_name, data_type, is_nullable, description
FROM `striim_watcher_metadata.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS`
WHERE table_name = 'striim_mon_datawarehouse_detail'
  AND column_name = 'targetComponentName';

