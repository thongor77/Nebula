# Core API — Nebula

> Contrat public du Core : ce que les thèmes peuvent attendre de chaque
> composant. Ce document décrit l'**API** (inputs, outputs, propriétés,
> signaux, dépendances autorisées) ; pour le rôle général et les
> contraintes de chaque composant, voir
> [`Specifications-Techniques.md`](Specifications-Techniques.md). Pour le
> vocabulaire des valeurs visuelles, voir
> [`Design-System.md`](Design-System.md). Pour le flux de theming, voir
> [`Theme-System.md`](Theme-System.md).
>
> Aucune implémentation ici — uniquement le contrat que l'implémentation
> devra respecter (Phase 1, voir `Roadmap.md`).

---

## 1. Principes

- Les thèmes consomment le Core. Le Core ne dépend **jamais** d'un thème.
- Chaque composant Core doit être indépendant : utilisable seul, sans
  présupposer la présence d'un autre composant Core dans l'arbre QML.
- Aucun composant Core ne doit contenir de logique spécifique à un thème
  (`if (themeName === "cyberpunk")` ou équivalent est interdit). Tout ce
  qui varie par thème passe par des propriétés exposées via
  `NebulaThemeProvider` (voir DT-0006), jamais par une branche de code
  conditionnelle sur l'identité du thème.
- Toute propriété publique documentée dans ce fichier est un contrat :
  la faire évoluer de façon incompatible (renommage, changement de type,
  suppression) est une rupture d'API et doit être tracée dans
  [`Decisions-Techniques.md`](Decisions-Techniques.md).
- Aucun composant Core ne dialogue directement avec SDDM (`sddm.login()`,
  `sddm.powerOff()`, `userModel`, `sessionModel`, ...) — uniquement via
  les Services (`core/services/`, Phase 1.4). Voir
  [`Services-Architecture.md`](Services-Architecture.md) et
  [`Nebula-Principles.md`](Nebula-Principles.md).

## 2. Convention d'un composant

Chaque composant Core documenté ci-dessous suit ce modèle :

```text
NebulaComponentName

Responsabilité : ce que fait le composant, en une phrase.

Inputs        : ce que le composant reçoit (système, utilisateur, thème).
Outputs       : ce que le composant produit ou déclenche.
Properties    : API publique en lecture (et écriture si applicable).
Signals       : événements émis vers le composant parent (thème).
Dependencies  : autres composants Core dont il dépend (jamais un thème).
```

Les noms de composants utilisés ici sont les noms canoniques déjà établis
dans `Specifications-Techniques.md` (ex. `NebulaWallpaperEngine`,
`NebulaBlurEffect`, `NebulaGlowEffect`) plutôt que des formes raccourcies,
pour rester cohérent avec le reste de la documentation.

## 3. Composants Core

### NebulaThemeConfig

- **Responsabilité** : conteneur des valeurs résolues du thème actif.
- **Inputs** : résultat du chargement effectué par `NebulaThemeLoader`.
- **Outputs** : valeurs de tokens en lecture seule (voir `Design-System.md`).
- **Properties** : groupes de valeurs par catégorie de token — `colors.*`,
  `spacing.*`, `radius.*`, `typography.*`, `animation.*`, `effects.*`.
  Liste exhaustive des noms : `Design-System.md`.
- **Signals** : aucun prévu en v1 (pas de rechargement à chaud — voir
  `Architecture.md`, Inconnues critiques).
- **Dependencies** : aucune.

### NebulaThemeLoader (implémenté en Phase 2.0.5)

- **Responsabilité** : seul composant autorisé à lire `theme.conf` et à
  peupler un `NebulaThemeConfig` — voir
  [`ThemeLoader.md`](ThemeLoader.md) pour le détail complet (cycle de
  chargement, stratégie de validation, piège des signaux au premier
  chargement).
