# Scripts

Utility scripts for the project:

| Script                      | Purpose                                                  |
| ---------------------------- | --------------------------------------------------------- |
| `install-nebula.sh`          | Install Nebula (Core + a theme) on a real system, idempotent |
| `uninstall-nebula.sh`        | Remove only what Nebula installed (`.nebula-managed` marker) |
| `check-installation.sh`      | Verify an install without ever modifying the system        |
| `check-theme.sh`             | Validate a theme's static structure against the SDK contract |
| `check-design-system.sh`     | Single pre-commit entry point: `qmllint` + `ThemeSyncCheck` + visual harnesses |

See [`docs/Installation.md`](../docs/Installation.md) and
[`docs/Packaging.md`](../docs/Packaging.md) for the full usage of the
install/uninstall/check scripts.
