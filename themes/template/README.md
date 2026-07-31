# Template

Neutral base theme — not meant to be used as-is. Copy this whole
directory to start a new Nebula theme (see
[`../../docs/Creating-A-Theme.md`](../../docs/Creating-A-Theme.md)).

- `theme.conf` ships the exact same values as `NebulaThemeConfig`'s own
  neutral fallback (see `docs/Theme-System.md` §5) — a starting point,
  not an identity. Change what your theme actually needs; leave the rest.
- `Main.qml` assembles only the Core components that exist today
  (Background/Wallpaper/Overlay/LoginLayout/Surface/Avatar/Clock/Date/
  Button) — no username input or password field yet, see
  `docs/Roadmap.md`.
- `assets/wallpapers/`, `assets/icons/`, `assets/fonts/` are empty —
  reserved folders for your theme's own assets (see `docs/Theme-SDK.md`
  §3). Shared assets belong in `core/assets/`, never copied here.
- `preview.png` is a placeholder — replace with a real screenshot once
  your theme has one.

Full contract (what a theme may/must never do): see
[`../../docs/Theme-SDK.md`](../../docs/Theme-SDK.md).
