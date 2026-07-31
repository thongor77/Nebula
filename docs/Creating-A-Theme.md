# Creating a Theme — Nebula

> Practical, step-by-step guide for a new contributor building a Nebula
> theme. This document explains **how**; it never repeats the rules —
> for what a theme is allowed or forbidden to do, its structure, naming
> conventions, and reserved folders, see the normative reference:
> [`Theme-SDK.md`](Theme-SDK.md). Read that document first.

---

## 1. Before you start

- Read [`Theme-SDK.md`](Theme-SDK.md) in full — this guide assumes you
  already know what a theme may and must never do.
- Set up your local environment: see
  [`Development-Environment.md`](Development-Environment.md) (SDDM test
  tools, `qmllint`).

## 2. Start from the Template

Copy [`themes/template/`](../themes/template/) to a new directory named
after your theme (lowercase, no space — see `Theme-SDK.md` §3):

```bash
cp -r themes/template themes/mytheme
```

You now have `README.md`, `metadata.desktop`, `theme.conf`, `Main.qml`,
`preview.png`, and empty `assets/{wallpapers,icons,fonts}/`.

## 3. Give it an identity: `theme.conf`

Open `themes/mytheme/theme.conf`. It ships with the exact same neutral
values as the Core's own fallback — change only what your theme's
identity actually needs. Every key must already exist in
[`Design-Tokens-Reference.md`](Design-Tokens-Reference.md); if you need a
value the Design System doesn't have yet, that's a Core discussion first
(see `Theme-SDK.md` §4), never an invented local key.

## 4. Lay out your screen: `Main.qml`

`Main.qml` assembles Core components — it never copies or modifies one
(see `Theme-SDK.md` §4). The Template's own `Main.qml` already shows the
real wiring (Services backed by `platform/sddm/` adapters, tokens applied
from `theme.conf`) — adjust the composition (which components, their
layout inside `NebulaLoginLayout`'s zones) to match your theme's visual
identity, but keep that wiring pattern.

See [`Core-API.md`](Core-API.md) for every component's contract.

## 5. Add your assets

Put wallpapers, icons, and fonts under `assets/wallpapers/`,
`assets/icons/`, `assets/fonts/` respectively — no other folder is
recognized (see `Theme-SDK.md` §3). Reference them from `Main.qml` with a
path relative to your theme's own directory. Replace `preview.png` with
an actual screenshot once your theme has something to show.

## 6. Fill in metadata

Edit `metadata.desktop`: at minimum `Name=`, `Description=`, `Author=`.
Leave `MainScript=Main.qml` and `ConfigFile=theme.conf` as they are
unless you renamed those files (you shouldn't — see `Theme-SDK.md` §3).

## 7. Test as you go

Three tools, in the order you'll actually use them while iterating:

1. **`qmllint themes/mytheme/*.qml`** — catches syntax errors instantly.
2. **`QML_XHR_ALLOW_FILE_READ=1 qml6 tests/ThemeHarness.qml -- mytheme`**
   — standalone, no SDDM needed: confirms `theme.conf` parses and shows
   every active token plus a small live component preview. Fastest
   feedback loop for tuning `theme.conf` values.
3. **`scripts/check-theme.sh mytheme`** — validates the whole structure
   against the SDK contract (required files, reserved folders, only
   known tokens in `theme.conf`).

Once those three pass, test for real:

```bash
sddm-greeter-qt6 --test-mode --theme themes/mytheme
```

This is the only way to confirm the full composition, the real
`config` context property, and actual SDDM behavior (see
`Development-Environment.md` §3). On a multi-monitor machine, expect one
window per physical screen.

## 8. Before opening a Pull Request

Go through the checklist in [`Theme-SDK.md`](Theme-SDK.md) §7, then see
[`CONTRIBUTING.md`](../CONTRIBUTING.md) for the PR process itself.
