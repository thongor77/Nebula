# Nord Theme Specification — Nebula

> Spécification du thème pilote, chargé de valider le Core MVP (voir
> [`Core-MVP.md`](Core-MVP.md) et `Roadmap.md`, Phase 2). Aucune
> implémentation ici — uniquement les valeurs de tokens et le layout visés,
> à assembler en composition pure sur le Core (voir
> [`Theme-SDK.md`](Theme-SDK.md)).
>
> Palette dérivée de la palette publique
> [Nord](https://www.nordtheme.com/) — cohérent avec l'identité déjà
> annoncée dans `themes/nord/README.md` ("calme et sobre").

---

## 1. Objectif

Nord est le thème de référence choisi pour valider le Core sans dépendre
des effets GPU (Blur/Glow/Particles), volontairement exclus du Core MVP
(voir `Core-MVP.md`, section Exclusions). S'il faut modifier `core/` pour
livrer Nord, c'est que l'architecture doit être revue (critère de
réussite, `Architecture.md` §6).

## 2. Palette

Valeurs de référence issues de la palette Nord publique, mappées aux
tokens de couleur du [Design System](Design-System.md) :

| Token               | Couleur Nord   | Hex       |
| --------------------- | ---------------- | ----------- |
| `backgroundColor`     | nord0             | `#2E3440`   |
| `surfaceColor`        | nord1             | `#3B4252`   |
| `textPrimary`         | nord6             | `#ECEFF4`   |
| `textSecondary`       | nord4             | `#D8DEE9`   |
| `primaryColor`        | nord8             | `#88C0D0`   |
| `secondaryColor`      | nord9             | `#81A1C1`   |
| `accentColor`         | nord10            | `#5E81AC`   |
| `errorColor`          | nord11            | `#BF616A`   |
| `successColor`        | nord14            | `#A3BE8C`   |

`accentColor` sert aussi de couleur pour les notifications `info` (voir
`Design-System.md`, note sur la sévérité `info`).

## 3. Typographie

Aucune police n'est encore choisie/validée au niveau du Core (voir
`Design-System.md` §4). Proposition pour Nord, à valider en Phase 1 selon
la disponibilité réelle dans l'environnement du greeter (voir
`SDDM-Compatibility.md`) :

- `fontFamilyPrimary` : une sans-serif géométrique largement disponible
  sous Linux (ex. Inter, ou la police système par défaut de la
  distribution si Inter n'est pas garantie).
- `fontFamilySecondary` : identique à `fontFamilyPrimary` — Nord ne
  distingue pas visuellement titre et corps de texte par la police, mais
  par la taille et le poids.
- Tailles : héritées des tokens `fontSizeTitle`, `fontSizeBody`,
  `fontSizeClock` du Design System, sans valeur spécifique à Nord (identité
  sobre, pas de typographie surdimensionnée).

## 4. Layout

- Composition centrée verticalement et horizontalement, une seule colonne.
- Ordre vertical : horloge (`NebulaClock`) et date (`NebulaDate`) en haut,
  avatar + nom d'utilisateur (`NebulaAvatar`, `NebulaUserList`) au centre,
  champ de mot de passe (`NebulaPasswordField`) juste en dessous,
  sélecteurs de session/clavier (`NebulaSessionSelector`,
  `NebulaKeyboardSelector`) et actions système (`NebulaPowerButtons`) en
  bas de l'écran.
- Espacement entre sections : `spacingLg`/`spacingXl` (voir
  `Design-System.md`) — Nord privilégie l'espace négatif à la densité.
- Rayons de bordure : `radiusMedium` pour le champ de mot de passe et les
  boutons, `radiusPill` pour l'avatar.
- Fond d'écran (`NebulaBackground`) : image statique, pas de diaporama ni
  de fond animé — cohérent avec l'absence d'effets GPU dans le MVP.

## 5. Composants utilisés

Repris intégralement de `Core-MVP.md` — Nord n'introduit aucun composant
optionnel supplémentaire :

`NebulaThemeProvider`, `NebulaBackground`, `NebulaClock`, `NebulaDate`,
`NebulaAvatar`, `NebulaUserList`, `NebulaPasswordField`,
`NebulaSessionSelector`, `NebulaKeyboardSelector`, `NebulaPowerButtons`
(`NebulaButton`), `NebulaNotification`, `NebulaAnimationManager`.

Aucun `NebulaBlurEffect`/`NebulaGlowEffect`/`NebulaParticles`,
`NebulaWallpaperEngine` ou `NebulaSoundManager` — cohérent avec les
exclusions du Core MVP.

## 6. Animations autorisées

- `durationFast` et `durationNormal` uniquement (micro-interactions,
  transitions standards) — voir `Design-System.md`.
- `durationSlow` évité par défaut : l'identité Nord est sobre, pas portée
  sur les transitions longues ou spectaculaires.
- Aucune animation continue en arrière-plan (cohérent avec la règle
  `Architecture.md` §5.4 : pas d'animation active sur un composant non
  visible — et Nord n'a de toute façon aucun composant visuel nécessitant
  une boucle d'animation permanente).

## 7. Checklist de validation du Core

Nord est considéré comme ayant validé le Core MVP quand :

- [ ] Le thème est assemblé uniquement via `theme.conf` + `Main.qml` +
      `assets/` (voir `Theme-SDK.md`), sans aucune modification de
      `core/`.
- [ ] Tous les tokens utilisés dans `theme.conf` existent déjà dans
      `Design-System.md` — aucune valeur inventée localement.
- [ ] Testé en mode `sddm-greeter --test-mode` (voir
      `Development-Environment.md`).
- [ ] Tout ajustement découvert pendant l'implémentation est reporté dans
      `Theme-SDK.md` (voir `Roadmap.md`, Phase 2).
