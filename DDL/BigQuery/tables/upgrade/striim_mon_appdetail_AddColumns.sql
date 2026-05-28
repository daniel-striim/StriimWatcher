-- Script: Add new columns to existing striim_mon_appdetail table
-- Purpose: Add backpressuredComponents column for backpressure stream tracking
-- Usage: Run this script to update existing BigQuery table structure

-- Add backpressured component names column
ALTER TABLE `striim_watcher_metadata.striim_mon_appdetail`
ADD COLUMN backpressuredComponents STRING OPTIONS (
    DESCRIPTION="Comma-separated list of backpressured stream or component names when the app is backpressured. Null if no backpressure detected."
);

-- Verify the changes
SELECT column_name, data_type, is_nullable, description
FROM `striim_watcher_metadata.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS`
WHERE table_name = 'striim_mon_appdetail'
  AND column_name = 'backpressuredComponents';
