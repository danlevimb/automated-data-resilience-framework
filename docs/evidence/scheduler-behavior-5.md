<p align="center">
<a href="../README.md">Home</a> |
<a href="scheduler-behavior.md">Back</a>
</p>

# Scenario 5 — Recovery Model Constraint
### Database is configured with SIMPLE recovery model.

### 🔍 Evidence
  - `recovery_model_desc = SIMPLE`
  - `SelectedBackupType = NULL`

<p align="center">
  <img src="../../docs/evidence/images/Scenario5_RecoveryModelConstraint.jpg" width="900">
</p>

### Interpretation
  - LOG backups are correctly skipped
  - Recovery model rules are enforced
  - No invalid operations are attempted
