# Roadmap — Nebula

> Mise à jour à chaque fonctionnalité livrée ou changement de phase
> (voir `META/Workflow-Claude.md`).

---

## Phase 0 — Architecture (terminée)

Objectif : ne pas écrire de code avant d'avoir validé le contrat
Core/Thèmes.

- [x] Définir la mission et les objectifs du projet
- [x] Structurer le dépôt (`core/`, `themes/`, `docs/`, `.github/`)
- [x] Documenter l'architecture cible (`docs/Architecture.md`)
- [x] Documenter les décisions techniques (`docs/Decisions-Techniques.md`)
- [x] Documenter les spécifications de composants (`docs/Specifications-Techniques.md`)
- [x] Définir les conventions de code et le processus de contribution
- [x] Documenter le catalogue de design tokens (`docs/Design-System.md`)
- [x] Documenter le flux de theming Core ↔ composants (`docs/Theme-System.md`)
- [x] Valider les inconnues critiques par prototype — fait en Phase 1.0
      (`docs/Prototype-Results.md`) : API SDDM réelle et multi-écran
      résolus ; coût des effets GPU, rendu HiDPI pixel, mécanisme de
      configuration (écriture/export) et authentification de bout en bout
      restent ouverts, explicitement hors périmètre de ce prototype.
- [x] Revue de l'architecture avant de passer en Phase 1 — satisfaite par
      la Phase 0.6 (`docs/Architecture-Review.md`)

## Phase 0.5 — Architecture Contracts (terminée)

Objectif : produire les contrats techniques (API, compatibilité, environnement
de développement, création de thème) qui guideront toute l'implémentation
future — pour qu'un développeur externe puisse commencer sans ambiguïté.

Statut : terminée.

Livrables :

- [x] Contrat public du Core (`docs/Core-API.md`)
- [x] Matrice de compatibilité SDDM (`docs/SDDM-Compatibility.md`)
- [x] Environnement de développement (`docs/Development-Environment.md`)
- [x] Guide de création de thème (`docs/Theme-Development.md`)
- [x] Revue de ces quatre documents — faite en Phase 0.6
      (`docs/Architecture-Review.md`)

## Phase 0.6 — Architecture Review (terminée)

Objectif : revue finale de cohérence documentaire avant démarrage du
Core MVP — vérifier que l'architecture permet une implémentation claire,
maintenable et extensible, sans code QML.

Statut : terminée.

Livrables :

- [x] Revue de cohérence croisée de tous les documents d'architecture,
      contradictions et doublons corrigés (`docs/Architecture-Review.md`)
- [x] Frontière Core/Theme/ThemeProvider confirmée explicitement
      (`docs/Architecture-Review.md`, section 4 ; enrichissement de
      `docs/Theme-System.md` avec ordre d'initialisation et valeurs par
      défaut)
- [x] Périmètre exact du Core MVP (`docs/Core-MVP.md`), réconcilié avec
      l'ordre de construction ci-dessous et avec `NebulaButton` désormais
      formalisé
- [x] Spécification du thème pilote (`docs/Nord-Theme-Specification.md`)
- [x] Risques techniques consolidés (SDDM, GPU, Wayland —
      `docs/Architecture-Review.md`, section 5)
- [x] Règle "Core ou Theme, documenter l'API avant d'implémenter, éviter
      toute dépendance à un thème" ajoutée dans `CLAUDE.md`

## Phase 1.0 — SDDM Technical Prototype (terminée)

Objectif : valider l'environnement SDDM réel avant le développement du
Core, par un prototype jetable (`prototype/`) — pas un thème, pas de
composants Core, pas de `ThemeProvider`.

Statut : terminée.

Livrables :

- [x] `prototype/Main.qml`, `theme.conf`, `README.md`
- [x] Testé en standalone (`qml6`) et via `sddm-greeter-qt6 --test-mode`
      sur une installation SDDM 0.21 réelle (voir
      `docs/Prototype-Results.md`)
- [x] API SDDM réelle vérifiée (`sddm`, `userModel`, `sessionModel`,
      `keyboard`, `screenModel`, `config`) — inconnue critique levée
- [x] Comportement multi-écran vérifié (une vue par écran physique) —
      inconnue critique levée, testé avec 3 écrans réels
- [x] Géométrie HiDPI vérifiée sur un setup à échelles mixtes (1 et 1.4)
- [x] `docs/Prototype-Results.md` créé ; répercussions sur
      `SDDM-Compatibility.md`, `Core-API.md`, `Development-Environment.md`,
      `Theme-Development.md` et `Architecture.md` (Inconnues critiques)
- [ ] Coût réel des effets GPU, rendu pixel HiDPI, mécanisme de
      configuration définitif, authentification de bout en bout —
      délibérément non couverts par ce prototype (voir
      `Prototype-Results.md` §7), à valider plus tard sans bloquer le
      Core MVP (voir `Core-MVP.md`, exclusions)

