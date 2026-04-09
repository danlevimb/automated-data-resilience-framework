<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a>
</p>

# Canary-Based Recovery Validation Model

## Overview

The framework implements a **canary-based validation model** to verify the correctness of point-in-time recovery operations.

Instead of assuming that a restore operation is successful based solely on execution status, this model introduces **data-level verification** using controlled markers within the transaction log.

This approach transforms recovery from a technical process into a **deterministic and verifiable outcome**.

---

## Conceptual Foundation

The canary validation model is based on a simple but powerful principle:

> A recovery operation is only valid if the resulting data state matches the intended recovery boundary.

To achieve this, the framework introduces **controlled data artifacts** (canaries) that act as reference points before and after the recovery boundary.

---

## Model Definition

The validation model consists of three controlled events:

| Event | Description |
|------|------------|
| BEFORE | Record inserted before the recovery boundary |
| MARK | Named transaction marker used as recovery reference |
| AFTER | Record inserted after the recovery boundary |

---

## Recovery Expectation

When performing a restore using `STOPBEFOREMARK`, the expected state is:

```text
               BEFORE       MARK       AFTER
SOURCE           1           1           1
TARGET           1           0           0
