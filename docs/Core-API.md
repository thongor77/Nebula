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

### NebulaThemeLoader

- **Responsabilité** : détecte et charge le thème actif au démarrage.
- **Inputs** : nom du thème actif (fourni par la configuration SDDM).
- **Outputs** : une instance de `NebulaThemeConfig` peuplée, ou un thème de
  repli en cas d'échec.
- **Properties** : `themeName` (string, lecture seule), `loaded` (bool),
  `loadError` (string, vide si aucune erreur).
- **Signals** : `themeLoaded()`, `themeLoadFailed(reason: string)`.
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
- **Dependencies** : `NebulaThemeProvider`.

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
- **Inputs** : propriété de contexte réelle `userModel` exposée par SDDM
  (confirmée par `Prototype-Results.md` §3.2 : `userModel.lastUser`,
  `userModel.lastIndex`).
- **Outputs** : utilisateur sélectionné.
- **Properties** : `model` (liste), `currentIndex` (int), `currentUser`
  (lecture seule).
- **Signals** : `userSelected(user)`.
- **Dependencies** : `NebulaAvatar`, `NebulaThemeProvider`.

### NebulaPasswordField

- **Responsabilité** : saisir le mot de passe et déclencher
  l'authentification.
- **Inputs** : saisie clavier.
- **Outputs** : tentative d'authentification transmise à SDDM via
  `sddm.login(username, password, sessionIndex)` (propriété de contexte
  réelle `sddm`, confirmée par `Prototype-Results.md` §3.2 ; jamais
  stockée par le composant).
- **Properties** : `placeholderText` (string), `hasError` (bool),
  `isBusy` (bool, pendant l'authentification).
- **Signals** : `submitted(password: string)`, `cleared()`.
- **Dependencies** : `NebulaThemeProvider`.

### NebulaSessionSelector

- **Responsabilité** : choisir la session à lancer.
- **Inputs** : propriété de contexte réelle `sessionModel` exposée par
  SDDM (confirmée par `Prototype-Results.md` §3.2 : `sessionModel.lastIndex`),
  peuplée à partir des fichiers `.desktop` de
  `/usr/share/wayland-sessions/` et `/usr/share/xsessions/`.
- **Outputs** : session sélectionnée.
- **Properties** : `model` (liste), `currentIndex` (int), `currentSession`
  (lecture seule).
- **Signals** : `sessionSelected(session)`.
- **Dependencies** : `NebulaThemeProvider`.

### NebulaKeyboardSelector

- **Responsabilité** : choisir la disposition clavier avant connexion.
- **Inputs** : propriété de contexte réelle `keyboard` exposée par SDDM
  (confirmée par `Prototype-Results.md` §3.2 : `keyboard.currentLayout`,
  `keyboard.layouts` — array d'objets avec `.longName`).
- **Outputs** : disposition sélectionnée.
- **Properties** : `model` (liste), `currentIndex` (int), `currentLayout`
  (lecture seule).
- **Signals** : `layoutSelected(layout)`.
- **Dependencies** : `NebulaThemeProvider`.

### NebulaPowerButtons

- **Responsabilité** : exposer les actions arrêt / redémarrage / veille.
- **Inputs** : propriété de contexte réelle `sddm` exposée par SDDM
  (confirmée par `Prototype-Results.md` §3.2 : `sddm.canHibernate`,
  `sddm.canSuspend`, `sddm.canReboot`, `sddm.canPowerOff`, et les méthodes
  `sddm.hibernate()`/`suspend()`/`reboot()`/`powerOff()`). La veille n'est
  pas toujours disponible (`can*` à `false` selon la plateforme).
- **Outputs** : déclenchement d'une action système.
- **Properties** : `canShutdown` (bool), `canReboot` (bool),
  `canSuspend` (bool), `confirmBeforeAction` (bool).
- **Signals** : `shutdownRequested()`, `rebootRequested()`,
  `suspendRequested()`.
- **Dependencies** : `NebulaButton` (chaque action est un `NebulaButton`
  configuré), `NebulaThemeProvider`.

### NebulaBackground

- **Responsabilité** : afficher le fond d'écran simple (image statique ou
  fond animé basique).
- **Inputs** : source d'image / paramètres du thème.
- **Outputs** : rendu du fond.
- **Properties** : `source` (url), `fillMode` (enum), `dimmed` (bool).
- **Signals** : aucun.
- **Dependencies** : `NebulaThemeProvider`.

### NebulaWallpaperEngine

- **Responsabilité** : gestion avancée de fond (diaporama, vidéo, shader),
  distincte du cas simple géré par `NebulaBackground`.
- **Inputs** : liste de sources, mode de rotation.
- **Outputs** : rendu de fond avancé.
- **Properties** : `sources` (liste), `rotationInterval` (int), `mode`
  (enum : `slideshow` / `video` / `shader`).
- **Signals** : `sourceChanged(index: int)`.
- **Dependencies** : `NebulaBackground`, `NebulaThemeProvider`.

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
