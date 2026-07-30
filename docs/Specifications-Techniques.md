# Spécifications techniques — Nebula

> Contrat attendu de chaque composant Core et exigences par thème.
> Document de référence pour la Phase 1 (Core MVP) — voir
> [`Roadmap.md`](Roadmap.md). Aucune implémentation ici : uniquement le
> "quoi" et le "pourquoi", le "comment" QML viendra après validation.
>
> Voir aussi [`Design-System.md`](Design-System.md) (vocabulaire des
> valeurs visuelles) et [`Theme-System.md`](Theme-System.md) (flux de
> theming Core ↔ composants).

---

## 1. Convention générale

- Tout composant public est préfixé `Nebula` (voir DT-0004 dans
  [`Decisions-Techniques.md`](Decisions-Techniques.md)).
- Toute valeur visuelle (couleur, police, espacement, durée d'animation)
  est lue via `NebulaThemeProvider` (jamais `ThemeConfig`/`ThemeLoader`
  directement — voir DT-0006 et [`Theme-System.md`](Theme-System.md)),
  jamais codée en dur.
- Chaque composant doit rester utilisable indépendamment des autres
  (pas de couplage caché entre `NebulaClock` et `NebulaBackground`, par
  exemple).
- Chaque propriété publique doit être documentée d'une phrase (voir
  [`CONTRIBUTING.md`](../CONTRIBUTING.md), section Documentation).

## 2. Composants Core

### NebulaThemeConfig

- **Rôle** : point d'entrée unique de configuration d'un thème.
- **Fournit** : accès en lecture aux couleurs, polices, espacements,
  chemins d'assets, paramètres d'animation.
- **Dépendances** : aucune (doit pouvoir être chargé en tout premier).
- **Ouvert** : mécanisme de stockage sous-jacent — voir DT-0003.

### NebulaThemeLoader

- **Rôle** : charge un thème (ses assets, son `ThemeConfig`, son layout)
  au démarrage du greeter.
