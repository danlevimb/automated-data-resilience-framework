<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a> |
<a href="../examples/examples.md">Examples</a>
</p>

# STOPAT Restore & Targeted Data Repair for User Incident

---

## Overview

This use case demonstrates a **real-world incident recovery scenario** involving:

- unintended bulk data modification  
- delayed incident detection  
- imprecise user-reported timing  
- continued system activity after corruption  
- point-in-time recovery using STOPAT  
- targeted data repair in production  

The objective is to:

- identify the last known valid state  
- restore a clean reference database  
- detect corrupted records  
- repair production data without full restore  

---

## Business Context

A data inconsistency was reported in the **Order Management System**, affecting financial values in the `app.Orders` table.

The issue originated from an unintended execution of a bulk update statement without a filtering condition.

The system continued normal operation after the incident, including:

- DMLs ocurring in high-rate transaction table.
- ON-LINE Backup Job-agents (LOGs every 15 minutes by policy)

This created a mixed dataset containing:

- corrupted historical records  
- valid new records  

---

## Incident Ticket

### 🎫 Incident ID: INC-2026-0413-ORDERS

**Date/Hour:** 13-Abr-26 12:25 p.m.  
**Environment:** Production  
**Service:** Order Management System  
**Reported by:** Business Operations  
**Severity:** High  

---

### Summary

Unexpected data corruption detected in order amounts affecting financial reporting.

---

### Detailed Description

The Business Operations team reported inconsistencies in order amounts within the production system.

Several records in the `app.Orders` table show incorrect values, impacting downstream processes and reporting accuracy.

---

### Suspected Root Cause

An unintended execution of a bulk update statement:

```sql
UPDATE app.Orders
SET Amount = 0;
```

### Detection Time

The issue was detected approximately 30–40 minutes after the incident occurred.

The user reported:

> “The issue may have happened around 11:00 AM.”

⚠️ This time is approximate and not reliable for recovery.

### Impact
- Financial data inconsistency
- Reporting inaccuracies
- Potential downstream system impact

### Requested Actions
   
1 - Identify last valid data state  
2 - Restore database to pre-incident point  
3 - Identify affected records  
4 - Perform controlled repair in production  
5 - Validate data consistency  

### Problem Statement

The exact time of the incident is unknown.

The system must determine:

    - when the data transitioned from valid to corrupted
    - how to identify the correct recovery point
    - how to restore without affecting valid post-incident data
    - how to repair production safely

### Recovery Strategy

A forensic, evidence-driven approach is used:

    1 - Define initial incident window  
    2 - Perform exploratory restores  
    3 - Identify GOOD vs BAD states  
    4 - Narrow the time boundary  
    5 - Determine optimal STOPAT  
    6 - Restore clean reference database  
    7 - Compare datasets  
    8 - Repair affected records  
    9 - Validate final state  

Execution Timeline (Actual Events)
| Time | Event |
|------|-------|
|10:20 |Last known good log backup |
|10:25 | Incident occurs (UPDATE without WHERE)|
|10:30 | New valid inserts occur|
|10:35 | Log backup captures incident|
|12:25 | Incident reported|

### Evidence — Mixed Dataset (Critical Insight)

Query showing corrupted values (Amount = 0)

```sql
SELECT TOP (50) *
FROM app.Orders
ORDER BY OrderCreatedAt DESC;
```
📸 [INSERT SCREENSHOT]

What we see:

- corrupted historical records
- valid new inserts
- OLD DATA → Amount = 0 ❌  
- NEW DATA → Amount correct ✅

### STOPAT Selection Methodology

STOPAT was not derived from user input.

Instead, it was determined using:

- exploratory restores
- GOOD vs BAD validation
- iterative narrowing (binary search approach)

### Exploratory Restore Process

Multiple restores were executed:

||
| STOPAT | Result | Evidence |
|---|---|---|
|10:50 | BAD | HERE |
|10:30 | BAD | HERE |
| 10:15 | GOOD | HERE |
|10:25 | Boundary |
|10:25:10 | Final precision |

📸 [INSERT SCREENSHOT]
Example restore execution

### Final STOPAT
`2026-04-13 10:25:10.500`

This represents the last known valid state before corruption.

### Restore Execution
```sql
EXEC cfg.usp_RestorePointInTime
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_StopAt',
    @StopAt = '2026-04-13 10:25:10.500',
    @DoCheckDB = 1,
    @ReplaceTarget = 1;
```
### Evidence — Restored Clean Data

📸 [INSERT SCREENSHOT]

```sql
SELECT TOP (50) *
FROM LabCriticalDB_StopAt.app.Orders
ORDER BY OrderCreatedAt DESC;
```

### Data Comparison (Production vs Restored)
```sql
SELECT 
    p.OrderID,
    p.Amount AS ProductionAmount,
    r.Amount AS RestoredAmount
FROM LabCriticalDB.app.Orders p
JOIN LabCriticalDB_StopAt.app.Orders r
    ON p.OrderID = r.OrderID
WHERE ISNULL(p.Amount,0) <> ISNULL(r.Amount,0);
```

📸 [INSERT SCREENSHOT]
Affected records comparison

Backup Before Repair
```sql
EXEC cfg.usp_BackupDatabase
    @DatabaseName = 'LabCriticalDB',
    @BackupType = 'LOG',
    @WithCompression = 1,
    @WithChecksum = 1;
```

📸 [INSERT SCREENSHOT]
Backup execution evidence

### Data Repair (Production)
```sql
BEGIN TRAN;

UPDATE p
SET p.Amount = r.Amount
FROM LabCriticalDB.app.Orders p
JOIN LabCriticalDB_StopAt.app.Orders r
    ON p.OrderID = r.OrderID
WHERE ISNULL(p.Amount,0) <> ISNULL(r.Amount,0);

SELECT @@ROWCOUNT AS RowsFixed;

COMMIT;
```

📸 [INSERT SCREENSHOT]
Rows affected during repair

### Final Validation
```sql
SELECT COUNT(*) AS RemainingDifferences
FROM LabCriticalDB.app.Orders p
JOIN LabCriticalDB_StopAt.app.Orders r
    ON p.OrderID = r.OrderID
WHERE ISNULL(p.Amount,0) <> ISNULL(r.Amount,0);
```

📸 [INSERT SCREENSHOT]
Expected result = 0

### Key Insights
    - User-reported time is unreliable
    - Log backups capture events independently of perception
    - Data corruption may coexist with valid data
    - STOPAT must be determined through evidence
    - Repair should be targeted, not destructive

### Summary

This use case demonstrates a complete incident recovery workflow:

forensic analysis
point-in-time recovery
data validation
targeted repair

It proves that backup systems must be complemented with deterministic recovery validation and repair strategies.

Final Outcome

   ✔ Incident successfully analyzed  
   ✔ STOPAT precisely identified  
   ✔ Data restored correctly  
   ✔ Production repaired safely  
   ✔ Data integrity fully restored  
