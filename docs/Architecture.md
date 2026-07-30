# Architecture — Nebula

> Document vivant. Toute décision qui en découle et mérite d'être tracée
> va dans [`Decisions-Techniques.md`](Decisions-Techniques.md).

---

## 1. Problème

Les thèmes SDDM existants sont, dans leur grande majorité, des projets
indépendants qui réimplémentent chacun leur propre horloge, leur propre
sélecteur d'utilisateur, leur propre champ de mot de passe, etc. Résultat :

- duplication massive de code QML entre thèmes ;
- qualité inégale (bugs corrigés dans un thème, jamais portés aux autres) ;
- pas de garantie de compatibilité Wayland/HiDPI/multi-écran ;
- personnalisation difficile car rien n'est centralisé.

Nebula répond à ce problème en séparant strictement ce qui est **générique**
(Core) de ce qui est **identité visuelle** (Thème).

## 2. Utilisateurs

| Utilisateur                     | Besoin                                                        |
| -------------------------------- | -------------------------------------------------------------- |
| Utilisateur final KDE Plasma 6    | Un écran de connexion beau, fluide, qui fonctionne sous Wayland |
| Créateur de thème (contributeur) | Pouvoir créer un nouveau thème sans réécrire les composants de base |
| Mainteneur Nebula                 | Un Core stable dont la qualité profite à tous les thèmes         |

## 3. Cas d'usage

1. Un utilisateur installe un thème Nebula existant (ex. `nord`) et
   personnalise ses couleurs / son fond d'écran via les valeurs exposées
   par `ThemeConfig` (voir [`Theme-System.md`](Theme-System.md)), sans
   toucher au QML.
2. Un contributeur crée un nouveau thème : il écrit uniquement des fichiers
   de configuration et de layout, en import ant les composants du Core.
3. Un mainteneur corrige un bug dans `core/components/PasswordField.qml` :
   le correctif profite instantanément à tous les thèmes.
4. Un utilisateur multi-écran / HiDPI démarre sa session : l'écran de
   connexion s'affiche correctement sur chaque moniteur, à la bonne échelle.

## 4. Inconnues critiques

Ces points doivent être validés par un prototype avant d'être figés dans
l'architecture définitive :

- **API réelle de SDDM 0.21+ sous Wayland** : quelles propriétés/signaux
  sont réellement exposés au QML par rapport à la théorie de la doc SDDM.
- **Multi-écran** : comportement exact de SDDM avec plusieurs sorties
  Wayland (une fenêtre de login par écran ? partagée ?).
- **Performance des effets GPU** (blur, particules) sur du matériel bas de
  gamme — nécessaire pour respecter la règle "ne jamais sacrifier la
  performance pour un effet visuel".
- **Mécanisme de configuration** : fichier `.conf` classique SDDM vs QML
  `Qt.labs.settings` vs JSON — impacte directement la conception de
  `ThemeConfig`.
- **Rechargement à chaud d'un thème** en développement (souhaitable mais
  non bloquant pour la v1).

Tant que ces points ne sont pas expérimentés, aucune décision les concernant
n'est considérée comme définitive. Suivi ligne par ligne de ces inconnues
et d'autres contraintes SDDM/Qt6 : [`SDDM-Compatibility.md`](SDDM-Compatibility.md).

## 5. Architecture cible

### 5.1 Principe

```text
nebula/
├── core/
│   ├── components/
│   ├── effects/
│   ├── animations/
│   ├── utils/
│   └── assets/
├── themes/
│   ├── cyberpunk/
│   ├── hacker/
│   ├── amoled/
│   ├── nord/
│   ├── glass/
│   └── hypr/
├── docs/
├── scripts/
├── tests/
└── .github/
```

`tests/` a été ajouté suite à l'analyse de la proposition externe
*Nebula Architecture Enhancement Proposal* — son absence était un vrai
manque, à structurer dès la Phase 1 (voir `Roadmap.md`).

Une restructuration plus large en `src/{core,themes,tools,shared}/` a été
étudiée mais différée — voir DT-0008 dans
[`Decisions-Techniques.md`](Decisions-Techniques.md).

- `core/` contient tout ce qui est réutilisable.
- `themes/` ne contient que l'identité de chaque thème.
- Chaque thème **importe** le Core ; le Core n'a jamais connaissance des
  thèmes.

### 5.2 Règles d'architecture