- **Inputs** : `configPath` (url) — chemin direct vers un `theme.conf`,
  résolu par le thème lui-même (`Qt.resolvedUrl("theme.conf")`), **pas**
  un nom de thème résolu via SDDM (contrat initial, pré-implémentation,
  révisé : lire la propriété de contexte SDDM `config` directement
  romprait `Nebula-Principles.md` §2 — voir `ThemeLoader.md` §3).
- **Outputs** : une instance de `NebulaThemeConfig` peuplée (`config`),
  ou ses valeurs par défaut inchangées en cas d'échec.
- **Properties** : `configPath` (url), `config` (`NebulaThemeConfig`,
  lecture seule), `themeName` (string, lecture seule, informatif), `loaded`
  (bool, lecture seule), `loadError` (string, lecture seule).
- **Methods** : `reload()`.
- **Signals** : `themeLoaded()`, `themeLoadFailed(reason: string)` — ne
  pas s'y fier pour le tout premier chargement, voir `ThemeLoader.md` §6.
- **Dependencies** : `NebulaThemeConfig`.

### NebulaThemeProvider

- **Responsabilité** : unique point d'accès au theming pour tous les
  composants visuels (voir DT-0006).
- **Inputs** : `NebulaThemeConfig` résolu par `NebulaThemeLoader`.
- **Outputs** : tokens exposés en lecture seule à tout composant qui
  l'importe.
- **Properties** : mêmes groupes que `NebulaThemeConfig` (`colors`,
  `spacing`, `radius`, `typography`, `animation`, `effects`), exposés en
  lecture seule et stables même si le mécanisme de stockage sous-jacent
  change (DT-0003).
- **Signals** : aucun prévu en v1 ; à réévaluer si le rechargement à chaud
  est validé.
- **Dependencies** : `NebulaThemeConfig`, `NebulaThemeLoader`.

### NebulaAuthService (Phase 1.4)

- **Responsabilité** : unique point d'accès à l'authentification pour
  tous les composants (voir [`Services-Architecture.md`](Services-Architecture.md)).
- **Inputs** : `adapter` (duck-typé — voir `Services-Architecture.md`).
- **Outputs** : succès/échec de l'authentification.
- **Properties** : `authenticating` (bool, lecture seule), `errorMessage`
  (string, lecture seule).
- **Signals** : `succeeded()`, `failed(reason: string)`.
- **Dependencies** : un `adapter` (mock en test, `SDDMAuthAdapter` en
  production — jamais SDDM directement, voir
  [`Nebula-Principles.md`](Nebula-Principles.md) §4).

### NebulaUserService (Phase 1.4)

- **Responsabilité** : unique point d'accès aux données utilisateur.
- **Inputs** : `adapter` (duck-typé).
- **Outputs** : utilisateur(s) courant(s).
- **Properties** : `users` (liste, lecture seule), `currentUser` (objet,
  lecture seule).
- **Signals** : aucun en Phase 1.4 (pas de rechargement réactif —
  `refresh()` existe mais rien n'observe encore son résultat).
- **Dependencies** : un `adapter`.

### NebulaSessionService (Phase 1.4)

- **Responsabilité** : unique point d'accès aux sessions disponibles.
- **Inputs** : `adapter` (duck-typé).
- **Outputs** : session sélectionnée.
- **Properties** : `sessions` (liste, lecture seule), `currentIndex`
  (int, lecture seule).
- **Signals** : `sessionChanged(index: int)`.
- **Dependencies** : un `adapter`.

### NebulaPowerService (Phase 1.4)

- **Responsabilité** : unique point d'accès aux actions d'alimentation
  système.
- **Inputs** : `adapter` (duck-typé).
- **Outputs** : déclenchement d'une action système (délégué à l'adapter).
- **Properties** : `canShutdown`, `canReboot`, `canSuspend` (bool,
  lecture seule).
- **Signals** : aucun.
- **Dependencies** : un `adapter`. Les actions sont no-op si la capacité
  correspondante est `false`, même si l'adapter laisserait autrement
  passer l'appel (sécurité côté service, pas seulement côté UI).

### NebulaClock

