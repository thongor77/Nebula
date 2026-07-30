# Design System — Nebula

> Catalogue des design tokens partagés par tous les thèmes. Ce document
> définit le **vocabulaire** (noms, échelles) ; le mécanisme d'accès à ces
> valeurs (comment un composant les lit réellement) est décrit dans
> [`Theme-System.md`](Theme-System.md). La valeur concrète de chaque token
> est définie par thème, jamais par le Core.
>
> Origine : issu de l'analyse de la proposition externe
> *Nebula Architecture Enhancement Proposal* (sections 2 et 3), fusionnées
> ici en un seul document plutôt qu'en deux redondants.

---

## 1. Principe

Aucune couleur, espacement, rayon de bordure, police ou durée d'animation
n'est codé en dur dans un composant Core. Un composant ne connaît que des
**noms de tokens** ; la valeur derrière chaque nom vient du thème actif via
`NebulaThemeProvider` (voir [`Theme-System.md`](Theme-System.md)).

## 2. Spacing

| Token         | Usage indicatif                     |
| -------------- | ------------------------------------- |
| `spacingXs`    | espacement minimal (icône ↔ texte)    |
| `spacingSm`    | espacement entre éléments proches      |
| `spacingMd`    | espacement par défaut entre sections   |
| `spacingLg`    | séparation entre blocs majeurs          |
| `spacingXl`    | marges d'écran                          |

Les valeurs concrètes (en px ou en unités logiques HiDPI) sont laissées à
chaque thème ; seule l'échelle relative (xs < sm < md < lg < xl) est
garantie par le Core.

## 3. Radius

| Token            | Usage indicatif                         |
| ------------------ | ------------------------------------------ |
| `radiusSmall`      | petits éléments (icônes, badges)            |
| `radiusMedium`     | champs de saisie, boutons                    |
| `radiusLarge`      | cartes, panneaux                             |
| `radiusPill`       | éléments totalement arrondis (pilules, avatars) |

## 4. Typography

Tokens exposés par `NebulaThemeProvider`, valeurs définies par thème :

- `fontFamilyPrimary` — police principale (titres, horloge)
- `fontFamilySecondary` — police secondaire (texte courant)
- `fontSizeTitle`
- `fontSizeBody`
- `fontSizeClock`
- `fontWeight` (normal / medium / bold — nommage à confirmer lors du
  prototype, voir Inconnues critiques dans `Architecture.md`)

Les polices par défaut (fallback si un thème n'en fournit pas) vivent dans
`core/assets/` — voir [`Specifications-Techniques.md`](Specifications-Techniques.md).

## 5. Animation

| Token           | Durée par défaut | Usage indicatif                  |
| ----------------- | ------------------ | ----------------------------------- |
| `durationFast`     | 120 ms              | micro-interactions (focus, hover)   |
| `durationNormal`   | 250 ms              | transitions standards               |
| `durationSlow`     | 500 ms              | transitions d'écran, apparitions    |

Courbes d'easing standards à définir lors du prototype `NebulaAnimationManager`
(Phase 1) — ne pas figer avant d'avoir testé leur rendu réel à 60 FPS.

Toute animation doit utiliser ces tokens via `NebulaAnimationManager`
plutôt que des durées codées en dur dans un composant (voir
`Specifications-Techniques.md`, section NebulaAnimationManager).

## 6. Effets

Tokens de configuration des effets optionnels (`NebulaBlurEffect`,
`NebulaGlowEffect`, `NebulaParticles`) :

- `blurAmount`
- `glowIntensity`
- `shadowElevation`
- `opacityOverlay`
- `enableEffects` (interrupteur global — doit permettre de désactiver tous
  les effets GPU d'un coup, notamment sur matériel bas de gamme)
- `particleDensity`

Ces tokens sont conceptuels tant que le coût réel des effets GPU n'a pas
été mesuré (voir `Architecture.md`, section Inconnues critiques). Un thème
ne doit jamais supposer qu'un effet est gratuit.

## 7. Couleurs

| Token             | Usage indicatif                          |
| ------------------ | ------------------------------------------- |
| `primaryColor`     | couleur d'accent principale                  |
| `secondaryColor`   | couleur d'accent secondaire                  |
| `accentColor`      | mise en avant ponctuelle (focus, sélection)  |
| `backgroundColor`  | fond général de l'écran                       |
| `surfaceColor`     | fond des panneaux/cartes                      |
| `textPrimary`      | texte principal                               |
| `textSecondary`    | texte atténué (labels, aide)                  |
| `errorColor`       | erreur d'authentification, état invalide       |
| `successColor`     | confirmation, état valide                      |

Nommage en camelCase pour rester cohérent avec les propriétés QML (plutôt
que le `PascalCase` de la proposition d'origine).

Le niveau de sévérité `info` de `NebulaNotification` (voir `Core-API.md`)
n'a pas de token de couleur dédié : il réutilise `accentColor` par
convention, plutôt que d'ajouter un token pour un seul usage. À revoir si
un second cas d'usage apparaît.

## 8. Statut

Ce catalogue est un vocabulaire de référence pour la Phase 1 (Core MVP).
Les noms peuvent encore évoluer légèrement lors du prototype de
`NebulaThemeProvider`, mais toute nouvelle valeur visuelle ajoutée à un
composant doit d'abord passer par ce document, jamais être inventée
localement dans un composant ou un thème.
