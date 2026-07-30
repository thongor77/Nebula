# Core MVP — Nebula

> Périmètre exact de la Phase 1 (voir [`Roadmap.md`](Roadmap.md)) : ce qui
> est **dans** le MVP et ce qui en est **explicitement exclu**. Ce document
> répond à "quoi et pourquoi" ; l'ordre de construction détaillé reste
> dans `Roadmap.md`, Phase 1.
>
> Réconciliation Phase 0.6 : la proposition d'origine listait un
> périmètre plus restreint (`NebulaClock`, `NebulaDate`, `NebulaButton`,
> `NebulaAvatar`) que celui déjà planifié dans `Roadmap.md`. Ce document
> reprend le périmètre complet déjà planifié — avec `NebulaButton`
> maintenant formalisé — pour éviter deux définitions concurrentes du MVP
> (voir [`Architecture-Review.md`](Architecture-Review.md), §3.7).

---

## 1. Objectif du MVP

Un Core minimal mais **complet du point de vue fonctionnel** : capable de
faire fonctionner un écran de connexion réel (voir `Architecture.md` §8,
"Ce que chaque thème doit fournir"), sans aucun effet visuel avancé.

## 2. Infrastructure

- `NebulaThemeConfig` — mécanisme de configuration (DT-0003)
- `NebulaThemeLoader` — chargement du thème actif
- `NebulaThemeProvider` — point d'accès unique au theming (DT-0006)
- Design Tokens (`docs/Design-System.md`) — vocabulaire des valeurs
  visuelles, dans leur première implémentation concrète
- `NebulaAuthService`, `NebulaUserService`, `NebulaSessionService`,
  `NebulaPowerService` (Phase 1.4) — unique point d'accès à toute
  intégration SDDM pour les composants (voir
  [`Services-Architecture.md`](Services-Architecture.md)). Adossés à
  `platform/sddm/` (squelettes en Phase 1.4, câblage réel plus tard).

## 3. Composants

### Layout

- `NebulaLoginLayout` (Phase 1.3) — squelette commun (zones fond /
  contenu principal / statut / pied de page), géométrie uniquement.

### Primitives simples et autonomes

- `NebulaButton`
- `NebulaAvatar`
- `NebulaClock`
- `NebulaDate`
- `NebulaBackground` (cas simple, sans diaporama ni vidéo)

### Composants d'intégration SDDM

Depuis la Phase 1.4, chacun dépend d'un Service (`core/services/`), pas
de SDDM directement — voir [`Services-Architecture.md`](Services-Architecture.md)
et [`Core-API.md`](Core-API.md).

- `NebulaUserList` (composé sur `NebulaAvatar`, dépend de
  `NebulaUserService`)
- `NebulaPasswordField` (dépend de `NebulaAuthService`)
- `NebulaSessionSelector` (dépend de `NebulaSessionService`)
- `NebulaKeyboardSelector` (pas de Service dédié — voir `Core-API.md`)
- `NebulaPowerButtons` (composé sur `NebulaButton`, dépend de
  `NebulaPowerService`)
- `NebulaNotification`
- `NebulaAnimationManager` (version minimale : tokens de durée uniquement,
  pas de courbes d'easing avancées)

## 4. Intégration SDDM

Correspondance entre les besoins fonctionnels et les composants qui les
couvrent (détail des inputs exacts : voir chaque entrée dans
[`Core-API.md`](Core-API.md)) :

| Besoin                     | Composant(s)                                   |
| ----------------------------- | ------------------------------------------------- |
| Récupération utilisateur       | `NebulaUserList`, `NebulaAvatar`                   |
| Authentification                | `NebulaPasswordField`                              |
| Session                         | `NebulaSessionSelector`, `NebulaKeyboardSelector`   |
| Actions système (arrêt/redémarrage/veille) | `NebulaPowerButtons`, `NebulaButton`   |

## 5. Explicitement exclu du MVP

- `NebulaBlurEffect`, `NebulaGlowEffect`, `NebulaParticles` — shaders,
  particules, flou avancé (voir `Roadmap.md`, Phase 3)
- `NebulaWallpaperEngine` en mode vidéo ou diaporama (le mode simple reste
  couvert par `NebulaBackground`)
- Effets complexes en général : tout ce qui dépend d'une ligne "à
  vérifier" de [`SDDM-Compatibility.md`](SDDM-Compatibility.md) sans plan
  de repli
- `NebulaSoundManager` — dépend de la ligne "Audio login", non vérifiée

Ces exclusions ne sont pas définitives : elles reflètent simplement que
ces fonctions dépendent d'inconnues non encore levées (voir
`Architecture.md` §4) ou sont hors du périmètre fonctionnel minimal d'un
écran de connexion.

## 6. Definition of Done du MVP

Le MVP est considéré terminé quand :

- [ ] Tous les composants des sections 2 et 3 respectent le Definition of
      Done individuel de [`Specifications-Techniques.md`](Specifications-Techniques.md#4-definition-of-done--composant-core)
- [ ] Le thème `nord` (voir
      [`Nord-Theme-Specification.md`](Nord-Theme-Specification.md)) peut
      être assemblé entièrement à partir de ces composants, sans modifier
      `core/` (critère de réussite, `Architecture.md` §6)
- [ ] Aucun composant du MVP ne dépend d'une ligne "à vérifier" de
      `SDDM-Compatibility.md`
