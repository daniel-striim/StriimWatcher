-- Script: Add new columns to existing striim_mon_table_comparison_sli table
-- Purpose: Add component name columns for source and target tracking
-- Usage: Run this script to update existing PostgreSQL table structure

-- Add Source Component Name column
ALTER TABLE mon.striim_mon_table_comparison_sli
ADD COLUMN sourceComponentName TEXT;

-- Add Target Component Name column
ALTER TABLE mon.striim_mon_table_comparison_sli
ADD COLUMN targetComponentName TEXT;

-- Verify the changes
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'mon'
  AND table_name = 'striim_mon_table_comparison_sli'
  AND column_name IN ('sourceComponentName', 'targetComponentName')
ORDER BY column_name;

