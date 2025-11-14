-- Table: striim_mon_lee
-- Purpose: Tracks Lag End-to-End (LEE) metrics for source-target pairs
-- Dependencies: striim_mon_table_runhistory (batchdate FK)
-- Description: Records latency measurements between sources and targets including min/max/avg LEE

CREATE OR REPLACE TABLE `striim_watcher_metadata.striim_mon_lee` (
    monleeid INT64 OPTIONS (
        DESCRIPTION="A unique bigint value for PK of the row."
    ),
    batchdate TIMESTAMP OPTIONS (
        DESCRIPTION="A FK reference to runtime in striim_mon_table_runhistory table, datetime of when this batch was run."
    ),
    sourceApp STRING OPTIONS (
        DESCRIPTION="(If detectable) The App name related to the Type. App name is not provided in the Lee report; however, by using the sourceName, we can attempt to find the App."
    ),
    sourceName STRING OPTIONS (
        DESCRIPTION="The Source Name as reported by the Lee report."
    ),
    sourceType STRING OPTIONS (
        DESCRIPTION="The Source Type as reported by the Lee report."
    ),
    targetApp STRING OPTIONS (
        DESCRIPTION="(If detectable) The App name related to the Type. App name is not provided in the Lee report; however, by using the targetName, we can attempt to find the App."
    ),
    targetName STRING OPTIONS (
        DESCRIPTION="The Target Name as reported by the Lee report."
    ),
    targetType STRING OPTIONS (
        DESCRIPTION="The Target Type as reported by the Lee report."
    ),
    lagEndToEnd NUMERIC OPTIONS (
        DESCRIPTION="The currently measured LAG returned from lee;"
    ),
    measuredAt TIMESTAMP OPTIONS (
        DESCRIPTION="The time the lag was measured at."
    ),
    sourceTime STRING OPTIONS (
        DESCRIPTION="The source time returned by report lee;"
    ),
    minLEE NUMERIC OPTIONS (
        DESCRIPTION="The min lee reported by lee. This represents the fastest end-to-end record creation and delivery, from the samplesize provided."
    ),
    maxLEE NUMERIC OPTIONS (
        DESCRIPTION="The max lee reported by lee. This represents the slowest end-to-end record creation and delivery, from the samplesize provided."
    ),
    avgLEE NUMERIC OPTIONS (
        DESCRIPTION="The average lee reported by lee. Based on the sample size, this represents the average time for the end-to-end record creation and delivery, from the samplesize."
    ),
    sampleSize INT OPTIONS (
        DESCRIPTION="The sample size used to calculate the lee statistics."
    ),
    PRIMARY KEY (monleeid) NOT ENFORCED
)
OPTIONS (
    DESCRIPTION="Tracks Lag End-to-End (LEE) metrics for source-target pairs"
);
