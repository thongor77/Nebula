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

**Core MVP en cours.** L'architecture, les contrats et un prototype
technique réel sont terminés (Phases 0 à 1.0). Composants Core réels déjà
implémentés et testés : `NebulaThemeConfig`, `NebulaThemeProvider`,
`NebulaButton`, `NebulaAvatar`, `NebulaClock`, `NebulaDate`,
`NebulaLoginLayout`, `NebulaAuthService`/`UserService`/`SessionService`/
`PowerService` (voir Roadmap ci-dessous). Aucun thème n'existe encore.

## Lancer le projet

Rien à lancer pour l'instant — pas de code. Une fois un premier thème
livré, les instructions d'installation seront ajoutées ici et dans le
`README.md`.

## Architecture

Résumé : `core/` fournit tout ce qui est réutilisable (components,
layouts, services, effects, animations, utils, assets) ; `platform/`
contient les adaptateurs concrets vers un backend (SDDM aujourd'hui) ;
`themes/` ne contient que couleurs, fonds d'écran, paramètres d'animation
et layout. Chaque thème importe le Core, jamais l'inverse. Le Core ne
connaît ni un thème, ni SDDM directement — voir
[`docs/Nebula-Principles.md`](docs/Nebula-Principles.md).

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

Phases 0 à 1.0 terminées — architecture, contrats, revue, et prototype
technique réel (voir [`docs/Architecture-Review.md`](docs/Architecture-Review.md),
[`docs/Core-MVP.md`](docs/Core-MVP.md),
[`docs/Nord-Theme-Specification.md`](docs/Nord-Theme-Specification.md) et
[`docs/Prototype-Results.md`](docs/Prototype-Results.md) — API SDDM
réelle et comportement multi-écran vérifiés sur une installation SDDM
0.21 réelle).
Phase 1 (Core MVP) en cours : `NebulaThemeConfig`, `NebulaThemeProvider`,
`NebulaButton` (Phase 1.1), `NebulaAvatar`, `NebulaClock`, `NebulaDate`
(Phase 1.2), `NebulaLoginLayout` (Phase 1.3, squelette à 4 zones),
`NebulaAuthService`/`NebulaUserService`/`NebulaSessionService`/
`NebulaPowerService` + squelettes `platform/sddm/` (Phase 1.4, voir
[`docs/Services-Architecture.md`](docs/Services-Architecture.md)) —
implémentés et testés, voir
[`docs/Core-Implementation-Status.md`](docs/Core-Implementation-Status.md)
et le journal des découvertes techniques
[`docs/Development-Journal.md`](docs/Development-Journal.md). Écran de
login statique (sans thème, sans SDDM) déjà démontrable via
`NebulaLoginLayout` + Services mockés (`tests/LoginScreenHarness.qml`).
`prototype/` reste jetable, distinct de `core/`.

## Règle avant toute nouvelle fonctionnalité

Ajoutée lors de la revue d'architecture Phase 0.6
([`docs/Architecture-Review.md`](docs/Architecture-Review.md)). Avant
d'implémenter quoi que ce soit :

1. Vérifier si la fonctionnalité appartient au Core ou au Theme (voir
   [`docs/Architecture-Review.md`](docs/Architecture-Review.md), section
   Frontière Core/Theme/ThemeProvider). En cas de doute, elle appartient
   au Core.
2. Documenter l'API avant l'implémentation
   ([`docs/Core-API.md`](docs/Core-API.md), voir DT-0009) — pas l'inverse.
3. Éviter toute dépendance spécifique à un thème dans le Core (aucun nom
   de thème — `cyberpunk`, `nord`, etc. — ne doit apparaître dans
   `core/`).
4. Éviter toute dépendance directe à SDDM dans un composant Core — passer
   par un Service (`core/services/`, Phase 1.4). Voir
   [`docs/Services-Architecture.md`](docs/Services-Architecture.md) et
   [`docs/Nebula-Principles.md`](docs/Nebula-Principles.md).

## Conventions spécifiques

En plus des standards globaux (`META/Standards.md`) :

- **Langue** : documentation publique (`README.md`, `CONTRIBUTING.md`,
  templates GitHub) en anglais ; documentation interne
  (`CLAUDE.md`, `docs/`) en français — cohérent avec la règle globale
  public → anglais / interne → français.
- **Nommage** : préfixe `Nebula` pour tout composant exporté par le Core,
  y compris les Services (`NebulaButton`, `NebulaClock`,
  `NebulaThemeProvider`, `NebulaAuthService`, ...). Les Platform Adapters
  (`platform/`) n'ont pas ce préfixe — ils vivent hors de `core/` et
  portent le nom de la plateforme (`SDDMAuthAdapter`, ...). Voir
  [`docs/Core-API.md`](docs/Core-API.md) et DT-0010.
- **Philosophie de priorité** : Stabilité > Performance > Maintenabilité >
  Accessibilité > Beauté. Ne jamais sacrifier la performance pour un effet
  visuel.
- **Configuration** : aucune couleur, police ou espacement codé en dur ;
  tout passe par `ThemeConfig`, mais un composant ne le lit jamais
  directement — uniquement via `NebulaThemeProvider` (voir DT-0006).
- Détail des conventions de code (QML, JS, commits, PR) :
  [`CONTRIBUTING.md`](CONTRIBUTING.md).
