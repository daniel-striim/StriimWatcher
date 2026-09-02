-- Function: update_alert_thresholds
-- Purpose: Apply the auto-tuned thresholds from StriimIntelligentThresholdRecommendations
-- Usage: CALL `striim_watcher_metadata.update_alert_thresholds`();
-- Returns: Summary of apps updated
-- Note: replaces the old insert_alert_updates() per-app EXECUTE IMMEDIATE loop with a single
--       MERGE. The QUALIFY dedups the recommendation view down to one row per appName (a
--       prior version could produce a duplicate row per app and fail the MERGE).

CREATE OR REPLACE PROCEDURE `striim_watcher_metadata.update_alert_thresholds`()
BEGIN
  DECLARE apps_to_update_count INT64;

  -- Count rows needing updates
  SET apps_to_update_count = (
    SELECT COUNT(*)
    FROM `striim_watcher_metadata.StriimIntelligentThresholdRecommendations`
  );

  IF apps_to_update_count > 0 THEN

    MERGE `striim_watcher_metadata.ApplicationAlertThresholds` AS target
    USING (
      SELECT *
      FROM `striim_watcher_metadata.StriimIntelligentThresholdRecommendations`
      QUALIFY ROW_NUMBER() OVER (
        PARTITION BY appName
        ORDER BY confidence_level DESC, appName DESC
      ) = 1
    ) AS source
    ON target.appName = source.appName

    WHEN MATCHED
         AND source.needs_update
         AND (target.retainStaticValueFlag IS NULL OR target.retainStaticValueFlag = FALSE)
    THEN
      UPDATE SET
        terminatedThresholdMinutes = source.new_terminated_threshold,
        backpressureThresholdMinutes = source.new_backpressure_threshold,
        checkpointNotProgressingThresholdMin = source.new_checkpoint_threshold,
        avgLeeThresholdMinutes = source.new_lee_threshold,
        maxBatchSizeBytes = source.new_largebatches_threshold,
        maxQueuedBatchesOnTarget = source.new_queuedbatches_threshold,
        sourceInactivityThresholdMinutes = source.new_sourceidle_threshold,
        isCdcApp = source.is_likely_cdc_app,
        terminatedCheckEnabled = TRUE,
        isEnabled = TRUE

    WHEN NOT MATCHED
         AND source.needs_update
    THEN
      INSERT (
        id,
        appName,
        isCdcApp,
        terminatedCheckEnabled,
        terminatedThresholdMinutes,
        backpressureThresholdMinutes,
        checkpointNotProgressingThresholdMin,
        avgLeeThresholdMinutes,
        maxBatchSizeBytes,
        maxQueuedBatchesOnTarget,
        sourceInactivityThresholdMinutes,
        retainStaticValueFlag,
        isEnabled
      )
      VALUES (
        GENERATE_UUID(),
        source.appName,
        source.is_likely_cdc_app,
        TRUE,
        source.new_terminated_threshold,
        source.new_backpressure_threshold,
        source.new_checkpoint_threshold,
        source.new_lee_threshold,
        source.new_largebatches_threshold,
        source.new_queuedbatches_threshold,
        source.new_sourceidle_threshold,
        FALSE,
        TRUE
      );

  END IF;

  -- Return summary for logging
  SELECT
    apps_to_update_count AS apps_updated,
    CURRENT_TIMESTAMP() AS execution_time,
    'Alert thresholds updated successfully' AS status;

END;
