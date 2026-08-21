# Contributing to Rocom

## Edition Model

Rocom follows an Edition-based release model. Each Edition is a
coherent snapshot of all Parts at a given point in time.

| Identifier | Meaning |
|------------|---------|
| `2026a` | First edition of 2026 (draft) |
| `2026b` | Second edition of 2026 |
| `2027a` | First edition of 2027 |

Editions are lettered within a year. Once an Edition reaches
**STABLE**, no further changes are made to it — only to subsequent
Editions.

## Change Mechanisms

Three mechanisms exist for modifying a specification:

### Supplements (Sup-nnn)

A Supplement extends a Part without modifying its normative text.
Supplements add new capability declarations, deployment profiles,
or implementation guidance.

**When to use:** New robot platform profiles, regional deployment
profiles, implementation notes.

**Format:** `Sup-NNN — Title` (e.g., `Sup-001 — MiR Fleet Profile`)

**Process:**
1. Open issue with `[Sup]` prefix
2. Draft supplement as `spec/part-NN-<title>/sup-NNN.md`
3. PR against `main`
4. Sup number is assigned from `spec/cp-registry.md` — registry update
   is part of the same commit as the Sup content
5. Maintainer reviews and merges

**Numbering:** Numbers are assigned ONLY from `spec/cp-registry.md`.
The registry is authoritative.

### Correction Proposals (CP-nnn)

A Correction Proposal fixes errors, ambiguities, or inconsistencies
in normative text. CPs are applied to the current Edition and carried
forward to all subsequent Editions.

**When to use:** Typos, broken references, contradictory requirements,
missing MUST/SHALL modifiers.

**Format:** `CP-NNN — Brief description`

**Process:**
1. Open issue with `[CP]` prefix and cite the exact Part/requirement ID
2. PR with minimal diff — only the correction
3. CP number is assigned from `spec/cp-registry.md` — registry update
   is part of the same commit as the CP content
4. Maintainer reviews and merges

**Numbering:** Numbers are assigned ONLY from `spec/cp-registry.md`.
The registry is authoritative — commit messages may reference the wrong
number, but the registry entry stands.

### Full Part Revisions

A Part revision replaces the entire normative text of a Part. This
requires Editor approval and is tracked as a GitHub issue with
`[Revision]` prefix.

**When to use:** Architectural changes, new conformance levels,
fundamental re-structuring.

**Process:**
1. Open issue with `[Revision]` prefix
2. Discussion period: minimum 14 days
3. Draft published as `DRAFT` within the Part directory
4. Replaces existing text on Edition release

## Naming Conventions

| Artifact | Pattern | Example |
|----------|---------|---------|
| Part directory | `part-NN-<kebab-case>` | `part-04-services` |
| Supplement | `sup-NNN.md` | `sup-001.md` |
| Correction | Referenced in commit message | `CP-012` |
| Requirements | `<prefix>-req-NNN` | `dg-req-001`, `it-req-102` |
| Principles | `<prefix>-p-NNN` | `dg-p-001`, `it-p-003` |

## Git Identity

Commits to this repository use:

```
Name: Rocom Project
Email: specs@techhappens.eu
```

Set locally:
```bash
git config user.name "Rocom Project"
git config user.email "specs@techhappens.eu"
```

## Review Process

1. All PRs require at least one review from a maintainer.
2. Normative text changes MUST cite the affected Part and requirement IDs.
3. Supplements and CPs are merged by maintainers; full revisions require
   Editor approval (tracked as issue).

## Scope

This repository contains the normative specification. The following are
out of scope:

- Product implementations (see respective vendor repositories)
- HRRM product API documentation (maintained separately)
- Marketing materials or presentations

For questions about conformance or certification, see GOVERNANCE.md.
