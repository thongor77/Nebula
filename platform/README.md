# Platform

Concrete, backend-specific adapters — the only code allowed to talk
directly to a real display-manager API. Sits alongside `core/` and
`themes/` as a third, distinct concern: `core/` is reusable abstractions
(components + services), `themes/` is visual identity, `platform/` is
backend bindings.

Not Nebula-prefixed (unlike `core/`) — see
[`docs/Decisions-Techniques.md`](../docs/Decisions-Techniques.md), DT-0010.

Currently: [`sddm/`](sddm/) only. Supporting a second display manager is
explicitly not a current goal — this directory exists to keep `core/`
decoupled from SDDM specifically, not to prepare for hypothetical other
backends (see [`docs/Services-Architecture.md`](../docs/Services-Architecture.md)).
