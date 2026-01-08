-- Function: Generate Unified Alerts
-- Purpose: Main entry point that combines all alert types into a single result set
-- Returns: Standardized alert format across all monitoring types

CREATE OR REPLACE FUNCTION mon.generate_unified_alerts()
RETURNS TABLE(
  clusterName TEXT,
  entity_name TEXT,
  deploymentOn TEXT,
  alert_type TEXT,
  alert_trigger_time TIMESTAMP,
  duration_of_problem_state_minutes BIGINT,
  configured_threshold_minutes BIGINT
) 
AS $$
  -- Terminated Application Alerts
  SELECT 
    clusterName, 
    entity_name, 
    deploymentOn, 
    alert_type, 
    alert_trigger_time, 
    duration_of_problem_state_minutes, 
    configured_threshold_minutes 
  FROM mon.get_terminated_app_alerts()
  
  UNION ALL
  
  -- Backpressure Alerts
  SELECT 
    clusterName, 
    entity_name, 
    deploymentOn, 
    alert_type, 
    alert_trigger_time, 
    duration_of_problem_state_minutes, 
    configured_threshold_minutes 
  FROM mon.get_backpressure_alerts()
  
  UNION ALL
  
  -- Checkpoint Not Progressing Alerts
  SELECT 
    clusterName, 
    entity_name, 
    deploymentOn, 
    alert_type, 
    alert_trigger_time, 
    duration_of_problem_state_minutes, 
    configured_threshold_minutes 
  FROM mon.get_checkpoint_alerts()
  
  UNION ALL
  
  -- High Average LEE Alerts
  SELECT 
    clusterName, 
    entity_name, 
    deploymentOn, 
    alert_type, 
    alert_trigger_time, 
    duration_of_problem_state_minutes, 
    configured_threshold_minutes 
  FROM mon.get_high_lee_alerts()
  
  UNION ALL

  -- StriimWatcher Silence Alerts
  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM mon.get_striimwatcher_silence_alerts()

  UNION ALL

  -- Large Batches Alerts
  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM mon.get_largebatches_alerts()

  UNION ALL

  -- Queued Batches Alerts
  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM mon.get_queuedbatches_alerts()

  UNION ALL

  -- Source Idle Alerts
  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM mon.get_sourceidle_alerts();
$$ LANGUAGE SQL;