Le dossier `prototype/` est jetable : il ne sera pas conservé comme base
de code du Core (voir `Core-MVP.md` et `Theme-Development.md` pour la
structure définitive d'un thème réel).

## Phase 1 — Core MVP

Objectif : un Core minimal mais complet, sans aucun thème visuel dessus.
Démarre après validation de la Phase 1.0.

**Sous-étape Phase 1.1 — Core Foundation Skeleton (terminée) :** premiers
pas d'implémentation réelle (`ThemeConfig`, `ThemeProvider`, tokens,
`NebulaButton`), testés visuellement (`qmllint` + rendu réel). Décisions
prises et bug de conception trouvé/corrigé (tokens `accentColor` ==
`primaryColor`) : voir
[`docs/Core-Implementation-Status.md`](Core-Implementation-Status.md).
Pas de thème complet, pas d'effets avancés — conforme au périmètre de
cette sous-étape.

**Sous-étape Phase 1.2 — Core Components Expansion (terminée) :**
`NebulaAvatar`, `NebulaClock`, `NebulaDate` implémentés et testés
(`qmllint`, rendu réel, scaling différent `QT_SCALE_FACTOR=2`). Critère de
fin atteint : écran de login statique (avatar + heure + date + bouton)
démontré dans `tests/LoginScreenHarness.qml`, sans thème ni API SDDM.
Décisions de réconciliation avec le brief (format libre pour `NebulaClock`
en plus de `use24HourFormat`/`showSeconds`, `radius` ajouté à
`NebulaAvatar`, `fallbackIcon` conservé) : voir
[`docs/Core-Implementation-Status.md`](Core-Implementation-Status.md).

Ordre de construction recommandé (plomberie avant composants visuels,
composants simples avant composants interactifs — voir
[`Theme-System.md`](Theme-System.md)) :

1. [x] `ThemeConfig` — Phase 1.1, `core/config/NebulaThemeConfig.qml`
       (voir `docs/Core-Implementation-Status.md`)
2. [x] Design tokens — Phase 1.1, premiers tokens implémentés dans
       `NebulaThemeConfig` (colors, spacing, radius, typography, animation)
3. [ ] `ThemeLoader`
4. [x] `ThemeProvider` — Phase 1.1, `core/theme/NebulaThemeProvider.qml`
5. [x] `Button` — Phase 1.1 ; [x] `Avatar` — Phase 1.2, tous deux dans
       `core/components/`
6. [ ] `Background`
7. [ ] `UserList`, `PasswordField`
8. [x] `Clock`, `Date` — Phase 1.2, `core/components/NebulaClock.qml`,
       `core/components/NebulaDate.qml`
9. [ ] `PowerButtons` (shutdown / reboot / sleep — composé sur `Button`)
10. [ ] `SessionSelector`, `KeyboardSelector`
11. [ ] `Notification`
12. [ ] `AnimationManager` (version minimale)
13. [ ] Mettre en place `tests/` avec une première suite de tests pour
       les composants livrés ci-dessus
14. [ ] Zéro warning QML sur l'ensemble du Core

Périmètre exact et exclusions du MVP : voir
[`Core-MVP.md`](Core-MVP.md).

## Phase 2 — Premier thème de référence

Objectif : prouver que le Core suffit à construire un thème complet sans
aucune duplication.

- [ ] Thème de référence retenu : `nord`. Choix confirmé après analyse
      d'une proposition alternative (`cyberpunk`) : `nord` reste préféré
      car sa simplicité visuelle permet de valider le contrat Core/Thème
      sans dépendre des effets GPU (blur/glow/particules), encore non
      stabilisés à ce stade (voir Phase 3). `cyberpunk` sert de second
      thème pour valider justement ces effets.
- [ ] Implémenter le thème en suivant `docs/Theme-Development.md`, en
      composition pure sur le Core
- [ ] Mettre à jour `docs/Theme-Development.md` avec les ajustements
      découverts lors de cette première implémentation réelle

## Phase 3 — Thèmes suivants et effets avancés

- [ ] `BlurEffect`, `GlowEffect`, `Particles` dans `core/effects/`
- [ ] Thèmes `cyberpunk`, `hacker`, `amoled`, `glass`, `hypr`
- [ ] `WallpaperEngine`, `SoundManager`

## Phase 4 — Outillage avancé (vision long terme)

Non planifié tant que les phases précédentes ne sont pas stables :

- [ ] **Nebula Designer** — application graphique compagnon permettant de
      modifier visuellement les tokens d'un thème (couleurs, animations,
      blur, glow, wallpapers, paramètres visuels du
      [Design System](Design-System.md)) puis d'exporter le résultat dans
      un format rechargeable par `NebulaThemeLoader` (ex. `theme.conf`).
      Voir le complément à DT-0003 dans `Decisions-Techniques.md`.
      Non développé maintenant — seule l'architecture (flux de theming
      dans `Theme-System.md`) est préparée dès aujourd'hui.
- [ ] Aperçu live
- [ ] Système de plugins
- [ ] Bibliothèque de shaders
- [ ] Marketplace de thèmes en ligne
- [ ] Installeur / updater de thème

Une restructuration du dépôt en `src/{core,themes,tools,shared}/` a été
étudiée pour préparer l'arrivée de Nebula Designer, mais différée — voir
DT-0008. À réévaluer seulement si cette phase devient active.

---

## Vision long terme

Nebula doit devenir une implémentation de référence pour les thèmes SDDM
modernes sous KDE Plasma. La qualité du code prime toujours sur la quantité
de fonctionnalités.
