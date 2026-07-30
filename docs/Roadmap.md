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
- [ ] Valider les inconnues critiques par prototype (API SDDM/Wayland,
      multi-écran, mécanisme de configuration, coût réel des effets GPU)
- [ ] Revue de l'architecture avant de passer en Phase 1

## Phase 1 — Core MVP

Objectif : un Core minimal mais complet, sans aucun thème visuel dessus.

- [ ] `ThemeConfig` (mécanisme de configuration validé en Phase 0)
- [ ] `ThemeLoader`
- [ ] `Background`
- [ ] `Clock`, `Date`
- [ ] `PasswordField`, `UserList`
- [ ] `SessionSelector`, `KeyboardSelector`
- [ ] `PowerButtons` (shutdown / reboot / sleep)
- [ ] `Notification`
- [ ] `AnimationManager` (version minimale)
- [ ] Zéro warning QML sur l'ensemble du Core

## Phase 2 — Premier thème de référence

Objectif : prouver que le Core suffit à construire un thème complet sans
aucune duplication.

- [ ] Choisir le thème de référence (probablement `nord`, le plus simple
      visuellement)
- [ ] Implémenter le thème en composition pure sur le Core
- [ ] Documenter le processus de création d'un thème à partir de
      l'expérience réelle

## Phase 3 — Thèmes suivants et effets avancés

- [ ] `BlurEffect`, `GlowEffect`, `Particles` dans `core/effects/`
- [ ] Thèmes `cyberpunk`, `hacker`, `amoled`, `glass`, `hypr`
- [ ] `WallpaperEngine`, `SoundManager`

## Phase 4 — Outillage avancé (vision long terme)

Non planifié tant que les phases précédentes ne sont pas stables :

- [ ] Éditeur de thème
- [ ] Aperçu live
- [ ] Système de plugins
- [ ] Bibliothèque de shaders
- [ ] Marketplace de thèmes en ligne
- [ ] Installeur / updater de thème

---

## Vision long terme

Nebula doit devenir une implémentation de référence pour les thèmes SDDM
modernes sous KDE Plasma. La qualité du code prime toujours sur la quantité
de fonctionnalités.
