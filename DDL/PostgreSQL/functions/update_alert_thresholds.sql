-- Function: update_alert_thresholds
-- Purpose: Apply the auto-tuned thresholds from StriimIntelligentThresholdRecommendations
-- Usage: SELECT * FROM mon.update_alert_thresholds();
-- Returns: Summary of apps updated
-- Note: replaces the old insert_alert_updates() per-app FOR-loop with a single set-based
--       upsert. The ROW_NUMBER() dedup keeps one row per appName (a prior version could
--       produce a duplicate row per app and fail the upsert on the unique appName lookup).

CREATE OR REPLACE FUNCTION mon.update_alert_thresholds()
RETURNS TABLE(
  apps_updated BIGINT,
  execution_time TIMESTAMPTZ,
  result_status TEXT
)
AS $$
DECLARE
  v_apps_updated BIGINT := 0;
BEGIN
  WITH deduped_recommendations AS (
    SELECT *
    FROM (
      SELECT
        r.*,
        ROW_NUMBER() OVER (
          PARTITION BY r.appName
          ORDER BY r.confidence_level DESC, r.appName DESC
        ) as rn
      FROM mon.StriimIntelligentThresholdRecommendations r
    ) ranked
    WHERE ranked.rn = 1
  ),
  upserted AS (
    INSERT INTO mon.ApplicationAlertThresholds (
      id, appName, isCdcApp, terminatedCheckEnabled,
      terminatedThresholdMinutes, backpressureThresholdMinutes,
      checkpointNotProgressingThresholdMin, avgLeeThresholdMinutes,
      maxBatchSizeBytes, maxQueuedBatchesOnTarget, sourceInactivityThresholdMinutes,
      retainStaticValueFlag, isEnabled
    )
    SELECT
      gen_random_uuid()::TEXT, dr.appName, dr.is_likely_cdc_app, TRUE,
      dr.new_terminated_threshold, dr.new_backpressure_threshold,
      dr.new_checkpoint_threshold, dr.new_lee_threshold,
      dr.new_largebatches_threshold, dr.new_queuedbatches_threshold, dr.new_sourceidle_threshold,
      FALSE, TRUE
    FROM deduped_recommendations dr
    WHERE dr.needs_update
    ON CONFLICT (appName) DO UPDATE SET
      terminatedThresholdMinutes = EXCLUDED.terminatedThresholdMinutes,
      backpressureThresholdMinutes = EXCLUDED.backpressureThresholdMinutes,
      checkpointNotProgressingThresholdMin = EXCLUDED.checkpointNotProgressingThresholdMin,
      avgLeeThresholdMinutes = EXCLUDED.avgLeeThresholdMinutes,
      maxBatchSizeBytes = EXCLUDED.maxBatchSizeBytes,
      maxQueuedBatchesOnTarget = EXCLUDED.maxQueuedBatchesOnTarget,
      sourceInactivityThresholdMinutes = EXCLUDED.sourceInactivityThresholdMinutes,
      isCdcApp = EXCLUDED.isCdcApp,
      terminatedCheckEnabled = TRUE,
      isEnabled = TRUE
    WHERE mon.ApplicationAlertThresholds.retainStaticValueFlag IS NULL
       OR mon.ApplicationAlertThresholds.retainStaticValueFlag = FALSE
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_apps_updated FROM upserted;

  RETURN QUERY SELECT
    v_apps_updated as apps_updated,
    CURRENT_TIMESTAMP as execution_time,
    'Alert thresholds updated successfully'::TEXT as result_status;
END;
$$ LANGUAGE plpgsql;