- **Fournit** : signal de fin de chargement, gestion d'erreur si un thème
  est mal formé (fallback vers un thème minimal plutôt qu'un écran noir).

### NebulaThemeProvider

- **Rôle** : unique point d'accès au theming pour les composants Core.
  Aucun composant ne lit `NebulaThemeConfig` ou `NebulaThemeLoader`
  directement — voir DT-0006 et [`Theme-System.md`](Theme-System.md).
- **Fournit** : les tokens définis dans
  [`Design-System.md`](Design-System.md) (couleurs, spacing, radius,
  typography, animation, effets) sous une API stable.
- **Dépendances** : `NebulaThemeConfig`, `NebulaThemeLoader`.
- **Garantie** : le mécanisme de stockage sous-jacent (DT-0003) peut
  évoluer sans jamais changer l'API consommée par les composants.

### NebulaBackground

- **Rôle** : affichage du fond d'écran / fond animé.
- **Fournit** : image statique, diaporama (optionnel), fond animé
  (optionnel, doit respecter la règle "jamais bloquer le thread UI").
- **Contrainte de performance** : dégradation gracieuse si le matériel ne
  suit pas (voir Architecture.md, priorités de conception).

### NebulaClock / NebulaDate

- **Rôle** : affichage de l'heure et de la date courantes.
- **Fournit** : format configurable (12h/24h, format de date) via
  `ThemeConfig`.
- **Contrainte de performance** : pas de timer plus fréquent que
  nécessaire (1x/seconde maximum pour l'horloge).

### NebulaUserList

- **Rôle** : sélection de l'utilisateur à connecter.
- **Fournit** : liste des utilisateurs (chacun affiché via
  `NebulaAvatar`), nom d'affichage, navigation clavier, état focus
  accessible.

### NebulaAvatar

- **Rôle** : affichage de l'avatar d'un utilisateur — extrait de
  `NebulaUserList` pour rester réutilisable seul (ex. futur écran
  mono-utilisateur, écran de déverrouillage).
- **Fournit** : image d'avatar avec repli sur une icône générique si
  aucune image n'est disponible.
- **Dépendances** : aucune (composant autonome).

### NebulaPasswordField

- **Rôle** : saisie du mot de passe.
- **Fournit** : masquage du texte, état d'erreur (mot de passe refusé),
  état de chargement pendant l'authentification, focus accessible par
  défaut au chargement de l'écran.

### NebulaSessionSelector

- **Rôle** : choix de la session (Plasma, autre DE, session custom).
- **Fournit** : liste des sessions détectées par SDDM.

### NebulaKeyboardSelector

- **Rôle** : choix de la disposition clavier avant connexion.

### NebulaPowerButtons

- **Rôle** : actions arrêt / redémarrage / veille.
- **Fournit** : confirmation optionnelle avant action destructive.

### NebulaNotification

- **Rôle** : affichage de messages système (erreur d'authentification,
  information SDDM).

### NebulaAnimationManager

- **Rôle** : point d'entrée unique pour déclencher des animations
  cohérentes (durées, courbes d'easing) définies par `ThemeConfig`, plutôt
  que des `Behavior`/`Animation` ad-hoc dans chaque composant.

### NebulaSoundManager

- **Rôle** : sons d'interface optionnels (connexion, erreur). Doit pouvoir
  être totalement désactivé sans erreur si aucun son n'est configuré.

### NebulaWallpaperEngine

- **Rôle** : gestion avancée de fond d'écran (diaporama, vidéo, shader) —
  distinct de `NebulaBackground` qui gère le cas simple.

### NebulaBlurEffect / NebulaGlowEffect / NebulaParticles

- **Rôle** : effets GPU optionnels partagés entre thèmes.
- **Contrainte** : chaque effet doit avoir un coût mesuré et un mécanisme
  de désactivation si le matériel est trop faible (inconnue critique à
  valider — voir Architecture.md).

### Polices et icônes partagées

- **Rôle** : assets communs à tous les thèmes, dans `core/assets/`, pour
  éviter qu'un thème embarque sa propre police redondante.

## 3. Exigences par thème

Tout thème dans `themes/<nom>/` doit fournir, au minimum :

| Élément                         | Composant Core utilisé      |
| --------------------------------- | ----------------------------- |
| Écran de connexion                | assemblage de tous les composants ci-dessous |
| Champ mot de passe                 | `NebulaPasswordField`         |
| Sélecteur d'utilisateur            | `NebulaUserList`, `NebulaAvatar` |
| Sélecteur de session               | `NebulaSessionSelector`       |
| Sélecteur de disposition clavier   | `NebulaKeyboardSelector`      |
| Horloge                            | `NebulaClock`                 |
| Date                               | `NebulaDate`                  |
| Arrêt / redémarrage / veille        | `NebulaPowerButtons`          |
| États de focus accessibles          | hérité de chaque composant Core |

Optionnel, selon l'identité du thème :

| Élément                  | Composant Core utilisé   |
| -------------------------- | --------------------------- |
| Fond animé                 | `NebulaBackground`, `NebulaWallpaperEngine` |
| Effets GPU                  | `NebulaBlurEffect`, `NebulaGlowEffect`, `NebulaParticles` |
| Météo, batterie, nom d'hôte | à définir — pas encore de composant Core prévu |
| Diaporama de fonds d'écran   | `NebulaWallpaperEngine` |

Un thème qui a besoin d'un élément optionnel sans composant Core existant
doit d'abord proposer ce composant au Core (voir DT-0002, composition
plutôt qu'héritage).

## 4. Definition of Done — composant Core

Un composant Core n'est considéré terminé que si :

- [ ] Zéro warning QML
- [ ] Toutes les valeurs visuelles proviennent exclusivement de
      `NebulaThemeProvider`, avec des noms issus de
      [`Design-System.md`](Design-System.md) — jamais d'accès direct à
      `ThemeConfig`/`ThemeLoader` (voir DT-0006)
- [ ] Chaque propriété publique est documentée d'une phrase
- [ ] Le composant fonctionne indépendamment des autres (testé isolément)
- [ ] Une suite de tests minimale existe dans `tests/` (voir `Roadmap.md`,
      Phase 1)
- [ ] Le focus clavier est géré pour les composants interactifs
- [ ] Aucune animation ne continue de tourner lorsque le composant n'est
      pas visible
- [ ] Le comportement est identique sous Wayland et X11, ou la différence
      est documentée et volontaire
- [ ] N'utilise que les modules Qt6 listés dans DT-0007
