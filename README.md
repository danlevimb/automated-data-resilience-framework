# Automated SQL Server Recovery Validation Framework
### A recoverable backup is the only good backup.

A SQL Server framework designed to **prove database recoverability**, not just assume it.

This project provides a deterministic and automated approach to validating **backup restore chains**, executing **point-in-time recovery (PITR)** scenarios, and generating **auditable recovery evidence** through restore telemetry and canary-based verification.

Instead of trusting that backups *should work*, this framework continuously verifies that they **actually do**.

---

# The Problem

In many environments, successful backups are treated as proof of recoverability.

Backup jobs run every night.  
Logs are generated.  
Alerts show **Success**.

Everything appears healthy.

Until the day a real restore is required.

That is when the real problems begin.

- **Broken restore chains** – Lack of traceability and validation of the transaction log restore sequence.
- **Uncertainty in point-in-time recovery** – Recovery procedures exist but are rarely tested to guarantee that PITR actually works.
- **No deterministic recovery validation** – Restore tests may complete successfully without proving that the database was restored to the intended logical state.
- **Lack of recovery telemetry** – Restore operations are rarely measured, leaving no data to estimate realistic recovery objectives (RTO/RPO).
- **Manual or inconsistent recovery testing** – Restore validation is performed ad-hoc instead of as a repeatable automated process.

These problems often remain invisible until a real production incident occurs.

---

# The Solution

This framework introduces an automated recovery validation system that:

- deterministically constructs restore chains
- executes controlled restore scenarios
- verifies logical recovery using canary records
- records execution telemetry
- generates auditable recovery evidence

By continuously validating restore capability, the framework transforms backup strategies from **assumed reliability** into **measurable recoverability**.

---

# Core Architecture

The framework is built around four core components.

| Component | Role |
|--------|--------|
| `cfg.usp_GetLatestBackupFiles` | **Restore Planner** – builds deterministic restore chains |
| `cfg.usp_RestorePointInTime` | **Restore Engine** – executes FULL / DIFF / LOG restores |
| `cfg.usp_ValidatePitrCanary` | **Validation Engine** – confirms logical correctness of recovery |
| `cfg.usp_RunRestoreTests` | **Orchestrator** – executes automated restore validation tests |

Together, these components provide a complete **restore validation pipeline**.

---

# Recovery Validation Workflow

The framework executes the following deterministic validation process:

1. Generate deterministic canary records
2. Create a marked transaction boundary
3. Produce required transaction log backups
4. Construct the restore chain
5. Execute FULL / DIFF / LOG restores
6. Apply `STOPAT` or `STOPBEFOREMARK`
7. Validate recovery using canary verification
8. Persist restore telemetry and evidence

This process converts restore validation from a **manual operation** into a **repeatable automated workflow**.

---

# Operational Capabilities

Although originally designed for restore validation, the framework enables additional operational capabilities:

### Recovery Validation
Proves that backups can be successfully restored.

### Recovery Automation
Enables restore operations to be executed programmatically through deterministic restore workflows.

### Recovery Observability
Captures restore telemetry to support operational analysis such as:

- restore duration trends
- recovery success rates
- recovery chain complexity
- estimated recovery times

This data can be used to refine and validate **Recovery Time Objectives (RTO)** and **Recovery Point Objectives (RPO)**.

---

# Example Execution

Example restore validation output:
- Processing database: AdventureWorks2022
- Creating PITR canaries
- Generating marked transaction
- Executing restore chain
- FULL restore completed
- DIFF restore completed
- LOG restore applied
- STOPAT applied successfully
- Validating canary records
- Validation result: PASSED

---

# Repository Structure

| Folder | Description |
|------|-------------|
| `docs/` | Architecture and framework documentation |
| `diagrams/` | Visual architecture diagrams |
| `sql/` | Database objects (tables, procedures, demos) |
| `examples/` | Execution outputs and validation evidence |

---

# Why This Matters

A successful backup does **not** guarantee recoverability.

Organizations frequently discover restore failures only during production incidents.

This framework demonstrates how to implement **continuous recovery validation** as part of a resilient data platform strategy.

Instead of assuming recoverability, this system **proves it**.

---

# Author

Dan Levi Menchaca Bedolla  
SQL Server Data Infrastructure & Reliability Engineer
