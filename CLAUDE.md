# CLAUDE.md — Nebula

> Projet important (voir `~/claude-projects/META/Standards.md`).
> Documentation complète : ce fichier + `README.md` + `docs/`.

---

## Description

Nebula est un framework SDDM modulaire pour KDE Plasma 6 / Wayland : un
Core réutilisable (composants, effets, animations, utilitaires) sur lequel
se greffent des thèmes qui ne définissent que leur identité visuelle.

Nebula n'est **pas** une collection de thèmes indépendants. La duplication
de composants entre thèmes est considérée comme un bug.

## Stack

- QML / Qt6
- SDDM 0.21+
- Wayland (cible principale), compatible X11

## État actuel

**Phase d'architecture.** Aucun composant QML n'est implémenté. Priorité
actuelle : valider la structure Core/Thèmes, le contrat de chaque
composant et les décisions techniques avant d'écrire le moindre code.

## Lancer le projet

Rien à lancer pour l'instant — pas de code. Une fois un premier thème
livré, les instructions d'installation seront ajoutées ici et dans le
`README.md`.

## Architecture

Résumé : `core/` fournit tout ce qui est réutilisable (components, effects,
animations, utils, assets) ; `themes/` ne contient que couleurs, fonds
d'écran, paramètres d'animation et layout. Chaque thème importe le Core,
jamais l'inverse.

Détail complet, utilisateurs cibles, cas d'usage et inconnues :
[`docs/Architecture.md`](docs/Architecture.md). Vocabulaire des tokens
visuels : [`docs/Design-System.md`](docs/Design-System.md). Flux de
theming (`ThemeLoader` → `ThemeConfig` → `ThemeProvider` → composants) :
[`docs/Theme-System.md`](docs/Theme-System.md).

## Décisions techniques

Voir [`docs/Decisions-Techniques.md`](docs/Decisions-Techniques.md) pour le
détail et les raisons de chaque choix (Wayland-first, composition plutôt
qu'héritage, ThemeConfig centralisé, etc.).

## Roadmap

Voir [`docs/Roadmap.md`](docs/Roadmap.md).

Phase actuelle : **Phase 0.5 — Architecture Contracts**, avant tout code.
Documents de contrat : [`docs/Core-API.md`](docs/Core-API.md),
[`docs/SDDM-Compatibility.md`](docs/SDDM-Compatibility.md),
[`docs/Development-Environment.md`](docs/Development-Environment.md),
[`docs/Theme-Development.md`](docs/Theme-Development.md).

## Conventions spécifiques

En plus des standards globaux (`META/Standards.md`) :

- **Langue** : documentation publique (`README.md`, `CONTRIBUTING.md`,
  templates GitHub) en anglais ; documentation interne
  (`CLAUDE.md`, `docs/`) en français — cohérent avec la règle globale
  public → anglais / interne → français.
- **Nommage** : préfixe `Nebula` pour tout composant exporté par le Core
  (`NebulaButton`, `NebulaClock`, `NebulaConfig`, ...). Voir
  [`docs/Specifications-Techniques.md`](docs/Specifications-Techniques.md).
- **Philosophie de priorité** : Stabilité > Performance > Maintenabilité >
  Accessibilité > Beauté. Ne jamais sacrifier la performance pour un effet
  visuel.
- **Configuration** : aucune couleur, police ou espacement codé en dur ;
  tout passe par `ThemeConfig`, mais un composant ne le lit jamais
  directement — uniquement via `NebulaThemeProvider` (voir DT-0006).
- Détail des conventions de code (QML, JS, commits, PR) :
  [`CONTRIBUTING.md`](CONTRIBUTING.md).