- **Responsabilité** : afficher l'heure courante, mise à jour automatique.
- **Inputs** : horloge système (`Timer` interne, 1 s).
- **Outputs** : texte d'heure formaté.
- **Properties** : `use24HourFormat` (bool), `showSeconds` (bool), `format`
  (string, vide par défaut — voir Phase 1.2 dans
  `Core-Implementation-Status.md` : si non vide, remplace entièrement le
  format dérivé de `use24HourFormat`/`showSeconds`).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider` (typography, colors).

### NebulaDate

- **Responsabilité** : afficher la date courante, respecte la locale
  système par défaut.
- **Inputs** : date système (`Timer` interne, 60 s — suffisant pour
  capturer le changement de jour sans logique de planification dédiée).
- **Outputs** : texte de date formaté.
- **Properties** : `dateFormat` (string), `locale` (string, vide par
  défaut = locale système, via `Qt.formatDate` sans `Locale` explicite).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider`.

### NebulaButton

- **Responsabilité** : bouton interactif générique, brique de base
  réutilisable pour toute action.
- **Inputs** : interaction utilisateur (clic, activation clavier).
- **Outputs** : déclenchement d'une action.
- **Properties** : `label` (string), `icon` (url), `enabled` (bool),
  `variant` (enum : `primary` / `secondary` / `ghost`, liée aux tokens de
  couleur du Design System).
- **Signals** : `clicked()`.
- **Dependencies** : `NebulaThemeProvider` (colors, spacing, radius,
  typography, animation, et depuis la Phase 1.6 le groupe `interaction` —
  voir `Design-Tokens-Reference.md`).

### NebulaAvatar

- **Responsabilité** : afficher l'avatar d'un utilisateur, avec repli sur
  une icône générique, ou à défaut une silhouette générique sans aucun
  asset externe requis (testé réellement — voir
  `Core-Implementation-Status.md`, Phase 1.2).
