# Rendering Guidelines — Nebula

> Bonnes pratiques de rendu QML pour le Core, éléments graphiques
> autorisés et interdits. Complète
> [`Core-API.md`](Core-API.md) et [`Architecture.md`](Architecture.md)
> §5.4 (objectifs non fonctionnels), et sert de référence pour toute
> future contribution à `core/components/`.

---

## 1. Principe

Le Core définit le comportement et les contrats visuels ; les thèmes
définissent les couleurs, images, effets et animations (voir
[`Nebula-Principles.md`](Nebula-Principles.md)). Ce document fixe ce que
le **Core** a le droit d'utiliser pour rester rapide et prévisible
indépendamment du thème qui l'habillera.

## 2. Primitives autorisées dans le Core

- `Rectangle` (couleur, bordure, radius)
- `Gradient` / `GradientStop` (remplissage dégradé plat, pas un effet)
- `Image` (avec repli documenté — voir `NebulaWallpaper`, `NebulaAvatar`)
- `Text`
- `MouseArea` (interaction simple ; `TapHandler` reste une option future
  si un besoin réel apparaît)
- `opacity`, `Behavior`/`NumberAnimation`/`ColorAnimation` pour des
  transitions **discrètes et ponctuelles** (voir §4)
- `QtQuick.Layouts` (`Row`, `Column`, `Grid` et leurs équivalents
  `Layouts`) pour la disposition

## 3. Interdit dans le Core

- `ShaderEffect`
- `MultiEffect` / `Qt5Compat.GraphicalEffects` (blur, drop shadow flou)
- Effets de particules
- Tout effet GPU complexe en général

Ces éléments appartiennent aux thèmes (`NebulaBlurEffect`,
`NebulaGlowEffect`, `NebulaParticles` — Phase 3, voir `Roadmap.md`), pas
au Core. Un composant Core qui a besoin d'un rendu de ce type doit rester
utilisable **sans** lui (voir `SDDM-Compatibility.md` : le coût réel de
ces effets n'est pas encore mesuré).

### Conséquence concrète : ombre plate, pas de flou

`NebulaSurface` propose une ombre optionnelle (`shadowEnabled`), mais
c'est une approximation **plate** (un `Rectangle` légèrement décalé, pas
un flou gaussien). C'est un compromis assumé : un vrai flou nécessiterait
`ShaderEffect`/`MultiEffect`, explicitement exclus du Core. Un thème qui
veut une ombre douce devra composer son propre effet par-dessus, hors du
Core.

## 4. Animations

- Autorisées : transitions ponctuelles déclenchées par une interaction
  (`NebulaButton` : `Behavior on scale`/`color` au clic — voir
  `Core-Implementation-Status.md`, Phase 1.1).
- Interdites dans le Core : toute animation qui tourne en continu sur un
  composant non visible ou inactif (voir `Architecture.md` §5.4).
- Les durées viennent toujours de `theme.animation.*` (jamais une valeur
  codée en dur) — voir DT-0006.

## 5. Contraintes de composition trouvées en testant (Phase 1.5)

- **`anchors.fill: parent` incompatible avec les positionneurs.** Un
  composant qui utilise `anchors.fill: parent` en interne
  (`NebulaBackground`, `NebulaLoginLayout`) ne peut pas être placé comme
  enfant direct d'un `Row`/`Column`/`Grid` — Qt Quick l'interdit
  explicitement (`Row will not function`). Trouvé en testant, voir
  `Development-Journal.md`, Phase 1.5.
- **Pas de `anchors.centerIn` dans une zone "hug content".** Un composant
  qui dimensionne une zone sur `childrenRect` (`NebulaLoginLayout`,
  `NebulaSurface`) ne doit jamais recevoir un enfant qui se centre avec
  `anchors.centerIn: parent` — boucle de binding garantie (le parent se
  dimensionne sur l'enfant, l'enfant se positionne sur la taille du
  parent). Utiliser `anchors.horizontalCenter`/`verticalCenter` seul si
  nécessaire, ou ne pas ancrer du tout si la zone épouse déjà exactement
  la taille du contenu. Voir DT-0011 et `Development-Journal.md`,
  Phase 1.3.
- **Chaque nouveau groupe de tokens doit être répercuté dans
  `NebulaThemeProvider`.** Ajouter un groupe à `NebulaThemeConfig` ne
  suffit pas — `NebulaThemeProvider` expose chaque groupe individuellement
  et ne délègue pas génériquement. Un token non répercuté vaut
  `undefined` et fait échouer silencieusement tout binding qui le lit
  (voir `Development-Journal.md`, Phase 1.5).

## 6. Référence de performance (Phase 1.5)

Établie sur `tests/LoginScreenHarness.qml`, pas dans un but de
micro-optimisation mais comme point de comparaison pour les futures
phases (thèmes Glass/Cyberpunk/Hyprland) :

- **~52 objets QML instanciés** au démarrage (compte manuel depuis le
  code source, pas une trace `qmlprofiler` — voir méthodologie
  ci-dessous). Répartition approximative : 10 pour
  `NebulaThemeProvider`/`NebulaThemeConfig` (groupes de tokens), 5 pour
  les Services/Adapters mockés, le reste pour les couches visuelles
  (Background/Wallpaper/Overlay/Layout/Surface) et les composants
  fonctionnels (Avatar ~7 objets à cause du repli en silhouette,
  Button ~8 à cause de sa structure Row+Image+Text+MouseArea+2
  `Behavior`).
- **Deux `Timer` actifs en continu** : `NebulaClock` (1 s) et
  `NebulaDate` (60 s) — aucun autre. Cohérent avec la règle "pas de timer
  plus fréquent que nécessaire" (`Specifications-Techniques.md`).
- **Aucun binding par-frame identifié** en dehors de ces deux `Timer` —
  les autres propriétés calculées (`NebulaAvatar.hasImage`,
  `NebulaSurface.implicitWidth/Height` via `childrenRect`) ne se
  réévaluent que sur changement réel (chargement d'image, changement de
  contenu), pas en continu.
- **Méthodologie** : `qmlprofiler` est disponible sur la machine de test
  mais nécessite une configuration de debug QML plus lourde qu'utile pour
  une simple référence ; ce relevé vient d'une lecture directe du code
  réellement exécuté, pas d'une trace automatisée. À raffiner avec
  `qmlprofiler` si un besoin de diagnostic plus fin apparaît (ex.
  régression suspectée après l'ajout d'un thème à effets).
