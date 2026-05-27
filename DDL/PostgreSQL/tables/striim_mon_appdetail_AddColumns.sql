-- Script: Add new columns to existing striim_mon_appdetail table
-- Purpose: Add backpressuredcomponents column for backpressure stream tracking
-- Usage: Run this script to update existing PostgreSQL table structure
--        (deployments that ran the DDL before backpressuredcomponents was added)

-- Add backpressured component names column
ALTER TABLE mon.striim_mon_appdetail
ADD COLUMN IF NOT EXISTS backpressuredcomponents TEXT;

-- Verify the changes
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'mon'
  AND table_name = 'striim_mon_appdetail'
  AND column_name = 'backpressuredcomponents'
ORDER BY ordinal_position;
