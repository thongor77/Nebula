# Core / Services

Non-visual runtime services: `NebulaAuthService`, `NebulaUserService`,
`NebulaSessionService`, `NebulaPowerService` (see
[`docs/Core-API.md`](../../docs/Core-API.md)). Each exposes a public contract
only and delegates to an `adapter` injected by the Platform layer
(`platform/sddm/`) — see
[`docs/Services-Architecture.md`](../../docs/Services-Architecture.md).

`NebulaThemeLoader` lives in `core/theme/`, not here — see
[`docs/Core-Implementation-Status.md`](../../docs/Core-Implementation-Status.md).
