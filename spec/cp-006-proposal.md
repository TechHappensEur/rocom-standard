# CP-006 Forslag — CostModel Generalisering

## Problem

`cost_model` i Part 3 og Part 4 inneholder felt som lekker
overenskomstregler til den åpne spesifikasjonen:

- `overtime_multiplier` — spesifikk kollektivavtale-semantikk
- `constraints` — "Collective agreement rules, skill requirements"

Dette er forretningslogikk som tilhører den lukkede allokeringsmotoren,
ikke den åpne standarden.

## Forslag

Erstat med nøytral `cost_factors`-struktur:

```yaml
# Before
cost_model:
  base_cost_per_minute: ...
  overtime_multiplier: ...       # ← overenskomstspesifikk
  min_engagement_minutes: ...
  constraints: ...               # ← kollektivavtale regler

# After
cost_model:
  base_cost_per_minute: ...
  min_engagement_minutes: ...
  cost_factors:                  # ← nøytral array
    type: array
    items: object
    description: >
      Arbitrary cost modifiers (e.g., time-of-day,
      location-based, regulatory). Structure is
      implementation-defined.
    properties:
      factor_id: "String — identifier for this factor"
      weight: "Float — multiplicative weight"
      applies_when: "String — human-readable condition"
```

## Migrasjonsnote

- Eksisterende `overtime_multiplier` → `cost_factors` element med
  `factor_id: "overtime"`, `applies_when: "outside availability windows"`
- Eksisterende `constraints` → flyttes til lukket allokeringsmotor
  (ikke del av åpen standard)
- Bakoverkompatibel: `cost_factors` er optional; eksisterende klienter
  som bruker `base_cost_per_minute` + `min_engagement_minutes` er upåvirket

## Status

AVVENTER Egils ja før utførelse.