- Ne jamais dupliquer un composant : composition plutôt que copier/coller.
- Tout composant réutilisable appartient au Core.
- Un thème ne définit que : couleurs, fonds d'écran, animations
  (paramètres, pas moteur), layout, assets propres au thème.
- Toute option visuelle doit être configurable via `ThemeConfig` — jamais
  de couleur, police ou espacement codé en dur.

### 5.3 Composants Core visés

`Clock`, `Date`, `Button`, `UserList`, `Avatar`, `PasswordField`,
`SessionSelector`, `PowerButtons`, `KeyboardSelector`, `Notification`,
`Background`, `WallpaperEngine`, `ThemeConfig`, `ThemeProvider`,
`AnimationManager`, `SoundManager`, `ThemeLoader`, `BlurEffect`,
`GlowEffect`, `Particles`, polices et icônes partagées.

`Button` a été formalisé lors de la revue Phase 0.6
(`Architecture-Review.md`) : il était déjà utilisé comme exemple dans
DT-0002 (`ThemeButton extends NebulaButton`) sans jamais avoir été
documenté comme composant réel — corrigé dans `Core-API.md` et
`Specifications-Techniques.md`.

`Avatar` a été extrait de `UserList` (réutilisable seul, par exemple pour un
futur écran mono-utilisateur) et `ThemeProvider` a été ajouté comme
intermédiaire obligatoire entre `ThemeConfig`/`ThemeLoader` et les
composants — voir DT-0006 et [`Theme-System.md`](Theme-System.md).

Contrat détaillé de chaque composant :
[`Specifications-Techniques.md`](Specifications-Techniques.md). Contrat
d'API public (propriétés, signaux, dépendances) : [`Core-API.md`](Core-API.md).
Vocabulaire des valeurs visuelles (couleurs, spacing, radius, typography,
animation, effets) : [`Design-System.md`](Design-System.md).

### 5.4 Objectifs non fonctionnels

- KDE Plasma 6, Qt6, SDDM 0.21+.
- Wayland en priorité, X11 compatible.
- HiDPI et multi-écran.
- 60 FPS, animations fluides et discrètes.
- Faible empreinte mémoire, démarrage rapide.
- Zéro warning QML.
- Aucune animation active ne tourne quand elle n'est pas visible à
  l'écran (pas d'animation permanente en arrière-plan d'un composant
  masqué).

### 5.5 Priorités de conception

En cas d'arbitrage, l'ordre de priorité est :

1. Stabilité
2. Performance
3. Maintenabilité
4. Accessibilité
5. Beauté

Ne jamais sacrifier la performance uniquement pour un effet visuel.

## 6. Critère de réussite du Core

Créer un nouveau thème doit se limiter à ajouter, dans `themes/<nom>/` :

- un fichier de configuration du thème (couleurs, tokens du Design System) ;
- un fichier de layout ;
- ses assets propres (fonds d'écran, icônes spécifiques).

**Sans jamais modifier `core/`.** Si un nouveau thème nécessite de modifier
le Core, c'est le signe que l'architecture doit être revue — pas que le
thème doit contourner le Core (voir DT-0002). Ce critère est le test
décisif de la réussite de la séparation Core/Thèmes.

## 7. Modules Qt6 privilégiés

Voir DT-0007 dans [`Decisions-Techniques.md`](Decisions-Techniques.md) pour
la liste des modules QML privilégiés (`QtQuick`, `QtQuick.Controls`,
`QtQuick.Shapes`, `ShaderEffect`) et de ceux à éviter.

## 8. Ce que chaque thème doit fournir

Obligatoire : écran de connexion, champ mot de passe, sélecteur
utilisateur, sélecteur de session, sélecteur de disposition clavier,
horloge, date, arrêt, redémarrage, veille, états de focus accessibles.

Optionnel : fond animé, effets GPU, météo, batterie, nom d'hôte, diaporama
de fonds d'écran.

## 9. Hors périmètre (pour l'instant)

- Éditeur de thème graphique, aperçu live, système de plugins, moteur de
  wallpaper avancé, bibliothèque de shaders, marketplace en ligne,
  installeur/updater de thème : voir [`Roadmap.md`](Roadmap.md), section
  vision long terme. Ne pas concevoir le Core pour ces besoins tant qu'ils
  ne sont pas planifiés dans une phase active.
