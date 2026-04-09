<p align="center">
<a href="../README.md">Home</a> |
<a href="scheduler-behavior.md">Back</a>
</p>

# Scenario 2 — LOG Backup Due
### Transaction log frequency has been exceeded.

### 🔍 Evidence
Decision matrix showing:
  - `LogDue = 1`
  - `SelectedBackupType = LOG`
  - `DecisionReason = 'LOG frequency reached'`

<p align="center">
  <img src="../../docs/evidence/images/Scenario2_LOGBackupDue.jpg" width="900">
</p>

### Interpretation
  - LOG backups are triggered precisely when required
  - Frequency is respected per Tier configuration
  - RPO enforcement is consistent
