# EventChanger Open Processor

A Striim Open Processor for transforming CDC (Change Data Capture) events by filtering columns, adding metadata columns, and generating DDL events for downstream targets.

## Table of Contents
- [Overview](#overview)
- [Installation](#installation)
- [Properties](#properties)
- [Property Details](#property-details)
- [Example TQL](#example-tql)
- [Output Event Structure](#output-event-structure)
- [Troubleshooting](#troubleshooting)

## Overview

EventChanger allows you to:
- **Filter columns** - Select only the columns you need from source events
- **Add metadata columns** - Inject event metadata (like OperationName, Timestamp) as new data columns
- **Generate DDL events** - Automatically send CREATE TABLE DDL events when new tables are detected
- **Skip unchanged updates** - Optionally skip UPDATE events where no interesting columns changed

## Installation

### Deploy in Striim
1. Upload the JAR to your Striim server
2. Load in Console: `LOAD 'UploadedFiles/EventChanger-5.2.0.jar';`

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `IncludedColumns` | String | Yes | `""` | Comma-separated list of column names to include. Use `*`, `%`, or empty string to include all columns. |
| `SendDDLEvents` | Boolean | No | `true` | Send CREATE TABLE DDL events when new tables are detected. |
| `SkipUpdatesForUninterestedColumns` | Boolean | No | `false` | Skip UPDATE events if none of the included columns changed. |
| `MetadataColumnMap` | String | No | `""` | Map metadata fields to new data columns. Format: `ColName=MetadataKey,...` |

## Property Details

### IncludedColumns

Filters the event to only include specified columns. Modifies both the data payload and DDL metadata.

```
IncludedColumns: 'EmployeeID,FirstName,LastName'
```

**To include ALL columns (no filtering):**
```
IncludedColumns: '*'    -- or '%' or ''
```

**Notes:**
- Column names are case-insensitive
- A new type is created with only the specified columns
- Primary key columns are preserved in DDL metadata
- Use `*`, `%`, or empty string (`""`) to include all columns (no filtering)

### SendDDLEvents

Controls whether CREATE TABLE DDL events are generated for new tables.

```
SendDDLEvents: true
```

**Notes:**
- DDL events are sent once per table, the first time a row is seen
- DDL events include `CDDLMetadata` with full column definitions
- Required for targets (like databases) that need schema information

### SkipUpdatesForUninterestedColumns

Optimizes UPDATE event processing by skipping events where only non-included columns changed.

```
SkipUpdatesForUninterestedColumns: true
```

**Notes:**
- Only applies to UPDATE operations
- Compares `data` (after) and `before` arrays to detect changes
- Reduces unnecessary updates when source has frequently updated columns you don't need

### MetadataColumnMap

Adds event metadata values as new data columns. Useful for capturing operation type, timestamps, or other metadata in your target.

```
MetadataColumnMap: 'TT=OperationName,TS=Timestamp'
```

**Format:** `NewColumnName=MetadataKey,AnotherColumn=AnotherKey`

**Common metadata keys:**
| Key | Description |
|-----|-------------|
| `OperationName` | CDC operation (INSERT, UPDATE, DELETE) |
| `Timestamp` | Event timestamp |
| `TableName` | Source table name |
| `SchemaName` | Source schema name |
| `TxnID` | Transaction ID (if available) |

**Notes:**
- New columns are appended to the end of the event data
- Column types are auto-detected based on value type
- Leave empty (`""`) to skip metadata column injection

## Example TQL

```sql
CREATE OR REPLACE APPLICATION CDCPipelineExample;

-- Source: Read from SQL Server
CREATE OR REPLACE SOURCE SQLSource USING Global.DatabaseReader (
  Password: 'mypassword',
  ConnectionURL: 'jdbc:sqlserver://localhost:1433;DatabaseName=mydb',
  Username: 'sa',
  DatabaseProviderType: 'SQLServer',
  Tables: 'dbo.EmployeeDetails',
  FetchSize: 100
)
OUTPUT TO SourceOutput;

-- Define output stream
CREATE STREAM ProcessedOutput OF Global.WAEvent;

-- Processor: Filter columns and add operation type column
CREATE OR REPLACE OPEN PROCESSOR TransformEvents USING Global.EventChanger (
  IncludedColumns: 'EmployeeID,FirstName,LastName,Email',
  SendDDLEvents: true,
  SkipUpdatesForUninterestedColumns: true,
  MetadataColumnMap: 'TT=OperationName,TS=Timestamp'
)
INPUT FROM SourceOutput
OUTPUT TO ProcessedOutput;

-- Target: Write to JSON files
CREATE OR REPLACE TARGET FileOutput USING Global.FileWriter (
  filename: 'cdc_output',
  flushpolicy: 'Interval:5s',
  rolloverpolicy: 'Interval:5s'
)
FORMAT USING Global.JSONFormatter (
  EventsAsArrayOfJsonObjects: 'true',
  jsonobjectdelimiter: '\n'
)
INPUT FROM ProcessedOutput;

END APPLICATION CDCPipelineExample;
```

### Minimal Example (Column Filtering Only)

```sql
CREATE OR REPLACE OPEN PROCESSOR FilterColumns USING Global.EventChanger (
  IncludedColumns: 'ID,Name,Email'
)
INPUT FROM SourceStream
OUTPUT TO FilteredStream;
```

### Example with Metadata Columns (All Columns + Metadata)

```sql
CREATE OR REPLACE OPEN PROCESSOR AddOpType USING Global.EventChanger (
  IncludedColumns: '*',
  MetadataColumnMap: 'OP_TYPE=OperationName,EVENT_TIME=Timestamp,SRC_TABLE=TableName'
)
INPUT FROM SourceStream
OUTPUT TO EnrichedStream;
```

This example includes ALL source columns and appends 3 metadata columns: `OP_TYPE`, `EVENT_TIME`, and `SRC_TABLE`.

## Output Event Structure

After processing, events will have:

| Field | Description |
|-------|-------------|
| `data[]` | Array with only included columns, plus metadata columns appended |
| `before[]` | For UPDATE/DELETE, before-image with same structure |
| `metadata` | Original metadata preserved, plus `CDDLMetadata` for DDL events |
| `typeUUID` | Points to dynamically created type matching filtered schema |

## Troubleshooting

### Enable Debug Logging

Run in Striim Console:
```
set loglevel = {com.striim.util.EventChanger: debug};
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Columns not appearing | Check column names are spelled correctly (case-insensitive) |
| No DDL events | Ensure `SendDDLEvents: true` |
| Metadata columns empty | Verify metadata key names match exactly (case-sensitive) |
| Updates not being skipped | Ensure `SkipUpdatesForUninterestedColumns: true` |

### Debug Log Messages

The processor logs detailed information at debug level:
- Property parsing and validation
- Column filtering decisions
- Metadata column injection
- DDL event generation
- Skip decisions for unchanged updates
