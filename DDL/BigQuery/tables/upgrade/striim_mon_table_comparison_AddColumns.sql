-- Script: Add new columns to existing striim_mon_table_comparison table
-- Purpose: Add component name columns for source and target tracking
-- Usage: Run this script to update existing BigQuery table structure

-- Add Source Component Name column
ALTER TABLE `striim_watcher_metadata.striim_mon_table_comparison`
ADD COLUMN sourceComponentName STRING OPTIONS (
    DESCRIPTION="Source component name from monitoring command"
);

-- Add Target Component Name column
ALTER TABLE `striim_watcher_metadata.striim_mon_table_comparison`
ADD COLUMN targetComponentName STRING OPTIONS (
    DESCRIPTION="Target component name from monitoring command"
);

-- Verify the changes
SELECT column_name, data_type, is_nullable, description
FROM `striim_watcher_metadata.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS`
WHERE table_name = 'striim_mon_table_comparison'
  AND column_name IN ('sourceComponentName', 'targetComponentName')
ORDER BY column_name;

