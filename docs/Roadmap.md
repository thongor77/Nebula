# Roadmap — Nebula

> Mise à jour à chaque fonctionnalité livrée ou changement de phase
> (voir `META/Workflow-Claude.md`).

---

## Phase 0 — Architecture (en cours)

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
- [ ] Valider les inconnues critiques par prototype (API SDDM/Wayland,
      multi-écran, mécanisme de configuration, coût réel des effets GPU,
      format d'export compatible avec le futur Nebula Designer — voir
      DT-0003)
- [ ] Revue de l'architecture avant de passer en Phase 1

## Phase 0.5 — Architecture Contracts (en cours)

Objectif : produire les contrats techniques (API, compatibilité, environnement
de développement, création de thème) qui guideront toute l'implémentation
future — pour qu'un développeur externe puisse commencer sans ambiguïté.

Statut : en cours.

Livrables :

- [x] Contrat public du Core (`docs/Core-API.md`)
- [x] Matrice de compatibilité SDDM (`docs/SDDM-Compatibility.md`)
- [x] Environnement de développement (`docs/Development-Environment.md`)
- [x] Guide de création de thème (`docs/Theme-Development.md`)
- [ ] Revue de ces quatre documents avant de démarrer la Phase 1

La Phase 1 (Core MVP) ne commence qu'après validation de cette phase — en
particulier après avoir levé au moins les inconnues bloquantes listées
dans `docs/SDDM-Compatibility.md` qui touchent les composants du premier
lot (voir ordre de construction ci-dessous).

## Phase 1 — Core MVP

Objectif : un Core minimal mais complet, sans aucun thème visuel dessus.
Démarre après validation de la Phase 0.5.

Ordre de construction recommandé (plomberie avant composants visuels,
composants simples avant composants interactifs — voir
[`Theme-System.md`](Theme-System.md)) :

1. [ ] `ThemeConfig` (mécanisme de configuration validé en Phase 0)
2. [ ] Design tokens (`docs/Design-System.md` → implémentation)
3. [ ] `ThemeLoader`
4. [ ] `ThemeProvider`
5. [ ] `Background`
6. [ ] `Avatar`, `UserList`, `PasswordField`
7. [ ] `Clock`, `Date`
8. [ ] `PowerButtons` (shutdown / reboot / sleep)
9. [ ] `SessionSelector`, `KeyboardSelector`
10. [ ] `Notification`
11. [ ] `AnimationManager` (version minimale)
12. [ ] Mettre en place `tests/` avec une première suite de tests pour
       les composants livrés ci-dessus
13. [ ] Zéro warning QML sur l'ensemble du Core

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
