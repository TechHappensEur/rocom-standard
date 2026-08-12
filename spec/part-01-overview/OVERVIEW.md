# FILE: spec/part-01-overview/OVERVIEW.md
# =====================================================================
# Rocom — Part 1: Overview and Scope
# Status: DRAFT 0.1 (2026-08-12) — Edition 2026a (draft)
# License: CC-BY 4.0 (see LICENSE-SPEC)
# =====================================================================

# 1. Purpose

Rocom is an open, vendor-neutral specification for integrating
heterogeneous robot fleets with enterprise orchestration systems. It
defines the protocol bindings, service contracts, security requirements,
and data governance controls that enable any conformant robot to
interoperate with any conformant orchestrator.

The target domain is healthcare logistics — but the architecture is
domain-agnostic.

# 2. Terminology

**orchestrator** — The system implementing the orchestration layer;
responsible for task allocation, the agent registry, and the audit
trail. This standard does not prescribe a specific orchestrator
implementation.

**agent** — Any entity that can be allocated tasks: human staff members,
robots, or human-in-the-loop operator stations (cockpit).

**convergence layer** — The IT/OT boundary crossing point where robot
fleet data (OT zone) meets enterprise systems (IT zone). All cross-zone
data flow passes through the convergence layer (see Part 7, dg-p-001).

**conformance level** — A tiered set of requirements (L1 through L3)
that allows incremental adoption. A system conforming to L2 satisfies
all L1 requirements.

# 3. Architecture — The Five Rings

```
          +----------------------------------+
          |        Ring 5: Governance        |
          |  (data governance, audit, CRA)   |
          +----------------------------------+
                    |
          +----------------------------------+
          |      Ring 4: Identity & Trust    |
          |  (NHI, X.509, SPIFFE, mTLS)     |
          +----------------------------------+
                    |
          +----------------------------------+
          |   Ring 3: Service Contracts      |
          |  (availability, task-source, ...) |
          +----------------------------------+
                    |
          +----------------------------------+
          |     Ring 2: Transport Profile    |
          |  (VDA 5050 binding, MQTT, ...)   |
          +----------------------------------+
                    |
          +----------------------------------+
          |      Ring 1: Fleet Binding       |
          |  (VDA 5050 core, factsheet, ...) |
          +----------------------------------+
                    |
              [ Robot Fleet / OT Zone ]
```

Each ring maps to a Part of this specification. Rings are dependency-ordered:
Ring N requires Rings 1 through N-1.

# 4. IT/OT Zone Model

```
  +------------------+    +-------------------+    +------------------+
  |    IT Zone       |    |  Convergence      |    |    OT Zone       |
  |                  |    |  Layer            |    |                  |
  |  HR Systems      |◄──►|  Rocom Gateway    |◄──►|  Robot Fleet     |
  |  Turnus/Columna  |    |  (mTLS, VDA 5050) |    |  (VDA 5050      |
  |  Workday         |    |                   |    |   compliant)     |
  |  Task Sources    |    |  Audit Trail      |    |  Vendor Systems  |
  |  Enterprise ERP  |    |  Data Governance  |    |  BMS/Access Ctrl |
  +------------------+    +-------------------+    +------------------+
```

- **OT Zone:** Robot fleet, vendor systems, BMS, access control. Data
  generated here includes operational telemetry, diagnostics, and sensor
  payloads.
- **Convergence Layer:** The only sanctioned crossing point. Enforces
  protocol binding (Part 5), identity verification (Part 6), data
  classification (Part 7), and audit logging.
- **IT Zone:** Enterprise systems, HR platforms, task sources. Receives
  only operational telemetry and authorized data classes.

# 5. Partner Planes

The specification defines four contract planes:

| Plane | Role | Specification Part |
|-------|------|--------------------|
| 1 — BMS Infrastructure | Building Management Systems (access control, elevators) | Part 2 |
| 2 — Robot Vendor | Rocom-conformant robot platforms | Part 5 |
| 3 — Availability Provider | HR/turnus systems providing agent availability | Part 4 |
| 4 — Task Source | Enterprise systems generating tasks | Part 4 |

# 6. Specification Parts

| Part | Title | Scope |
|------|-------|-------|
| 1 | Overview and Scope | Architecture, terminology, zone model |
| 2 | Protocol Bindings | VDA 5050 binding with Rocom extensions |
| 3 | Messaging and Transport | (reserved) |
| 4 | Service Contracts | Availability provider, task source interfaces |
| 5 | Transport Profile | Capability registry, healthcare extensions |
| 6 | Security | Machine identity, trust, mTLS |
| 7 | Data Governance | Data classification, egress control, Art. 30 |

# 7. Conformance

A system claiming Rocom conformance MUST declare its conformance level
(L1, L2, or L3) per Part, and satisfy all requirements at that level
and below. Partial conformance within a Part is permitted; the system
MUST document which requirements are not met.

Formal certification is defined separately (see the Rocom Certification
Program).
