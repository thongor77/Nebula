# Tests

Test suite for Core components (`core/`). Introduced during the
architecture review to close a real gap: no testing strategy existed
before.

Each Core component's Definition of Done requires a minimal test in this
directory — see
[`docs/Specifications-Techniques.md`](../docs/Specifications-Techniques.md).

The concrete automated test framework (QML `TestCase` via `QtTest`, or
another approach) is still not chosen. `ButtonHarness.qml` is a manual
**visual** harness, not an automated test — run it with
`qml6 tests/ButtonHarness.qml` and inspect the result (see
[`docs/Core-Implementation-Status.md`](../docs/Core-Implementation-Status.md)
for what was verified this way). It should be replaced or complemented by
a real automated test once the framework decision is made.
