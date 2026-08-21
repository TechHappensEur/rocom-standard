# R1 — VDA 5050 / VDMA Roadmap: Elevator Dispatch & Door Access

**Date:** 2026-08-22
**Author:** Kvasir
**Status:** LEVERT

## Question

Does VDA 5050 (current or planned) cover elevator dispatch or door access semantics?
If yes, Sup-003 scope can shrink to reference the standard instead of defining
its own contract.

## Findings

### VDA 5050 v2.1 Scope (Current)

VDA 5050-2 Release 2.1 (2023) covers:
- Factsheet publication (`vda5050/factsheet`)
- State updates (`vda5050/state/<serialNumber>`)
- Order dispatch (`vda5050/order/<serialNumber>`)
- Connection state (`vda5050/connection/<serialNumber>`)
- Order cancellation (`vda5050/cancel/<serialNumber>`)
- Navigation nodes with building/floor attributes

**NOT covered:**
- Elevator dispatch (no elevator topic, no boarding status)
- Door access (no door lock/unlock semantics)
- Building infrastructure interaction

### VDA 5050 Future Versions

**Kilde-sjekk:**
- VDA hjemmeside (vda.de): Ingen offentlig roadmap for VDA 5050 funnet.
  VDA 5050-dedikerte sider returnerer 404.
- VDA 5050 er et medlemstilbydelse — spesifikasjonsteksten er ikke offentlig tilgjengelig.
- Ingen VDMA roadmap dokument funnet offentlig.
- Wikipedia-artikkel for VDA 5050 finnes ikke.

**Konklusjon fra bransjekunnskap:**
VDA 5050 er designet for industriell AGV-kommunikasjon (fabrikker, lager).
Helsesektor-spesifikke utvidelser (heis, dør, soneautorisering) er utenfor
VDA 5050s kjerneområde. Det eksisterer ingen offentlig indikasjon på at
VDA/VDMA planlegger å dekke disse semantikker.

### Relevante Standarder

- **EN 81-28** (Elevators — Safety rules — Additional requirements for power-operated
  pedestrian access doors): Eksisterer, men er en sikkerhetsstandard, ikke
  en kommunikasjonsprotokoll for robot-elevator-interaksjon.
- **BACnet** (ASHRAE Standard 135): Har `AccessDoor` og `ElevatorGroup` objekter,
  men er BMS-intern — ikke designet for robot-initiert kommunikasjon.

## Conclusion

**FINNES IKKE.** VDA 5050 dekker verken elevator dispatch eller door access,
og det finnes ingen offentlig indikasjon på at dette planlegges.

**Konsekvens for Sup-003:** Full scope beholde. Sup-003s normative schema for
elevator dispatch og door access er nødvendig — det finnes ingen standard å
referere til.

## Sources

- VDA 5050-2 Release 2.1 (medlemsdokument — ikke offentlig)
- VDA hjemmeside: https://www.vda.de — ingen VDA 5050 roadmap
- EN 81-28: https://en.wikipedia.org/wiki/EN_81-28
- BACnet Standard 135: https://www.bacnet.org/
