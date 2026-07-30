# Tests

Test suite for Core components (`core/`). Introduced during the
architecture review to close a real gap: no testing strategy existed
before.

Empty until Phase 1 (Core MVP) — see
[`docs/Roadmap.md`](../docs/Roadmap.md). Each Core component's Definition
of Done requires a minimal test in this directory — see
[`docs/Specifications-Techniques.md`](../docs/Specifications-Techniques.md).

The concrete test framework (QML `TestCase` via `QtTest`, or another
approach) is not chosen yet — to be validated alongside the Phase 0
prototypes.
