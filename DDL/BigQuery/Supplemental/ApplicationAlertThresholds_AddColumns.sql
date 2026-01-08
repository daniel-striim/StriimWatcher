-- Script: Add new columns to existing ApplicationAlertThresholds table
-- Purpose: Add columns for enhanced alert threshold configuration
-- Usage: Run this script to update existing BigQuery table structure

-- Add RetainStaticValueFlag column
ALTER TABLE `striim_watcher_metadata.ApplicationAlertThresholds`
ADD COLUMN retainStaticValueFlag BOOLEAN DEFAULT FALSE;

-- Add Source Inactivity Threshold column
ALTER TABLE `striim_watcher_metadata.ApplicationAlertThresholds`
ADD COLUMN sourceInactivityThresholdMinutes INT64;

-- Add Max Queued Batches on Target column
ALTER TABLE `striim_watcher_metadata.ApplicationAlertThresholds`
ADD COLUMN maxQueuedBatchesOnTarget INT64;

-- Add Max Batch Size Bytes column
ALTER TABLE `striim_watcher_metadata.ApplicationAlertThresholds`
ADD COLUMN maxBatchSizeBytes INT64;

-- Verify the changes
SELECT column_name, data_type, is_nullable, description
FROM `striim_watcher_metadata.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS`
WHERE table_name = 'ApplicationAlertThresholds'
ORDER BY ordinal_position;