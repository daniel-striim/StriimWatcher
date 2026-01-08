
CREATE OR REPLACE TABLE FUNCTION `striim_watcher_metadata.generate_unified_alerts`(striimwatcher_threshold_minutes INT64)
RETURNS TABLE<
  clusterName STRING,
  entity_name STRING,
  deploymentOn STRING,
  alert_type STRING,
  alert_trigger_time TIMESTAMP,
  duration_of_problem_state_minutes INT64,
  configured_threshold_minutes INT64
>
AS (
WITH
-- Step 1: Collect all alerts from individual functions
AllAlerts AS (
  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM `striim_watcher_metadata.get_terminated_app_alerts`()

  UNION ALL

  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM `striim_watcher_metadata.get_backpressure_alerts`()

  UNION ALL

  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM `striim_watcher_metadata.get_checkpoint_alerts`()

  UNION ALL

  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM `striim_watcher_metadata.get_high_lee_alerts`()

  UNION ALL

  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM `striim_watcher_metadata.get_sourceidle_alerts`()

  UNION ALL

  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM `striim_watcher_metadata.get_queuedbatches_alerts`()

  UNION ALL

  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM `striim_watcher_metadata.get_largebatches_alerts`()

  UNION ALL

  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM `striim_watcher_metadata.get_striimwatcher_silence_alerts`(striimwatcher_threshold_minutes)
),

-- Step 2: Assign priority levels to each alert type
AlertsWithPriority AS (
  SELECT
    *,
    CASE alert_type
      WHEN 'STRIIMWATCHER_SILENCE' THEN 1  -- Highest priority: system-level issues
      WHEN 'TERMINATED' THEN 2            -- App completely down
      WHEN 'CHECKPOINT_NOT_PROGRESSING' THEN 3  -- Recovery issues
      WHEN 'BACKPRESSURE' THEN 4          -- Performance issues
      WHEN 'SOURCE_IDLE' THEN 5           -- Source inactivity issues
      WHEN 'QUEUED_BATCHES' THEN 6        -- Batch queue issues
      WHEN 'LARGE_BATCHES' THEN 7         -- Batch size issues
      WHEN 'HIGH_AVG_LEE' THEN 8          -- Lowest priority: latency issues
      ELSE 99
    END AS alert_priority
  FROM AllAlerts
),

-- Step 3: For each cluster/app combination, find the highest priority alert
HighestPriorityPerEntity AS (
  SELECT
    clusterName,
    entity_name,
    MIN(alert_priority) AS min_priority
  FROM AlertsWithPriority
  GROUP BY clusterName, entity_name
),

-- Step 4: Filter to keep only the highest priority alerts per entity
FilteredAlerts AS (
  SELECT
    a.clusterName,
    a.entity_name,
    a.deploymentOn,
    a.alert_type,
    a.alert_trigger_time,
    a.duration_of_problem_state_minutes,
    a.configured_threshold_minutes,
    a.alert_priority
  FROM AlertsWithPriority a
  INNER JOIN HighestPriorityPerEntity h
    ON a.clusterName = h.clusterName
    AND a.entity_name = h.entity_name
    AND a.alert_priority = h.min_priority
),

-- Step 5: Apply cluster-level suppression for StriimWatcher silence alerts
FinalAlerts AS (
  SELECT
    clusterName,
    entity_name,
    deploymentOn,
    alert_type,
    alert_trigger_time,
    duration_of_problem_state_minutes,
    configured_threshold_minutes
  FROM FilteredAlerts
  WHERE
    -- Include StriimWatcher silence alerts (they suppress everything else in their cluster)
    alert_type = 'STRIIMWATCHER_SILENCE'

    OR

    -- Include other alerts only if their cluster doesn't have StriimWatcher silence
    (
      alert_type != 'STRIIMWATCHER_SILENCE'
      AND clusterName NOT IN (
        SELECT DISTINCT clusterName
        FROM FilteredAlerts
        WHERE alert_type = 'STRIIMWATCHER_SILENCE'
      )
    )
)

-- Step 6: Return the final results
SELECT
  clusterName,
  entity_name,
  deploymentOn,
  alert_type,
  alert_trigger_time,
  duration_of_problem_state_minutes,
  configured_threshold_minutes
FROM FinalAlerts
ORDER BY
  -- Order by priority: StriimWatcher, Terminated, Checkpoint, Backpressure, Source Idle, Queued Batches, Large Batches, High LEE
  CASE alert_type
    WHEN 'STRIIMWATCHER_SILENCE' THEN 1
    WHEN 'TERMINATED' THEN 2
    WHEN 'CHECKPOINT_NOT_PROGRESSING' THEN 3
    WHEN 'BACKPRESSURE' THEN 4
    WHEN 'SOURCE_IDLE' THEN 5
    WHEN 'QUEUED_BATCHES' THEN 6
    WHEN 'LARGE_BATCHES' THEN 7
    WHEN 'HIGH_AVG_LEE' THEN 8
    ELSE 9
  END,
  clusterName,
  entity_name
);

