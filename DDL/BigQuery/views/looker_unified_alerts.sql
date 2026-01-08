-- View: Looker Unified Alerts
-- Purpose: Shows all active alerts from the unified alert generation function
-- Dashboard: Operational Dashboard
-- Description: Returns current active alerts with priority ranking and suppression applied

CREATE OR REPLACE VIEW `striim_watcher_metadata.looker_unified_alerts` AS
SELECT
  clusterName,
  entity_name as appName,
  deploymentOn as nodename,
  alert_type,
  alert_trigger_time,
  duration_of_problem_state_minutes,
  ROUND(duration_of_problem_state_minutes / 60.0, 2) as duration_hours,
  configured_threshold_minutes,
  CASE alert_type
    WHEN 'STRIIMWATCHER_SILENCE' THEN 1
    WHEN 'TERMINATED' THEN 2
    WHEN 'CHECKPOINT_NOT_PROGRESSING' THEN 3
    WHEN 'BACKPRESSURE' THEN 4
    WHEN 'SOURCE_IDLE' THEN 5
    WHEN 'QUEUED_BATCHES' THEN 6
    WHEN 'LARGE_BATCHES' THEN 7
    WHEN 'HIGH_AVG_LEE' THEN 8
    ELSE 99
  END AS alert_priority,
  CASE alert_type
    WHEN 'STRIIMWATCHER_SILENCE' THEN 'System'
    WHEN 'TERMINATED' THEN 'Availability'
    WHEN 'CHECKPOINT_NOT_PROGRESSING' THEN 'Recovery'
    WHEN 'BACKPRESSURE' THEN 'Performance'
    WHEN 'SOURCE_IDLE' THEN 'Performance'
    WHEN 'QUEUED_BATCHES' THEN 'Performance'
    WHEN 'LARGE_BATCHES' THEN 'Performance'
    WHEN 'HIGH_AVG_LEE' THEN 'Latency'
    ELSE 'Other'
  END AS alert_category,
  CASE 
    WHEN alert_type IN ('STRIIMWATCHER_SILENCE', 'TERMINATED') THEN 'CRITICAL'
    WHEN alert_type IN ('CHECKPOINT_NOT_PROGRESSING', 'BACKPRESSURE') THEN 'HIGH'
    WHEN alert_type IN ('SOURCE_IDLE', 'QUEUED_BATCHES', 'LARGE_BATCHES') THEN 'MEDIUM'
    ELSE 'LOW'
  END AS severity
FROM
  `striim_watcher_metadata.generate_unified_alerts`(30)
ORDER BY
  alert_priority,
  duration_of_problem_state_minutes DESC;

