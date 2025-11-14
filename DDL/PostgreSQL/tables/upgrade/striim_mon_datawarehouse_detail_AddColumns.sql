-- Script: Add new columns to existing striim_mon_datawarehouse_detail table
-- Purpose: Add targetComponentName column for component tracking
-- Usage: Run this script to update existing PostgreSQL table structure

-- Add Target Component Name column
ALTER TABLE mon.striim_mon_datawarehouse_detail
ADD COLUMN targetComponentName TEXT;

-- Verify the changes
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema = 'mon'
  AND table_name = 'striim_mon_datawarehouse_detail'
  AND column_name = 'targetComponentName'
ORDER BY ordinal_position;

