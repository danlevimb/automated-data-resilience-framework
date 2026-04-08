<p align="center">
<a href="../../README.md">Home</a> |
<a href="../examples/examples.md">Examples</a>
</p>

# Backup Execution Evidence

This section provides real execution evidence of the framework operating under a **policy-driven scheduling model**.

The objective is to demonstrate that backup operations are:

- Dynamically determined at runtime  
- Executed according to defined policies  
- Properly recorded in telemetry  
- Consistent with expected operational cadence  

---

# Scenario

## Policy Configuration

- Tier 0 (Critical)
  - FULL: Daily  
  - DIFF: Every 4 hours  
  - LOG: Every 15 minutes  

- Scheduler:
  - SQL Server Agent Job executes every **5 minutes**

---

# Step 1 — Decision Engine (Dry Run)

Execute the scheduler in validation mode:

```sql
EXEC cfg.usp_RunScheduledBackups
    @DryRun = 1,
    @Debug = 1;
