-- Function: insert_alert_updates
-- Purpose: Automatically generate and execute intelligent alert threshold updates
-- Usage: SELECT * FROM mon.insert_alert_updates();
-- Returns: Summary of apps updated and their new thresholds

CREATE OR REPLACE FUNCTION mon.insert_alert_updates()
RETURNS TABLE(
  apps_updated BIGINT,
  total_apps_analyzed BIGINT,
  execution_time TIMESTAMPTZ,
  result_status TEXT
)
AS $$
DECLARE
  v_apps_updated BIGINT := 0;
  v_total_apps BIGINT := 0;
  rec RECORD;
BEGIN
  -- Create a temporary table to store apps that need updates
  CREATE TEMP TABLE IF NOT EXISTS apps_to_update AS
  WITH
  -- Configuration: Hard-coded min/max values and block sizes for each threshold type
  ThresholdConfiguration AS (
    SELECT
      -- Terminated App Thresholds
      60 as terminated_min_minutes,
      240 as terminated_max_minutes,
      15 as terminated_block_size_minutes,
      
      -- Backpressure Thresholds  
      60 as backpressure_min_minutes,
      480 as backpressure_max_minutes,
      30 as backpressure_block_size_minutes,
      
      -- Checkpoint Thresholds
      60 as checkpoint_min_minutes,
      720 as checkpoint_max_minutes,
      60 as checkpoint_block_size_minutes,
      
      -- LEE (Latency) Thresholds
      30 as lee_min_minutes,
      120 as lee_max_minutes,
      5 as lee_block_size_minutes,

      -- Large Batches Thresholds (in bytes)
      104857600 as largebatches_min_bytes,    -- 100MB
      262144000 as largebatches_max_bytes,    -- 250MB

      -- Queued Batches Thresholds
      1 as queuedbatches_min_count,
      2 as queuedbatches_max_count,

      -- Source Idle Thresholds (in minutes)
      60 as sourceidle_min_minutes,
      240 as sourceidle_max_minutes,

      -- UPSERT change threshold (percentage)
      0.20 as change_threshold_pct
  ),
  
  -- Step 1: Analyze terminated app patterns (non-RUNNING states)
  AppStatusHistory AS (
    SELECT
      smd.appName,
      smd.batchdate,
      UPPER(TRIM(smd.appStatus)) as status,
      LAG(UPPER(TRIM(smd.appStatus)), 1, '') OVER (PARTITION BY smd.appName ORDER BY smd.batchdate) as prev_status
    FROM
      mon.striim_mon_appdetail AS smd
    WHERE
      smd.batchdate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
      AND smd.appStatus IS NOT NULL
  ),
  
  SpellGroups AS (
    SELECT
      appName,
      batchdate,
      status,
      SUM(CASE WHEN status != prev_status THEN 1 ELSE 0 END) 
        OVER (PARTITION BY appName ORDER BY batchdate) as spell_id
    FROM
      AppStatusHistory
  ),
  
  NonRunningSpells AS (
    SELECT
      appName,
      spell_id,
      EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate))) / 60 as downtime_minutes
    FROM
      SpellGroups
    WHERE
      status != 'RUNNING'
    GROUP BY
      appName, spell_id
    HAVING
      EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate))) / 60 > 0
  ),

  TerminatedAppAnalysis AS (
    SELECT
      tc.terminated_min_minutes,
      tc.terminated_max_minutes,
      tc.terminated_block_size_minutes,
      nrs.appName,
      COUNT(*) as downtime_events,
      AVG(nrs.downtime_minutes) as avg_downtime_minutes,
      STDDEV(nrs.downtime_minutes) as stddev_downtime_minutes,
      MAX(nrs.downtime_minutes) as max_downtime_minutes,
      PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY nrs.downtime_minutes) as p95_downtime_minutes,
      LEAST(tc.terminated_max_minutes, 
        GREATEST(tc.terminated_min_minutes,
          CAST(CEIL((AVG(nrs.downtime_minutes) + COALESCE(STDDEV(nrs.downtime_minutes), 0)) / tc.terminated_block_size_minutes) * tc.terminated_block_size_minutes AS BIGINT)
        )
      ) as suggested_terminated_threshold
    FROM
      NonRunningSpells nrs
    CROSS JOIN ThresholdConfiguration tc
    GROUP BY
      tc.terminated_min_minutes, tc.terminated_max_minutes, tc.terminated_block_size_minutes, nrs.appName
  ),

  -- Step 2: Analyze backpressure patterns
  BackpressureHistory AS (
    SELECT
      smd.appName,
      smd.batchdate,
      smd.isBackpressured,
      LAG(smd.isBackpressured, 1, NULL) OVER (PARTITION BY smd.appName ORDER BY smd.batchdate) as prev_isBackpressured
    FROM
      mon.striim_mon_appdetail AS smd
    WHERE
      smd.batchdate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
      AND smd.isBackpressured IS NOT NULL
  ),
  
  BackpressureSpells AS (
    SELECT
      appName,
      batchdate,
      isBackpressured,
      SUM(CASE WHEN isBackpressured IS DISTINCT FROM prev_isBackpressured THEN 1 ELSE 0 END) 
        OVER (PARTITION BY appName ORDER BY batchdate) as spell_id
    FROM
      BackpressureHistory
  ),
  
  BackpressureEvents AS (
    SELECT
      appName,
      spell_id,
      EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate))) / 60 as backpressure_minutes
    FROM
      BackpressureSpells
    WHERE
      isBackpressured = TRUE
    GROUP BY
      appName, spell_id
    HAVING
      EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate))) / 60 > 0
  ),

  BackpressureAnalysis AS (
    SELECT
      tc.backpressure_min_minutes,
      tc.backpressure_max_minutes,
      tc.backpressure_block_size_minutes,
      be.appName,
      COUNT(*) as backpressure_events,
      AVG(be.backpressure_minutes) as avg_backpressure_minutes,
      STDDEV(be.backpressure_minutes) as stddev_backpressure_minutes,
      MAX(be.backpressure_minutes) as max_backpressure_minutes,
      LEAST(tc.backpressure_max_minutes,
        GREATEST(tc.backpressure_min_minutes,
          CAST(CEIL((AVG(be.backpressure_minutes) + COALESCE(STDDEV(be.backpressure_minutes), 0)) / tc.backpressure_block_size_minutes) * tc.backpressure_block_size_minutes AS BIGINT)
        )
      ) as suggested_backpressure_threshold
    FROM
      BackpressureEvents be
    CROSS JOIN ThresholdConfiguration tc
    GROUP BY
      tc.backpressure_min_minutes, tc.backpressure_max_minutes, tc.backpressure_block_size_minutes, be.appName
  ),

  -- Step 3: Analyze checkpoint issues
  CheckpointHistory AS (
    SELECT
      smd.appName,
      smd.batchdate,
      (smd.isRecoveryEnabled = TRUE AND UPPER(TRIM(smd.checkpointStatus)) != 'PROGRESSING') AS is_checkpoint_issue,
      LAG((smd.isRecoveryEnabled = TRUE AND UPPER(TRIM(smd.checkpointStatus)) != 'PROGRESSING'), 1, NULL)
        OVER (PARTITION BY smd.appName ORDER BY smd.batchdate) as prev_is_checkpoint_issue
    FROM
      mon.striim_mon_appdetail AS smd
    WHERE
      smd.batchdate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
      AND smd.isRecoveryEnabled IS NOT NULL
  ),

  CheckpointSpells AS (
    SELECT
      appName,
      batchdate,
      is_checkpoint_issue,
      SUM(CASE WHEN is_checkpoint_issue IS DISTINCT FROM prev_is_checkpoint_issue THEN 1 ELSE 0 END)
        OVER (PARTITION BY appName ORDER BY batchdate) as spell_id
    FROM
      CheckpointHistory
  ),

  CheckpointEvents AS (
    SELECT
      appName,
      spell_id,
      EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate))) / 60 as checkpoint_issue_minutes
    FROM
      CheckpointSpells
    WHERE
      is_checkpoint_issue = TRUE
    GROUP BY
      appName, spell_id
    HAVING
      EXTRACT(EPOCH FROM (MAX(batchdate) - MIN(batchdate))) / 60 > 0
  ),

  CheckpointAnalysis AS (
    SELECT
      tc.checkpoint_min_minutes,
      tc.checkpoint_max_minutes,
      tc.checkpoint_block_size_minutes,
      ce.appName,
      COUNT(*) as checkpoint_events,
      AVG(ce.checkpoint_issue_minutes) as avg_checkpoint_minutes,
      STDDEV(ce.checkpoint_issue_minutes) as stddev_checkpoint_minutes,
      MAX(ce.checkpoint_issue_minutes) as max_checkpoint_minutes,
      LEAST(tc.checkpoint_max_minutes,
        GREATEST(tc.checkpoint_min_minutes,
          CAST(CEIL((AVG(ce.checkpoint_issue_minutes) + COALESCE(STDDEV(ce.checkpoint_issue_minutes), 0)) / tc.checkpoint_block_size_minutes) * tc.checkpoint_block_size_minutes AS BIGINT)
        )
      ) as suggested_checkpoint_threshold
    FROM
      CheckpointEvents ce
    CROSS JOIN ThresholdConfiguration tc
    GROUP BY
      tc.checkpoint_min_minutes, tc.checkpoint_max_minutes, tc.checkpoint_block_size_minutes, ce.appName
  ),

  -- Step 4: Analyze LEE (latency) patterns
  LeeAnalysis AS (
    SELECT
      tc.lee_min_minutes,
      tc.lee_max_minutes,
      tc.lee_block_size_minutes,
      sml.sourceApp as appName,
      COUNT(*) as lee_measurements,
      AVG(sml.avgLEE / 60000.0) as avg_lee_minutes,
      STDDEV(sml.avgLEE / 60000.0) as stddev_lee_minutes,
      MAX(sml.avgLEE / 60000.0) as max_lee_minutes,
      PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY sml.avgLEE / 60000.0) as p95_lee_minutes,
      LEAST(tc.lee_max_minutes,
        GREATEST(tc.lee_min_minutes,
          CAST(CEIL((PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY sml.avgLEE / 60000.0) * 1.5) / tc.lee_block_size_minutes) * tc.lee_block_size_minutes AS BIGINT)
        )
      ) as suggested_lee_threshold
    FROM
      mon.striim_mon_lee AS sml
    CROSS JOIN ThresholdConfiguration tc
    WHERE
      sml.batchdate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
      AND sml.avgLEE IS NOT NULL
      AND sml.avgLEE > 0
    GROUP BY
      tc.lee_min_minutes, tc.lee_max_minutes, tc.lee_block_size_minutes, sml.sourceApp
  ),

  -- Step 5: Get application metadata with enhanced CDC detection
  AppBasicMetrics AS (
    SELECT
      smd.appName,
      AVG(smd.totalInput) as avg_input,
      AVG(smd.totalOutput) as avg_output,
      COUNT(DISTINCT DATE(smd.batchdate)) as days_active,
      MAX(smd.batchdate) as last_seen,
      COUNT(CASE WHEN smd.checkpointStatus IS NOT NULL THEN 1 END) as checkpoint_records,
      COUNT(*) as total_records
    FROM
      mon.striim_mon_appdetail AS smd
    WHERE
      smd.batchdate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY
      smd.appName
  ),

  AppSourceTypeInfo AS (
    SELECT
      sml.sourceApp as appName,
      COUNT(CASE WHEN UPPER(TRIM(sml.sourceType)) = 'DATABASEREADER' THEN 1 END) as database_reader_sources,
      COUNT(DISTINCT sml.sourceType) as distinct_source_types
    FROM
      mon.striim_mon_lee AS sml
    WHERE
      sml.batchdate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
      AND sml.sourceApp IS NOT NULL
      AND sml.sourceType IS NOT NULL
    GROUP BY
      sml.sourceApp
  ),

  AppTableOperationInfo AS (
    SELECT
      stc.appName,
      SUM(COALESCE(stc.srcNumOfUpdates, 0) + COALESCE(stc.tgtNumOfUpdates, 0)) as total_updates,
      SUM(COALESCE(stc.srcNumOfDeletes, 0) + COALESCE(stc.tgtNumOfDeletes, 0)) as total_deletes,
      SUM(COALESCE(stc.srcNumOfPkupdates, 0) + COALESCE(stc.tgtNumOfPkupdates, 0)) as total_pk_updates,
      SUM(COALESCE(stc.srcNumOfInserts, 0) + COALESCE(stc.tgtNumOfInserts, 0)) as total_inserts,
      COUNT(DISTINCT stc.sourceName) as distinct_tables
    FROM
      mon.striim_mon_table_comparison AS stc
    WHERE
      stc.batchdate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
      AND stc.appName IS NOT NULL
    GROUP BY
      stc.appName
  ),

  AppMetadata AS (
    SELECT
      abm.appName,
      abm.days_active,
      abm.last_seen,
      smtrh.clusterName,
      -- Enhanced CDC detection logic with table operation analysis
      CASE
        WHEN UPPER(abm.appName) LIKE '%ILA%' THEN FALSE
        WHEN UPPER(abm.appName) LIKE '%STRIIM_WATCHER%' THEN FALSE
        WHEN COALESCE(asti.database_reader_sources, 0) > 0 THEN FALSE
        WHEN COALESCE(atoi.total_updates, 0) > 0 OR COALESCE(atoi.total_deletes, 0) > 0 OR COALESCE(atoi.total_pk_updates, 0) > 0 THEN TRUE
        WHEN (abm.checkpoint_records::FLOAT / abm.total_records) > 0.5 AND abm.avg_input > 1000 AND abm.avg_output > 1000 THEN TRUE
        WHEN abm.avg_input > 1000 AND abm.avg_output > 1000 THEN TRUE
        ELSE FALSE
      END as is_likely_cdc_app,
      abm.avg_input,
      abm.avg_output,
      abm.checkpoint_records,
      abm.total_records,
      COALESCE(asti.database_reader_sources, 0) as database_reader_sources,
      COALESCE(asti.distinct_source_types, 0) as distinct_source_types,
      COALESCE(atoi.total_updates, 0) as total_updates,
      COALESCE(atoi.total_deletes, 0) as total_deletes,
      COALESCE(atoi.total_pk_updates, 0) as total_pk_updates,
      COALESCE(atoi.total_inserts, 0) as total_inserts,
      COALESCE(atoi.distinct_tables, 0) as distinct_tables
    FROM
      AppBasicMetrics abm
    LEFT JOIN AppSourceTypeInfo asti ON abm.appName = asti.appName
    LEFT JOIN AppTableOperationInfo atoi ON abm.appName = atoi.appName
    LEFT JOIN mon.striim_mon_table_runhistory smtrh ON smtrh.batchdate = abm.last_seen
  ),

  -- Step 6: Compare with existing thresholds and prepare UPSERT data
  ThresholdComparison AS (
    SELECT
      tc.change_threshold_pct,
      am.appName,
      am.clusterName,
      am.is_likely_cdc_app,
      am.days_active,
      am.last_seen,
      COALESCE(ta.suggested_terminated_threshold,
        CASE WHEN am.is_likely_cdc_app THEN tc.terminated_min_minutes ELSE tc.terminated_min_minutes * 2 END
      ) as new_terminated_threshold,
      COALESCE(ba.suggested_backpressure_threshold,
        CASE WHEN am.is_likely_cdc_app THEN tc.backpressure_min_minutes ELSE tc.backpressure_min_minutes * 2 END
      ) as new_backpressure_threshold,
      COALESCE(ca.suggested_checkpoint_threshold,
        CASE WHEN am.is_likely_cdc_app THEN tc.checkpoint_min_minutes ELSE tc.checkpoint_min_minutes * 3 END
      ) as new_checkpoint_threshold,
      COALESCE(la.suggested_lee_threshold,
        CASE WHEN am.is_likely_cdc_app THEN tc.lee_min_minutes ELSE tc.lee_min_minutes * 3 END
      ) as new_lee_threshold,
      CASE WHEN am.is_likely_cdc_app THEN tc.largebatches_min_bytes ELSE tc.largebatches_max_bytes END as new_largebatches_threshold,
      CASE WHEN am.is_likely_cdc_app THEN tc.queuedbatches_min_count ELSE tc.queuedbatches_max_count END as new_queuedbatches_threshold,
      CASE WHEN am.is_likely_cdc_app THEN tc.sourceidle_min_minutes ELSE tc.sourceidle_max_minutes END as new_sourceidle_threshold,
      existing.terminatedThresholdMinutes as current_terminated_threshold,
      existing.backpressureThresholdMinutes as current_backpressure_threshold,
      existing.checkpointNotProgressingThresholdMin as current_checkpoint_threshold,
      existing.avgLeeThresholdMinutes as current_lee_threshold,
      existing.maxBatchSizeBytes as current_largebatches_threshold,
      existing.maxQueuedBatchesOnTarget as current_queuedbatches_threshold,
      existing.sourceInactivityThresholdMinutes as current_sourceidle_threshold,
      existing.isEnabled as current_is_enabled,
      COALESCE(ta.downtime_events, 0) as historical_downtime_events,
      COALESCE(ta.max_downtime_minutes, 0) as max_historical_downtime_minutes,
      COALESCE(ba.backpressure_events, 0) as historical_backpressure_events,
      COALESCE(ca.checkpoint_events, 0) as historical_checkpoint_events,
      COALESCE(la.lee_measurements, 0) as historical_lee_measurements,
      CASE
        WHEN am.days_active >= 7 AND COALESCE(ta.downtime_events, 0) >= 3 THEN 'HIGH'
        WHEN am.days_active >= 3 AND COALESCE(ta.downtime_events, 0) >= 1 THEN 'MEDIUM'
        ELSE 'LOW'
      END as confidence_level,
      CASE WHEN existing.appName IS NULL THEN TRUE ELSE FALSE END as is_new_app
    FROM
      AppMetadata am
    CROSS JOIN ThresholdConfiguration tc
    LEFT JOIN TerminatedAppAnalysis ta ON am.appName = ta.appName
    LEFT JOIN BackpressureAnalysis ba ON am.appName = ba.appName
    LEFT JOIN CheckpointAnalysis ca ON am.appName = ca.appName
    LEFT JOIN LeeAnalysis la ON am.appName = la.appName
    LEFT JOIN mon.ApplicationAlertThresholds existing ON am.appName = existing.appName
    WHERE
      am.last_seen >= CURRENT_TIMESTAMP - INTERVAL '7 days'
  ),

  -- Step 7: Determine which thresholds need updating
  UpdateCandidates AS (
    SELECT
      *,
      CASE
        WHEN is_new_app THEN TRUE
        WHEN current_terminated_threshold IS NULL OR current_terminated_threshold = 0 THEN TRUE
        ELSE ABS(new_terminated_threshold - current_terminated_threshold)::FLOAT / current_terminated_threshold >= change_threshold_pct
      END as should_update_terminated,
      CASE
        WHEN is_new_app THEN TRUE
        WHEN current_backpressure_threshold IS NULL OR current_backpressure_threshold = 0 THEN TRUE
        ELSE ABS(new_backpressure_threshold - current_backpressure_threshold)::FLOAT / current_backpressure_threshold >= change_threshold_pct
      END as should_update_backpressure,
      CASE
        WHEN is_new_app THEN TRUE
        WHEN current_checkpoint_threshold IS NULL OR current_checkpoint_threshold = 0 THEN TRUE
        ELSE ABS(new_checkpoint_threshold - current_checkpoint_threshold)::FLOAT / current_checkpoint_threshold >= change_threshold_pct
      END as should_update_checkpoint,
      CASE
        WHEN is_new_app THEN TRUE
        WHEN current_lee_threshold IS NULL OR current_lee_threshold = 0 THEN TRUE
        ELSE ABS(new_lee_threshold - current_lee_threshold)::FLOAT / current_lee_threshold >= change_threshold_pct
      END as should_update_lee,
      CASE
        WHEN is_new_app THEN TRUE
        WHEN current_largebatches_threshold IS NULL OR current_largebatches_threshold = 0 THEN TRUE
        ELSE ABS(new_largebatches_threshold - current_largebatches_threshold)::FLOAT / current_largebatches_threshold >= change_threshold_pct
      END as should_update_largebatches,
      CASE
        WHEN is_new_app THEN TRUE
        WHEN current_queuedbatches_threshold IS NULL OR current_queuedbatches_threshold = 0 THEN TRUE
        ELSE ABS(new_queuedbatches_threshold - current_queuedbatches_threshold)::FLOAT / current_queuedbatches_threshold >= change_threshold_pct
      END as should_update_queuedbatches,
      CASE
        WHEN is_new_app THEN TRUE
        WHEN current_sourceidle_threshold IS NULL OR current_sourceidle_threshold = 0 THEN TRUE
        ELSE ABS(new_sourceidle_threshold - current_sourceidle_threshold)::FLOAT / current_sourceidle_threshold >= change_threshold_pct
      END as should_update_sourceidle
    FROM ThresholdComparison
  ),

  -- Step 8: Generate summary
  RecommendationSummary AS (
    SELECT
      appName,
      clusterName,
      is_likely_cdc_app,
      confidence_level,
      is_new_app,
      new_terminated_threshold,
      new_backpressure_threshold,
      new_checkpoint_threshold,
      new_lee_threshold,
      new_largebatches_threshold,
      new_queuedbatches_threshold,
      new_sourceidle_threshold,
      should_update_terminated,
      should_update_backpressure,
      should_update_checkpoint,
      should_update_lee,
      should_update_largebatches,
      should_update_queuedbatches,
      should_update_sourceidle,
      CASE
        WHEN is_new_app OR should_update_terminated OR should_update_backpressure
             OR should_update_checkpoint OR should_update_lee
             OR should_update_largebatches OR should_update_queuedbatches OR should_update_sourceidle THEN TRUE
        ELSE FALSE
      END as needs_update
    FROM UpdateCandidates
  )

  SELECT
    rs.appName,
    rs.clusterName,
    rs.is_likely_cdc_app,
    rs.new_terminated_threshold,
    rs.new_backpressure_threshold,
    rs.new_checkpoint_threshold,
    rs.new_lee_threshold,
    rs.new_largebatches_threshold,
    rs.new_queuedbatches_threshold,
    rs.new_sourceidle_threshold
  FROM RecommendationSummary rs
  WHERE rs.is_likely_cdc_app = TRUE
    AND rs.needs_update = TRUE
  ORDER BY
    rs.is_new_app DESC,
    rs.is_likely_cdc_app DESC,
    rs.confidence_level DESC,
    rs.appName;

  -- Get total count of apps to update
  SELECT COUNT(*) INTO v_total_apps FROM apps_to_update;

  -- Execute UPSERT for all apps that need updates
  FOR rec IN SELECT * FROM apps_to_update LOOP
    INSERT INTO mon.ApplicationAlertThresholds (
      id, appName, isCdcApp, terminatedCheckEnabled,
      terminatedThresholdMinutes, backpressureThresholdMinutes,
      checkpointNotProgressingThresholdMin, avgLeeThresholdMinutes,
      maxBatchSizeBytes, maxQueuedBatchesOnTarget, sourceInactivityThresholdMinutes,
      retainStaticValueFlag, isEnabled
    ) VALUES (
      gen_random_uuid()::TEXT, rec.appName, rec.is_likely_cdc_app, TRUE,
      rec.new_terminated_threshold, rec.new_backpressure_threshold,
      rec.new_checkpoint_threshold, rec.new_lee_threshold,
      rec.new_largebatches_threshold, rec.new_queuedbatches_threshold, rec.new_sourceidle_threshold,
      FALSE, TRUE
    )
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
       OR mon.ApplicationAlertThresholds.retainStaticValueFlag = FALSE;

    v_apps_updated := v_apps_updated + 1;
  END LOOP;

  -- Clean up temp table
  DROP TABLE IF EXISTS apps_to_update;

  -- Return summary
  RETURN QUERY SELECT
    v_apps_updated as apps_updated,
    v_total_apps as total_apps_analyzed,
    CURRENT_TIMESTAMP as execution_time,
    'Alert thresholds updated successfully'::TEXT as result_status;
END;
$$ LANGUAGE plpgsql;
