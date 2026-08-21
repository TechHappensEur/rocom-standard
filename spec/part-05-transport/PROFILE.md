# FILE: specs/rocom-profile/PROFILE.md
# Rocom Healthcare Profile — Normative Specification v0.1

## 1. Scope

This profile defines the requirements a robot system MUST satisfy to be
considered Rocom-conformant. It extends the VDA 5050 standard by adding
healthcare-specific capability declarations, compliance event reporting,
and chain-of-custody tracking on `rocom/v0/` extension topics.

Standard VDA 5050 messages are never modified.

## 1.1 Normative References

This profile is based on **VDA 5050 version 2.1** (VDA 5050-2, Release 2.1, 2023).
All references to "VDA 5050" in this profile refer to this specific version unless
explicitly stated otherwise.

The VDA 5050 topic namespace `vda5050/` and message schemas defined in VDA 5050 v2.1
are used without modification. Rocom extensions use the separate `rocom/v0/` namespace.

## 2. Conformance Levels

### Level 1 — VDA 5050 Baseline
The system SHALL:
- [P-2.1.1] Publish a valid factsheet on `vda5050/factsheet` on connection.
- [P-2.1.2] Publish periodic state updates on `vda5050/state/<serialNumber>`.
- [P-2.1.3] Accept orders on `vda5050/order/<serialNumber>` and execute node sequences.
- [P-2.1.4] Publish connection state on `vda5050/connection/<serialNumber>`.
- [P-2.1.5] Support order cancellation on `vda5050/cancel/<serialNumber>`.

### Level 2 — Rocom Core
The system SHALL additionally:
- [P-2.2.1] Publish compliance events on `rocom/v0/compliance/event` on every zone transition.
- [P-2.2.2] Each compliance event MUST include `auditCorrelationId` referencing the orchestrator AuditEvent.
- [P-2.2.3] Declare Rocom-profile capabilities on `rocom/v0/capability/declare` using keys from the capability registry.
- [P-2.2.4] Report `complianceStatus` as `passed`, `failed`, or `exception` for each zone transition.

### Level 3 — Rocom Healthcare
The system SHALL additionally:
- [P-2.3.1] Publish chain-of-custody events on `rocom/v0/chainOfCustody/event` for tasks requiring chain-of-custody (`chainOfCustody: true` in capability params).
- [P-2.3.2] Enforce restricted-zone access: robot MUST publish a `restricted_zone_check` compliance event before entering a restricted zone, and SHALL NOT proceed if `complianceStatus` is `failed`.
- [P-2.3.3] Ensure chain-of-custody event completeness: every `picked_up` action MUST have a corresponding `delivered` or `handed_off` action within the task lifetime.
- [P-2.3.4] Capability declarations MUST match a key defined in `capability-registry.yaml`. Undeclared keys SHALL cause a conformance test failure.

## 3. Capability Declaration

Every conformant robot SHALL publish a capability declaration containing:
- `key`: one of the keys defined in the capability registry
- `level`: `basic`, `advanced`, or `certified`
- `certified`: boolean indicating whether the capability has passed certification testing

## 4. Audit Correlation

Every compliance and chain-of-custody event MUST carry an `auditCorrelationId`
that references the corresponding orchestrator `AuditEvent.eventId`. This ensures
the end-to-end audit trail from allocation decision through physical execution.

## 5. Restricted Zone Enforcement

When a task requires capability with `restricted_zones: true`:
1. The orchestrator SHALL include zone restriction constraints in the allocation proposal.
2. The gateway SHALL verify zone access before dispatching the order.
3. The robot SHALL publish a `restricted_zone_check` compliance event upon zone boundary crossing.
4. If access is denied, the robot SHALL NOT enter and SHALL transition to ERROR state.

## 6. Error Handling

- [P-6.1] A robot detecting a compliance failure SHALL publish a state update with `state: ERROR` and the corresponding compliance event with `complianceStatus: failed`.
- [P-6.2] The gateway SHALL notify the orchestrator of the compliance failure via the `/agents/{agentId}` PATCH endpoint.
- [P-6.3] The orchestrator SHALL record the failure in the audit trail and mark the task as `cancelled`.