- **Inputs** : `source` (chemin de l'image utilisateur).
- **Outputs** : image rendue, découpée selon `radius`.
- **Properties** : `source` (url), `fallbackIcon` (url), `size` (real),
  `radius` (real, par défaut `theme.radius.radiusPill` — un thème peut le
  surcharger pour un avatar carré aux coins arrondis plutôt que circulaire).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider` (radius, couleurs de repli).

### NebulaUserList

- **Responsabilité** : lister les utilisateurs disponibles et gérer la
  sélection.
- **Inputs** : `NebulaUserService` (voir
  [`Services-Architecture.md`](Services-Architecture.md)) — **jamais**
  `userModel` directement depuis la Phase 1.4 (voir
  [`Nebula-Principles.md`](Nebula-Principles.md) §4). Le service
  lui-même est adossé, en dernier ressort, à la propriété de contexte
  réelle `userModel` exposée par SDDM (`userModel.lastUser`,
  `userModel.lastIndex` — confirmée par `Prototype-Results.md` §3.2), via
  `platform/sddm/SDDMUserAdapter.qml`.
- **Outputs** : utilisateur sélectionné.
- **Properties** : `model` (liste), `currentIndex` (int), `currentUser`
  (lecture seule).
- **Signals** : `userSelected(user)`.
- **Dependencies** : `NebulaAvatar`, `NebulaThemeProvider`,
  `NebulaUserService`.

### NebulaPasswordField

- **Responsabilité** : saisir le mot de passe et déclencher
  l'authentification.
- **Inputs** : saisie clavier.
- **Outputs** : tentative d'authentification transmise via
  `NebulaAuthService.authenticate(username, password)` (voir
  [`Services-Architecture.md`](Services-Architecture.md)) — **jamais**
  `sddm.login()` directement depuis la Phase 1.4 (voir
  [`Nebula-Principles.md`](Nebula-Principles.md) §4). Le service
  lui-même délègue, en dernier ressort, à `sddm.login(username, password,
  sessionIndex)` (propriété de contexte réelle `sddm`, confirmée par
  `Prototype-Results.md` §3.2) via `platform/sddm/SDDMAuthAdapter.qml`.
  Jamais stockée par le composant.
- **Properties** : `placeholderText` (string), `hasError` (bool),
  `isBusy` (bool, pendant l'authentification — reflète
  `NebulaAuthService.authenticating`).
- **Signals** : `submitted(password: string)`, `cleared()`.
- **Dependencies** : `NebulaThemeProvider`, `NebulaAuthService`.

### NebulaSessionSelector

- **Responsabilité** : choisir la session à lancer.
- **Inputs** : `NebulaSessionService` (voir
  [`Services-Architecture.md`](Services-Architecture.md)) — **jamais**
  `sessionModel` directement depuis la Phase 1.4. Le service lui-même est
  adossé, en dernier ressort, à la propriété de contexte réelle
  `sessionModel` exposée par SDDM (`sessionModel.lastIndex`, peuplée à
  partir des fichiers `.desktop` de `/usr/share/wayland-sessions/` et
  `/usr/share/xsessions/` — confirmée par `Prototype-Results.md` §3.2),
  via `platform/sddm/SDDMSessionAdapter.qml`.
- **Outputs** : session sélectionnée.
- **Properties** : `model` (liste), `currentIndex` (int), `currentSession`
  (lecture seule).
- **Signals** : `sessionSelected(session)`.
- **Dependencies** : `NebulaThemeProvider`, `NebulaSessionService`.

### NebulaKeyboardSelector

- **Responsabilité** : choisir la disposition clavier avant connexion.
- **Inputs** : propriété de contexte réelle `keyboard` exposée par SDDM
  (confirmée par `Prototype-Results.md` §3.2 : `keyboard.currentLayout`,
  `keyboard.layouts` — array d'objets avec `.longName`). Contrairement aux
  autres composants d'intégration SDDM, aucun Service dédié n'a été
  introduit en Phase 1.4 pour la disposition clavier — à réévaluer si ce
  composant est implémenté avant qu'un besoin réel de Service apparaisse
  (voir principe de travail du workspace, pas d'abstraction anticipée).
- **Outputs** : disposition sélectionnée.
- **Properties** : `model` (liste), `currentIndex` (int), `currentLayout`
  (lecture seule).
- **Signals** : `layoutSelected(layout)`.
- **Dependencies** : `NebulaThemeProvider`.

### NebulaPowerButtons

- **Responsabilité** : exposer les actions arrêt / redémarrage / veille.
- **Inputs** : `NebulaPowerService` (voir
  [`Services-Architecture.md`](Services-Architecture.md)) — **jamais**
  `sddm.powerOff()`/`reboot()`/`hibernate()` directement depuis la
  Phase 1.4 (voir [`Nebula-Principles.md`](Nebula-Principles.md) §4/§6).
  Le service lui-même délègue, en dernier ressort, à
  `sddm.canHibernate`/`canSuspend`/`canReboot`/`canPowerOff` et
  `sddm.hibernate()`/`suspend()`/`reboot()`/`powerOff()` (confirmés par
  `Prototype-Results.md` §3.2) via `platform/sddm/SDDMPowerAdapter.qml`.
  La veille n'est pas toujours disponible (`can*` à `false` selon la
  plateforme).
- **Outputs** : déclenchement d'une action système.
- **Properties** : `canShutdown` (bool), `canReboot` (bool),
  `canSuspend` (bool), `confirmBeforeAction` (bool).
- **Signals** : `shutdownRequested()`, `rebootRequested()`,
  `suspendRequested()`.
- **Dependencies** : `NebulaButton` (chaque action est un `NebulaButton`
  configuré), `NebulaThemeProvider`, `NebulaPowerService`.

### NebulaLoginLayout

- **Responsabilité** : squelette commun d'un écran de connexion — quatre
  zones (fond, contenu principal, statut, pied de page), géométrie
  uniquement (marges, espacements, dimensionnement responsive). Aucune
  couleur, aucun asset, aucune logique SDDM (voir §1).
- **Inputs** : contenu placé par le thème dans chaque zone.
- **Outputs** : positionnement des zones.
- **Properties** : `wallpaperContent`, `mainContent` (zone par défaut),
  `statusContent`, `footerContent` — chacune un point d'insertion de
  contenu (`property alias ... : zone.data`), pas une propriété de valeur
  simple.
- **Contrat** : le contenu placé dans `mainContent`/`statusContent` doit
  se centrer horizontalement uniquement (jamais `anchors.centerIn`) — ces
  zones dimensionnent leur hauteur sur leur propre contenu, voir
  `docs/Development-Journal.md` (Phase 1.3).
- **Limitation connue** : pas de gestion du débordement vertical sur une
  fenêtre à ratio extrême (très basse et large) — voir
  `docs/Development-Journal.md`.
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider` (spacing uniquement).

### NebulaBackground (contrat révisé en Phase 1.5)

- **Responsabilité** : racine visuelle d'un écran — occupe toute la
  surface disponible et accueille les autres couches visuelles
  (`NebulaWallpaper`, `NebulaOverlay`, `NebulaLoginLayout`, ...) comme de
  simples enfants. Ne contient plus de logique d'image ni de couleur
  propre depuis la Phase 1.5 (voir DT-0012 dans
  `Decisions-Techniques.md` — l'ancien contrat `source`/`fillMode`/
  `dimmed`, documenté en Phase 0.6, n'a jamais été implémenté et a été
  déplacé vers `NebulaWallpaper`).
- **Inputs** : aucun.
- **Outputs** : aucun — conteneur pur.
- **Properties** : aucune propriété spécifique (hérite des propriétés
  standard d'un `Item`).
- **Signals** : aucun.
- **Dependencies** : aucune.
- **Contrainte d'usage** : utilise `anchors.fill: parent` en interne — ne
  peut donc pas être placé comme enfant direct d'un `Row`/`Column`/`Grid`
  (positionneurs Qt Quick qui interdisent `fill`/`centerIn` sur leurs
  enfants). Trouvé en testant, voir `Development-Journal.md`, Phase 1.5.

### NebulaWallpaper (Phase 1.5)

- **Responsabilité** : afficher une image de fond simple, avec repli sur
  une couleur unie si l'image est absente ou échoue à charger.
- **Inputs** : `source` (chemin de l'image).
- **Outputs** : rendu de l'image, ou de la couleur de repli
  (`theme.colors.backgroundColor`) si `source` est vide ou en échec.
- **Properties** : `source` (url), `mode` (enum : `fill` / `fit` / `crop`,
  correspond à `Image.fillMode`).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider`.
- **Hors périmètre (Phase 1.5)** : diaporama, vidéo, image distante —
  voir `NebulaWallpaperEngine` ci-dessous, qui prendra le relais pour ces
  cas avancés.

### NebulaWallpaperEngine

- **Responsabilité** : gestion avancée de fond (diaporama, vidéo, shader),
  distincte du cas simple géré par `NebulaWallpaper` depuis la Phase 1.5.
- **Inputs** : liste de sources, mode de rotation.
- **Outputs** : rendu de fond avancé.
- **Properties** : `sources` (liste), `rotationInterval` (int), `mode`
  (enum : `slideshow` / `video` / `shader`).
- **Signals** : `sourceChanged(index: int)`.
- **Dependencies** : `NebulaWallpaper`, `NebulaThemeProvider`.

### NebulaOverlay (Phase 1.5)

- **Responsabilité** : voile visuel plat par-dessus une autre couche
  (typiquement `NebulaWallpaper`) pour améliorer la lisibilité du texte.
  Aucun flou, aucun `ShaderEffect` — remplissage uni ou dégradé à deux
  arrêts uniquement (voir `Rendering-Guidelines.md`).
- **Inputs** : aucun.
- **Outputs** : rendu du voile.
- **Properties** : `useGradient` (bool), `color1`/`color2` (color, arrêts
  du dégradé si activé).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider` (token `overlay.overlayOpacity`).

### NebulaSurface (Phase 1.5)

- **Responsabilité** : panneau générique derrière tout contenu de type
  carte (panneau de connexion, carte utilisateur, boîte de dialogue,
  futur menu de session). Gère uniquement padding, radius, bordure,
  opacité et une ombre plate optionnelle (aucun flou/`ShaderEffect`, voir
  `Rendering-Guidelines.md`).
- **Inputs** : contenu placé via la zone par défaut (`default property`).
- **Outputs** : rendu du panneau.
- **Properties** : `padding` (real, défaut `spacing.spacingMd`), `radius`
  (real, défaut `radius.radiusLarge`), `borderWidth` (real, défaut
  `surface.surfaceBorderWidth`), `borderColor` (color), `surfaceColor`
  (color, défaut `colors.surfaceColor`), `shadowEnabled` (bool, défaut
  `false`), `shadowColor` (color), `shadowOffset` (real), `shadowOpacity`
  (real, défaut `0.25` — promue de valeur inline codée en dur à propriété
  en Phase 1.6, voir `Design-Tokens-Reference.md`).
- **Contrat** : se dimensionne pour épouser exactement son contenu — le
  contenu ne doit jamais se centrer avec `anchors.centerIn: parent`
  (même contrainte que les zones de `NebulaLoginLayout`, voir DT-0011).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider` (spacing, radius, colors,
  token `surface.surfaceOpacity`/`surfaceBorderWidth`). Ne réutilise
  volontairement pas de tokens `surfaceRadius`/`surfacePadding` dédiés —
  voir DT-0013 dans `Decisions-Techniques.md`.

### NebulaBlurEffect

- **Responsabilité** : effet de flou GPU optionnel.
- **Inputs** : contenu à flouter (élément QML cible).
- **Outputs** : rendu flouté.
- **Properties** : `amount` (real, lié au token `effects.blurAmount`),
  `enabled` (bool).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider` ; doit respecter le token
  global `effects.enableEffects` (voir `Design-System.md`).

### NebulaGlowEffect

- **Responsabilité** : effet de lueur GPU optionnel.
- **Properties** : `intensity` (real, lié à `effects.glowIntensity`),
  `color` (color), `enabled` (bool).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider` ; respecte `effects.enableEffects`.

### NebulaParticles

- **Responsabilité** : système de particules GPU optionnel.
- **Properties** : `density` (real, lié à `effects.particleDensity`),
  `enabled` (bool).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider` ; respecte `effects.enableEffects`.
  Contrainte de performance forte — voir `Architecture.md`, Inconnues
  critiques.

### NebulaAnimationManager

- **Responsabilité** : point d'entrée unique pour déclencher des
  animations cohérentes, plutôt que des `Behavior`/`Animation` ad-hoc.
- **Inputs** : cible à animer, nom du token de durée/courbe.
- **Outputs** : animation exécutée avec les valeurs du thème actif.
- **Properties** : expose les tokens `animation.durationFast`,
  `animation.durationNormal`, `animation.durationSlow` (voir
  `Design-System.md`).
- **Signals** : aucun prévu en v1.
- **Dependencies** : `NebulaThemeProvider`.

### NebulaNotification

- **Responsabilité** : afficher des messages système (erreur
  d'authentification, information SDDM).
- **Properties** : `message` (string), `severity` (enum :
  `info`/`error`/`success`), `visible` (bool), `autoHideDuration` (int,
  lié à un token d'animation).
- **Signals** : `dismissed()`.
- **Dependencies** : `NebulaThemeProvider`.

### NebulaSoundManager

- **Responsabilité** : jouer des sons d'interface optionnels (connexion,
  erreur), désactivable sans erreur si aucun son n'est configuré.
- **Properties** : `enabled` (bool).
- **Signals** : aucun (déclenchement par méthode conceptuelle
  `play(eventName)`, à préciser en Phase 1).
- **Dependencies** : `NebulaThemeProvider` (chemins de sons résolus via
  `NebulaThemeConfig`).

## 4. Composants non couverts par ce contrat

Polices et icônes partagées (`core/assets/`) ne sont pas des composants
QML et n'ont donc pas de contrat API — voir
`Specifications-Techniques.md` pour leur rôle.
