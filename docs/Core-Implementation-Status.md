# Core Implementation Status — Nebula

> État d'avancement du Core MVP (voir [`Core-MVP.md`](Core-MVP.md) pour le
> périmètre complet, [`Roadmap.md`](Roadmap.md) pour l'ordre de
> construction). Mis à jour à chaque composant livré. Les découvertes
> techniques (bugs trouvés, causes, solutions) sont détaillées dans
> [`Development-Journal.md`](Development-Journal.md) — ce document-ci
> reste centré sur *quoi* est fait et *quelles* décisions ont été prises,
> pas sur le récit du débogage.

---

## 1. Composants terminés

### NebulaThemeConfig (`core/config/NebulaThemeConfig.qml`)

- Conteneur des valeurs résolues : `colors`, `spacing`, `radius`,
  `typography`, `animation` (groupes de propriétés imbriquées, voir
  [`Design-System.md`](Design-System.md)).
- Valeurs par défaut **volontairement génériques**, distinctes de la
  palette Nord — voir §3, décision D1.
- Validation simple : propriété `valid` (bool) vérifiant que chaque
  groupe contient des valeurs exploitables — pas un validateur de schéma
  complet (aucun besoin observé pour plus, voir principe de travail du
  workspace).
- Pas de dépendances. `qmllint` : aucun avertissement.

### NebulaThemeProvider (`core/theme/NebulaThemeProvider.qml`)

- Point d'accès unique consommé par les composants (voir DT-0006) :
  expose `colors`, `spacing`, `radius`, `typography`, `animation` en
  lecture, en enveloppant `NebulaThemeConfig`.
- `assets` exposé comme groupe vide en attendant `NebulaThemeLoader`
  (voir §3, décision D3).
- Tant que `NebulaThemeLoader` n'existe pas, les valeurs par défaut de
  `NebulaThemeConfig` **sont** le fallback — pas un cas séparé, exactement
  ce que décrit [`Theme-System.md`](Theme-System.md) §5.
- `qmllint` : aucun avertissement.

### NebulaButton (`core/components/NebulaButton.qml`)

- Testé réellement (voir §4) : couleurs par variante (`primary`,
  `secondary`, `ghost`), taille (`implicitWidth`/`implicitHeight` dérivés
  du contenu + tokens de spacing), radius (`theme.radius.radiusMedium`),
  état normal, état désactivé (`opacity`), état pressé (assombrissement +
  échelle), focus clavier visible (contour `accentColor`).
- Propriétés : `label`, `icon`, `variant`, `enabled` (héritée d'`Item`) ;
  signal `clicked()`.
- Dépendance : `NebulaThemeProvider` (propriété `required`, voir §3,
  décision D2).
- `qmllint` : aucun avertissement.

### NebulaAvatar (`core/components/NebulaAvatar.qml`) — Phase 1.2

- Testé réellement (voir §4) : image personnalisée (`source`, découpage
  `PreserveAspectCrop`), plusieurs tailles (`size`), radius personnalisable
  (`radius`, circulaire par défaut via `theme.radius.radiusPill`), et
  repli à deux niveaux — `fallbackIcon` fourni par le thème, sinon
  silhouette générique dessinée sans aucun asset externe (deux
  `Rectangle`).
- Propriétés : `source` (url), `fallbackIcon` (url), `size` (real),
  `radius` (real).
- Dépendance : `NebulaThemeProvider`.
- `qmllint` : aucun avertissement.

### NebulaClock (`core/components/NebulaClock.qml`) — Phase 1.2

- Testé réellement (voir §4) : mise à jour automatique (`Timer` 1 s),
  format 24h avec secondes (`hh:mm:ss`), token `typography.fontSizeClock`.
- Propriétés : `use24HourFormat` (bool), `showSeconds` (bool), `format`
  (string — voir §3, décision D7 pour la réconciliation avec le contrat
  déjà documenté).
- Dépendance : `NebulaThemeProvider`.
- `qmllint` : aucun avertissement.

### NebulaDate (`core/components/NebulaDate.qml`) — Phase 1.2

- Testé réellement (voir §4) : respect de la locale système par défaut
  (`Qt.formatDate` sans `Locale` explicite), format `"dddd d MMMM yyyy"`
  affiché correctement en anglais (locale système de la machine de test).
- Propriétés : `dateFormat` (string), `locale` (string, vide = système).
- Dépendance : `NebulaThemeProvider`.
- `qmllint` : aucun avertissement.

### NebulaLoginLayout (`core/layouts/NebulaLoginLayout.qml`) — Phase 1.3

- Testé réellement (voir §4) : quatre zones (`wallpaperContent`,
  `mainContent` par défaut, `statusContent`, `footerContent`), aucune
  couleur ni asset ni logique SDDM — géométrie seule (marges/espacements
  via tokens `spacing`).
- Responsive : dimensionnement relatif/pourcentage plutôt que coordonnées
  absolues, vérifié à plusieurs tailles/ratios (16:9 large, portrait
  étroit, `QT_SCALE_FACTOR=2`).
- Deux découvertes réelles pendant le test (bug de boucle de binding,
  limitation de débordement vertical sur ratio extrême) — voir
  [`Development-Journal.md`](Development-Journal.md), entrées Phase 1.3.
- Dépendance : `NebulaThemeProvider` (spacing uniquement).
- `qmllint` : aucun avertissement.

### NebulaAuthService / NebulaUserService / NebulaSessionService / NebulaPowerService (`core/services/`) — Phase 1.4

- Testés réellement (voir §4) : instanciation, délégation à un `adapter`
  injecté, cycle complet `authenticating` → `succeeded`/`failed` pour
  l'auth (round-trip asynchrone simulé par `tests/mocks/MockAuthAdapter.qml`).
- Contrat public uniquement — aucune connexion SDDM réelle (voir
  [`Services-Architecture.md`](Services-Architecture.md)).
- `platform/sddm/SDDM*Adapter.qml` créés en parallèle : squelettes,
  capacités par défaut à `false`/vides, aucune méthode n'agit réellement
  (`console.warn` à la place).
- `qmllint` : aucun avertissement (après correction, voir D12 ci-dessous).

### NebulaBackground / NebulaWallpaper / NebulaOverlay / NebulaSurface (`core/components/`) — Phase 1.5

- Testés réellement (voir §4) : image personnalisée + repli couleur
  (`NebulaWallpaper`), voile plat + dégradé (`NebulaOverlay`), panneau
  avec padding/radius/bordure + ombre plate optionnelle (`NebulaSurface`).
- `NebulaBackground` revu par rapport à son contrat Phase 0.6 (jamais
  implémenté) : devient un conteneur racine pur, sans propriété d'image
  — voir DT-0012.
- Deux bugs réels trouvés et corrigés pendant le test (voir §4 et
  `Development-Journal.md`) : contrainte `Row`/`anchors.fill`, et tokens
  `overlay`/`surface` non répercutés dans `NebulaThemeProvider`.
- `qmllint` : aucun avertissement sur les 4 fichiers.

### Design System Hardening — Phase 1.6

- Audit complet des 14 fichiers du Core (`core/config`, `core/theme`,
  `core/components`, `core/layouts`, `core/services`) à la recherche de
  valeurs codées en dur. Résultat détaillé et classification de chaque
  valeur trouvée : [`Design-Tokens-Reference.md`](Design-Tokens-Reference.md).
- Nouveau groupe de tokens `interaction` (`opacityDisabled`,
  `scalePressed`, `pressedDarkenFactor`, `borderWidthThin`,
  `borderWidthFocus`) ajouté à `NebulaThemeConfig`/`NebulaThemeProvider`
  — extrait de valeurs jusque-là codées en dur dans `NebulaButton`.
- `NebulaSurface.shadowOpacity` : promue de valeur inline codée en dur à
  propriété par instance, cohérente avec `shadowColor`/`shadowOffset`
  déjà existantes.
- `NebulaLoginLayout` : largeur responsive des zones Main
  Content/Status dédupliquée en une seule propriété interne
  (`_contentWidth`) au lieu d'être répétée deux fois.
- `tests/ThemeSyncCheck.qml` (nouveau) : vérifie automatiquement que tout
  groupe de tokens de `NebulaThemeConfig` est exposé par
  `NebulaThemeProvider` — testé réellement dans les deux sens (voir §4).
- `scripts/check-design-system.sh` (nouveau) : point d'entrée unique
  (`qmllint` + `ThemeSyncCheck` + harnais visuels) avant un commit.
- `qmllint` : aucun avertissement sur l'ensemble des fichiers modifiés.

### Phase 2.0 — Theme SDK Foundation

**Aucun fichier sous `core/` modifié cette phase** — c'était l'objectif :
prouver que le Core est déjà suffisant pour accueillir un thème, pas le
faire évoluer. Le SDK lui-même (`themes/template/`,
[`docs/Theme-SDK.md`](Theme-SDK.md), `docs/Creating-A-Theme.md`,
`scripts/check-theme.sh`, `tests/ThemeHarness.qml`) et les décisions
prises (fusion documentaire, retrait de `overrides/`, `metadata.desktop`,
pont temporaire `theme.conf`→`NebulaThemeConfig`) sont détaillés dans
[`Roadmap.md`](Roadmap.md) et
[`Decisions-Techniques.md`](Decisions-Techniques.md) (DT-0014 à DT-0017)
plutôt que répétés ici, puisqu'ils ne concernent pas `core/`. Deux bugs
réels trouvés et corrigés en testant sous `sddm-greeter --test-mode`
réel : voir [`Development-Journal.md`](Development-Journal.md).

### NebulaThemeLoader (`core/theme/NebulaThemeLoader.qml`) — Phase 2.0.5

- Résout DT-0017 (voir `Decisions-Techniques.md`) : unique responsable de
  la lecture de `theme.conf`, remplace `applyFlatValues()` dupliquée dans
  `themes/template/Main.qml`/`tests/ThemeHarness.qml` (retirée des deux).
- Lit `theme.conf` directement (jamais la propriété de contexte SDDM
  `config`) — voir `docs/ThemeLoader.md` §3 pour la justification
  architecturale (Core jamais dépendant de SDDM).
- Tolérant par construction : token inconnu journalisé et ignoré, token
  absent laisse la valeur par défaut du Core, valeur invalide détectée
  après assignation (`isNaN`, `color.valid`) et la valeur par défaut
  restaurée — jamais de crash, testé sur les 5 scénarios requis via
  `tests/ThemeLoaderHarness.qml` (voir §4).
- Deux bugs réels trouvés et corrigés pendant le développement (voir
  `Development-Journal.md`) : référence vivante au lieu d'une copie en
  capturant une propriété `color` dans une variable JS ; indistinction
  fichier vide/manquant/lectures désactivées (DT-0018).
- `qmllint` : aucun avertissement.

### Phase 2.1 — Nord Validation Theme

**Aucun fichier sous `core/` modifié cette phase** — objectif de la
phase : valider que le SDK/ThemeLoader/Design Tokens suffisent à
construire un thème réel sans faire évoluer le Core. `themes/nord/`
(nouveau) et les outils de diagnostic (`tests/ThemeInspector.qml`,
nouveau) sont détaillés dans [`Roadmap.md`](Roadmap.md) et
[`docs/Nord-Validation-Report.md`](Nord-Validation-Report.md) plutôt que
répétés ici. Constat majeur (non lié à `core/` mais à la distribution
d'un thème installé séparément du dépôt) : voir
`Nord-Validation-Report.md`, Constat #1, et
[`Compatibility-Matrix.md`](Compatibility-Matrix.md) §7.

### Phase 2.2 — Deployment & Installation Architecture

**Aucun fichier sous `core/` modifié cette phase** — objectif : résoudre
le Constat #1 de Nord (distribution) sans toucher au comportement des
composants (contrainte explicite du brief). Trois architectures
prototypées et testées réellement ; Solution B retenue (Core comme
module QML, chemin QML par défaut de Qt — aucune configuration système
requise). Détail complet dans
[`Deployment-Decision.md`](Deployment-Decision.md), DT-0022 dans
`Decisions-Techniques.md`, et [`Roadmap.md`](Roadmap.md) plutôt que
répété ici. Nouveaux scripts `scripts/install-nebula.sh`/
`uninstall-nebula.sh`/`check-installation.sh`, tous testés en conditions
réelles (installation, vérification, désinstallation complète). Vraies
découvertes techniques (chemin QML par défaut, modules à espace de noms
à points, `git safe.directory` sous root) : voir
[`Development-Journal.md`](Development-Journal.md).

### NebulaUserList / NebulaPasswordField / NebulaSessionSelector / NebulaPowerButtons (`core/components/`) — Phase 2.3

- Quatre nouveaux composants interactifs, tous dépendants uniquement de
  `NebulaThemeProvider` et d'un Service (jamais SDDM directement) — voir
  [`Login-Architecture.md`](Login-Architecture.md) pour le détail complet
  et le flux d'authentification.
- `NebulaPowerService` étendu avec `canHibernate`/`hibernate()` (DT-0019
  dans `Decisions-Techniques.md`), propagé à `SDDMPowerAdapter` (toujours
  un squelette) et `MockPowerAdapter`.
- Pas de nouveau type Core pour l'état d'authentification
  (Idle/Authenticating/Succeeded/Failed) — chaque composant reflète
  directement l'état déjà exposé par son Service (DT-0020).
- `NebulaPowerButtons.confirmBeforeAction` : confirmation en deux clics
  auto-contenue (pas de dialogue modal, `NebulaNotification` n'existe pas
  encore) — testée réellement (armement, exécution, expiration).
- Testés réellement en isolation puis ensemble via
  `tests/LoginWorkflowHarness.qml` (nouveau) : navigation clavier,
  sélection souris, soumission de mot de passe, changement de session,
  confirmation d'action d'alimentation — tous avec des Mock adapters.
- `themes/template/Main.qml` mis à jour pour les utiliser (référence SDK
  à jour) ; testé sous `sddm-greeter --test-mode` réel avec les vrais
  adapters `platform/sddm/` (toujours des squelettes) — dégradation
  propre confirmée (aucune entrée, aucun bouton, aucun crash).
- `qmllint` : aucun avertissement.

## 2. Composants en cours / pas commencés

Reste du périmètre du Core MVP (voir `Core-MVP.md`) :
`NebulaKeyboardSelector`, `NebulaNotification`, `NebulaAnimationManager`,
`NebulaWallpaperEngine`, `NebulaBlurEffect`/`NebulaGlowEffect`/
`NebulaParticles` (Phase 3) — non commencés. Leur contrat `Core-API.md`
a cependant déjà été mis à jour pour dépendre des Services (Phase 1.4)
plutôt que de SDDM directement.

**Critère de fin de la Phase 1.2 atteint** : un écran de login statique
(avatar + heure + date + bouton) est démontré dans
`tests/LoginScreenHarness.qml`, assemblé uniquement via
`NebulaThemeProvider`, sans dépendre d'un thème ni de l'API SDDM — voir
§4.

**Critère de fin de la Phase 1.3 atteint** : `tests/LoginScreenHarness.qml`
n'assemble plus les composants directement — il instancie
`NebulaLoginLayout` et y place son contenu (Avatar, Clock, Date, Button)
via la zone par défaut. Résultat visuel identique à la Phase 1.2, vérifié
par capture d'écran.

**Critère de fin de la Phase 1.5 atteint** :
`tests/LoginScreenHarness.qml` affiche un véritable écran de connexion en
couches (`NebulaBackground` → `NebulaWallpaper` → `NebulaOverlay` →
`NebulaLoginLayout` → `NebulaSurface` → Avatar/Clock/Date/Button),
exclusivement composé de composants Core, sans thème. Vérifié par capture
d'écran. Le Core est désormais considéré comme visuellement complet pour
le périmètre du MVP (voir `Core-MVP.md`) : les phases suivantes peuvent se
concentrer sur `NebulaPasswordField`/`NebulaUserList`/
`NebulaSessionSelector` et l'intégration SDDM réelle.

**Critère de fin de la Phase 1.4 atteint** : aucun composant Core
n'appelle `sddm.*` directement (aucun n'existe encore qui le pourrait —
mais le contrat `Core-API.md` l'interdit désormais explicitement pour
`NebulaUserList`/`NebulaPasswordField`/`NebulaSessionSelector`/
`NebulaPowerButtons`). `tests/LoginScreenHarness.qml` continue de
fonctionner sans SDDM, désormais via `NebulaUserService`/
`NebulaAuthService` réels (avec adapters fictifs) plutôt que des valeurs
codées en dur.

**Critère de fin de la Phase 1.6 atteint** : plus aucune valeur codée en
dur identifiée par l'audit ne reste sans classification explicite
(devenue token, restée locale et documentée, ou promue en propriété
d'instance) ; `ThemeConfig`/`ThemeProvider` sont vérifiés synchronisés
automatiquement par `tests/ThemeSyncCheck.qml` ; `VisualHarness.qml`/
`LoginScreenHarness.qml` confirment l'absence de régression visuelle
(capture d'écran, taille par défaut et `QT_SCALE_FACTOR=2`). Le Core est
considéré stable pour démarrer le premier thème (Nord).

**Critère de fin de la Phase 2.0.5 atteint** : une seule implémentation
de la logique de chargement de token existe dans tout le projet
(`NebulaThemeLoader`) ; seul ce composant connaît le format `theme.conf` ;
les composants Core restent totalement indépendants des thèmes (aucun
changement à `NebulaButton`, `NebulaSurface`, etc.) ; `themes/template/`
et `tests/ThemeHarness.qml` utilisent tous deux le Loader ; DT-0017 est
résolu sans modification de l'API publique du Core. Le projet est prêt
pour Nord (Phase 2.1).

**Critère de fin de la Phase 2.3 atteint** : un écran de connexion
complet peut être assemblé uniquement avec des composants Core
(`tests/LoginWorkflowHarness.qml`) ; tous les nouveaux composants
communiquent exclusivement avec les Services ; aucun ne dépend
directement de SDDM ; le harnais valide le flux complet d'interaction
(sélection utilisateur, mot de passe, session, actions d'alimentation).
Le Core dispose désormais de tous les éléments Phase 1 nécessaires à un
écran de connexion complet, à l'exception de `NebulaKeyboardSelector` et
`NebulaNotification`.

## 3. Décisions prises pendant cette phase

### D1 — Palette par défaut générique, distincte de Nord

**Contexte** : `NebulaThemeConfig` a besoin de valeurs par défaut
concrètes pour être testable, mais le Core ne doit jamais porter
l'identité d'un thème (`Core-API.md` §1).

**Décision** : palette de repli neutre (bleu générique `#4a90d9`, gris
foncé `#1e1e1e`/`#2a2a2a`, etc.), délibérément différente de la palette
Nord documentée dans `Nord-Theme-Specification.md`.

**Trouvé pendant le test** : la première version donnait `accentColor`
la même valeur que `primaryColor` — un bouton avec le focus visible sur
fond `primary` avait un contour invisible (même couleur que le fond).
Corrigé en donnant à `accentColor` une teinte nettement différente
(`#f0a030`, ambre) — vérifié visuellement (voir §4). Leçon retenue :
`accentColor` doit toujours être visuellement distinct de `primaryColor`
et `secondaryColor`, sous peine de rendre les indicateurs de focus
inutiles pour l'accessibilité.

### D2 — Injection explicite de `NebulaThemeProvider`, pas de singleton

**Contexte** : aucune décision n'a encore été prise sur le système de
modules QML (`qmldir` + `pragma Singleton`, ou build system type
`qt_add_qml_module`/CMake) — voir §3, décision D3 ci-dessous.

**Décision** : pour cette phase, `NebulaButton` reçoit son
`NebulaThemeProvider` via une `required property`, assignée explicitement
par qui l'instancie (voir `tests/ButtonHarness.qml`). Pas de singleton
global implicite.

**Raisons** : reste simple et testable sans dépendre d'une décision de
build/packaging pas encore prise ; rend la dépendance explicite (cohérent
avec `Core-API.md` §1 : "chaque composant Core doit être indépendant").

**Conséquences** : à réévaluer une fois le système de modules choisi —
un vrai singleton (`pragma Singleton`) simplifierait l'usage dans les
thèmes réels en évitant de repasser `theme:` à chaque composant. Pas
bloquant pour la suite du Core MVP.

### D3 — Pas de `qmldir`/CMake pour l'instant

**Contexte** : les fichiers QML du Core sont pour l'instant consommés
via des imports relatifs de répertoire (`import "../theme"`,
`import "../config"`), exactement comme les thèmes SDDM réels observés en
Phase 1.0 (`Prototype-Results.md`) — pas de module QML nommé, pas de
`qmldir`, pas de build system.

**Décision** : rester sur ce mécanisme simple tant qu'aucun besoin réel
de packaging (module nommé, installation système) ne se manifeste —
cohérent avec le principe de travail du workspace (pas d'outillage avant
besoin observé).

**Conséquences** : si un thème réel a besoin d'importer le Core par un
nom de module stable plutôt que par chemin relatif, ou si Nebula doit
être installé comme paquet système, cette décision devra être rouverte.

### D4 — `fontWeight` résolu en `fontWeightNormal`/`fontWeightBold`

**Contexte** : `Design-System.md` §4 laissait le nommage de `fontWeight`
ouvert ("à confirmer lors du prototype").

**Décision** : deux tokens distincts, `fontWeightNormal` et
`fontWeightBold`, valués directement avec l'énumération Qt
(`Font.Normal`, `Font.Bold`) plutôt qu'une échelle personnalisée.
`Design-System.md` à mettre à jour en conséquence (voir §5).

### D5 — Tokens d'effets non implémentés

**Contexte** : `Design-System.md` §6 documente des tokens d'effets
(`blurAmount`, `glowIntensity`, `enableEffects`, `particleDensity`) mais
aucun composant ne les consomme encore.

**Décision** : ne pas les ajouter à `NebulaThemeConfig` tant que
`NebulaBlurEffect`/`NebulaGlowEffect`/`NebulaParticles` ne sont pas
implémentés (Phase 3, voir `Roadmap.md`) — cohérent avec le principe
"pas d'abstraction avant besoin réel".

### D6 — `qmllint --warnings-as-errors` retiré (CI et doc)

**Contexte** : en testant réellement `qmllint` sur cette machine (Qt
6.11.1), le flag `--warnings-as-errors`, documenté dans
`Development-Environment.md` et utilisé dans
`.github/workflows/qml-lint.yml` depuis la Phase 0.5, **n'existe pas**
sur ce binaire (`qmllint --help` ne le liste pas, `qmllint` renvoie une
erreur "Unknown option"). Vérifié que `qmllint` sans option échoue déjà
(code de sortie non nul) sur une vraie erreur de syntaxe — le flag
n'apportait donc rien de toute façon.

**Décision** : flag retiré de `.github/workflows/qml-lint.yml` et de
`Development-Environment.md`.

### D7 — `NebulaClock.format` ajouté en plus de `use24HourFormat`/`showSeconds`

**Contexte** : le brief de la Phase 1.2 demandait une propriété `format`
libre pour `NebulaClock`, alors que `Core-API.md` documentait déjà
`use24HourFormat`/`showSeconds` depuis la Phase 0.6.

**Décision** : garder les deux. `format` (string, vide par défaut) permet
de remplacer entièrement le format calculé à partir de
`use24HourFormat`/`showSeconds` quand un thème a besoin de quelque chose
de plus spécifique, sans casser l'API simple déjà documentée et déjà
utilisée comme référence ailleurs.

**Raisons** : évite de choisir entre "l'ancien contrat était incomplet"
et "le brief se trompe" — les deux approches sont légitimes et n'entrent
pas en conflit une fois combinées.

### D8 — `fallbackIcon` conservé (pas `fallback`), `radius` ajouté à `NebulaAvatar`

**Contexte** : le brief de la Phase 1.2 nommait la propriété de repli
`fallback`, alors que `Core-API.md` documentait déjà `fallbackIcon`
depuis la Phase 0.6. Le brief demandait aussi une propriété `radius`,
absente du contrat déjà documenté (qui ne mentionnait qu'un usage interne
du token `radius` du thème, pas une propriété dédiée).

**Décision** : garder le nom déjà établi `fallbackIcon` (éviter une
rupture d'API sans raison réelle — DT-0009) ; ajouter `radius` comme
nouvelle propriété (réel besoin : un thème doit pouvoir choisir un avatar
carré aux coins arrondis plutôt que circulaire, testé avec succès — voir
§4). `Core-API.md` mis à jour pour documenter `radius`.

### D9 — Leçon : les imports QML par chemin absolu doivent utiliser `file:`

**Trouvé pendant le test** : un harnais de vérification ad hoc utilisant
`import "/home/luust/.../core/theme"` (chemin absolu sans schéma) a fait
échouer `qml6` avec "Did not load any objects, exiting" — message générique
qui n'explique rien par lui-même. La vraie cause n'apparaissait que dans
`journalctl` (comme pour `sddm-greeter`, voir `Prototype-Results.md`
§3.5) : `"... is not a valid import URL ... Try "file:/...".`.

**Conséquence pour la suite** : tous les imports internes du Core
utilisent des chemins **relatifs** (`import "../theme"`) — jamais de
chemin absolu — ce qui reste valide indépendamment de l'endroit où le
dépôt est cloné. Documenté ici pour éviter de perdre du temps à
redécouvrir la même erreur plus tard.

### D10 — Contenu des zones via `property alias ... : zone.data`, pas de `Loader`/`Component`

**Contexte** : `NebulaLoginLayout` doit accepter que son utilisateur
(harnais aujourd'hui, thème réel plus tard) place ses propres composants
dans quatre zones, sans que `NebulaLoginLayout` connaisse ces composants
à l'avance.

**Décision** : chaque zone expose une propriété `property alias
xxxContent: zoneItem.data`, et `mainContent` est en plus la propriété
`default` (les enfants anonymes y atterrissent automatiquement). Pas de
`Loader`/`Component` — inutile ici, tout le contenu est statique au
moment de l'écriture du QML, pas chargé dynamiquement à l'exécution.

**Raisons** : reste le pattern QML le plus simple pour ce besoin ;
cohérent avec l'absence de système de modules/singleton décidée en
Phase 1.1 (D2/D3).

**Conséquences** : documenté comme contrat dans `Core-API.md`. Si
`NebulaThemeLoader` a un jour besoin de charger le contenu d'une zone
dynamiquement (thème sélectionné à l'exécution), ce choix devra être
réévalué — `Loader`/`Component` deviendraient alors pertinents.

### D11 — Limitation assumée : pas de gestion du débordement vertical

Voir `Development-Journal.md` (Phase 1.3, entrée sur le ratio 900×300).
Décision : ne pas ajouter de logique de rétrécissement adaptatif
maintenant — aucun écran réel visé par Nebula n'a un ratio aussi extrême
(voir `SDDM-Compatibility.md`). À revisiter seulement si un besoin réel
apparaît (voir principe de travail du workspace).

### D12 — Services préfixés `Nebula`, Adapters non préfixés (Phase 1.4)

Réconciliation avec le brief : les noms de fichiers proposés
(`AuthService.qml`, `SDDMAuthAdapter.qml`) ne suivaient pas DT-0004 pour
les premiers. Décision complète et raisons : voir DT-0010 dans
`Decisions-Techniques.md`. En bref : `core/services/Nebula*Service.qml`
(DT-0004 s'applique, c'est du Core) ; `platform/sddm/SDDM*Adapter.qml`
sans préfixe (hors `core/`, spécifique à SDDM par nature).

### D13 — `Connections{}` invalide comme enfant direct d'un `QtObject`

**Trouvé pendant le test** : `NebulaAuthService.qml` déclarait
`Connections { target: root.adapter; ... }` comme enfant direct de son
`QtObject` racine. `qmllint` ne l'a pas signalé, mais `qml6` a refusé de
charger le fichier : `Cannot assign to non-existent default property` —
`QtObject` n'a pas de default property pour recevoir un enfant anonyme
(contrairement à `Item`, qui déclare `default property list data`).

**Solution** : connexion en JavaScript impératif
(`adapter.loginResult.connect(...)` dans `onAdapterChanged`) plutôt qu'un
bloc `Connections{}` déclaratif. Même piège retrouvé dans
`tests/mocks/MockAuthAdapter.qml` (qui a, lui, un vrai besoin d'un
`Timer` enfant) — corrigé en changeant son type racine de `QtObject` à
`Item`, puisqu'un `Timer` enfant est indispensable là et qu'`Item`
fournit le default property nécessaire.

Décision complète et règle générale pour la suite : voir DT-0011 dans
`Decisions-Techniques.md`. Détail du diagnostic : voir
`Development-Journal.md`, Phase 1.4.

### D14 — `NebulaBackground`/`NebulaWallpaper` séparés (Phase 1.5)

Réconciliation avec le brief : `NebulaBackground` était déjà documenté
(Phase 0.6) avec un contrat image (`source`/`fillMode`/`dimmed`), jamais
implémenté. Séparé en conteneur racine pur (`NebulaBackground`) + image
simple (`NebulaWallpaper`) pour respecter "chaque composant doit avoir
une responsabilité unique". Décision complète : voir DT-0012.

### D15 — Contrainte trouvée : `anchors.fill` incompatible avec les positionneurs

**Trouvé pendant le test** : placer `NebulaBackground` (qui utilise
`anchors.fill: parent` en interne) comme enfant direct d'un `Row` de test
a produit `QML Row: Cannot specify ... fill ... anchors for items inside
Row. Row will not function.` Corrigé en révisant le harnais de test (une
configuration par fenêtre entière, pas côte à côte) — ce n'était pas un
bug du composant, mais un usage invalide à documenter. Voir
`Rendering-Guidelines.md` §5 et `Development-Journal.md`, Phase 1.5.

### D16 — Bug réel : tokens `overlay`/`surface` non répercutés dans `NebulaThemeProvider`

**Trouvé pendant le test** : `NebulaOverlay` s'affichait totalement
opaque (wallpaper invisible) au premier essai. Cause :
`theme.overlay.overlayOpacity` levait `TypeError: ... of undefined` —
`NebulaThemeConfig` avait bien reçu les nouveaux groupes `overlay`/
`surface`, mais `NebulaThemeProvider` ne les ré-exposait pas encore
(chaque groupe y est répercuté individuellement, pas délégué
génériquement). Corrigé en ajoutant les deux lignes manquantes. Détail :
`Development-Journal.md`, Phase 1.5. **Rappel pour la suite** : tout
nouveau groupe de tokens ajouté à `NebulaThemeConfig` doit être
explicitement répercuté dans `NebulaThemeProvider` — ce n'est pas
automatique.

### D17 — Pas de tokens `surfaceRadius`/`surfacePadding` dédiés

Voir DT-0013 dans `Decisions-Techniques.md` : `NebulaSurface` réutilise
`radius.radiusLarge`/`spacing.spacingMd` par défaut plutôt que d'ajouter
des tokens dédiés non justifiés par un besoin réel observé.

### D18 — Bonus phase 1.5 réalisés : `VisualHarness.qml` et référence de performance

Les deux demandes optionnelles du brief ont été faites : voir
`tests/VisualHarness.qml` (tous les composants sur une page, utile pour
les régressions visuelles futures) et `Rendering-Guidelines.md` §6
(référence de performance — ~52 objets QML au démarrage, 2 `Timer` actifs
en continu, aucun binding par-frame identifié en dehors d'eux).

### D19 — Nouveau groupe de tokens `interaction` (Phase 1.6)

`NebulaButton` codait en dur son retour visuel d'interaction
(assombrissement à la pression, largeurs de bordure focus/ghost, opacité
désactivée, échelle de pression). Justifié comme tokens (et non laissé
local) car les prochains composants interactifs du Roadmap
(`NebulaPasswordField`, `NebulaUserList`, `NebulaSessionSelector`) auront
besoin des mêmes états et doivent rester visuellement cohérents entre
eux. Détail : [`Design-Tokens-Reference.md`](Design-Tokens-Reference.md).

### D20 — `NebulaAvatar`/`NebulaLoginLayout` : valeurs restées locales, documentées

L'audit Phase 1.6 a aussi trouvé des valeurs codées en dur qui ne sont
**pas** devenues des tokens : la taille par défaut et les ratios de la
silhouette de repli de `NebulaAvatar` (géométrie décorative, pas
d'identité de thème), et la largeur responsive des zones de
`NebulaLoginLayout` (contrat de layout du Core, pas une valeur qu'un
thème doit pouvoir changer — dédupliquée en une propriété interne). Voir
`Design-Tokens-Reference.md`, section « Valeurs volontairement non
tokenisées ».

### D21 — `tests/ThemeSyncCheck.qml` : détection automatique de la régression D16

La Phase 1.5 avait trouvé un bug réel (D16) uniquement à l'exécution :
des tokens définis dans `NebulaThemeConfig` mais jamais répercutés dans
`NebulaThemeProvider`. Plutôt que de compter sur une relecture manuelle
à chaque nouvelle phase, `tests/ThemeSyncCheck.qml` compare
automatiquement les groupes de tokens des deux objets (`Object.keys()`
fonctionne sur un `QtObject` QML, voir `Development-Journal.md`) et
échoue si l'un manque. Intégré à `scripts/check-design-system.sh`.

### D22 — `NebulaThemeLoader` lit `theme.conf` directement, jamais `config` (SDDM)

Voir `ThemeLoader.md` §3 : lire la propriété de contexte `config`
directement depuis `core/` romprait `Nebula-Principles.md` §2. Le Loader
fait sa propre lecture de fichier, fonctionnant à l'identique sous
`qml6`, `sddm-greeter --test-mode`, et SDDM réel.

### D23 — Bug réel : référence vivante en capturant une propriété `color` dans une variable JS

`var previous = group[tokenName]` avant une réassignation ne crée pas de
copie pour un type objet (`color`) — `previous` reflète aussi la nouvelle
valeur après coup. Corrigé avec `var previous = "" + group[tokenName]`
(force une vraie copie via conversion en chaîne). Voir
`Development-Journal.md`, Phase 2.0.5.

### D24 — Bug réel : ré-entrance de binding en affichant une propriété et son propre effet dérivé

Un `Text` affichant à la fois `loader.configPath` et une valeur dérivée
de `reload()` (déclenché par le changement de `configPath` lui-même)
provoquait un vrai `Binding loop detected`, pas un faux positif. Corrigé
en affichant `themeName` (stable) plutôt que `configPath`. Voir
`Development-Journal.md`, Phase 2.0.5.

## 4. Vérifications réelles effectuées

- `qmllint` sur les 3 nouveaux fichiers + le harnais de test : aucun
  avertissement.
- Rendu visuel confirmé par capture d'écran (`qml6 tests/ButtonHarness.qml`
  + `spectacle`) : couleurs par variante, tailles, radius, état désactivé.
- Focus clavier réel confirmé : le bouton avec `focus: true` obtient
  effectivement `activeFocus` de la fenêtre et affiche le contour ambre
  attendu (pas seulement en théorie — vérifié à l'écran).
- État pressé et focus vérifiés visuellement via des instances de
  démonstration temporaires (valeurs forcées), retirées du harnais après
  confirmation — la mécanique de `Behavior`/`MouseArea.pressed` elle-même
  n'est pas testable sans automatisation d'entrée (aucun outil
  `ydotool`/`wtype`/`dotool` disponible sur cette machine).

### Phase 1.2

- `qmllint` sur `NebulaAvatar.qml`, `NebulaClock.qml`, `NebulaDate.qml` et
  `tests/LoginScreenHarness.qml` : aucun avertissement.
- `tests/LoginScreenHarness.qml` (Avatar + Clock + Date + Button assemblés
  via `NebulaThemeProvider` seul) rendu réellement avec `qml6` et capturé
  à l'écran : horloge à jour (`20:21:44`), date correcte au format système
  (`Thursday 30 July 2026`), avatar en silhouette de repli, bouton
  cohérent avec la Phase 1.1.
- **Validation scaling différent** : même harnais relancé avec
  `QT_SCALE_FACTOR=2` — mise à l'échelle propre, aucun texte tronqué,
  aucun artefact, la silhouette de repli (vectorielle) reste nette (pas
  de pixellisation, contrairement à ce qu'on aurait avec une image
  bitmap).
- `NebulaAvatar` testé séparément avec une vraie image
  (`/usr/share/pixmaps/htop.png`, `fillMode: PreserveAspectCrop`) à côté
  d'une instance en repli avec `radius: theme.radius.radiusMedium` — les
  deux rendus confirmés par capture d'écran (image personnalisée
  correctement découpée en cercle ; repli correctement découpé en carré
  aux coins arrondis avec un `radius` différent).

### Phase 1.3

- `qmllint` sur `NebulaLoginLayout.qml` et `tests/LoginScreenHarness.qml`
  mis à jour : aucun avertissement.
- Bug de boucle de binding trouvé, corrigé, revérifié (voir D-Journal) ;
  rendu final identique visuellement à la Phase 1.2 (capture d'écran
  comparée).
- Testé à plusieurs tailles/ratios réels : 480×520 (référence), 960×540
  (16:9 large), 340×700 (portrait étroit), 900×300 (ratio extrême — a
  révélé la limitation D11), et `QT_SCALE_FACTOR=2` sur la taille de
  référence — tous rendus capturés à l'écran, aucun avertissement QML
  restant après correction du bug de boucle.

### Phase 1.4

- `qmllint` sur les 4 Services, les 4 Adapters SDDM, les 4 Mock Adapters,
  `tests/ServicesHarness.qml` et `tests/LoginScreenHarness.qml` mis à
  jour : aucun avertissement — y compris sur les deux fichiers qui
  contenaient pourtant le bug `Connections{}`/`QtObject` (D13), un bug
  invisible à `qmllint`, trouvé uniquement à l'exécution réelle.
- `tests/ServicesHarness.qml` exécuté réellement (`qml6`) : les 4
  services s'instancient, `NebulaSessionService.selectSession(1)` change
  bien `currentIndex` (0→1), `NebulaPowerService` reflète les capacités
  du mock, et `NebulaAuthService.authenticate()` déclenche bien
  `authenticating: true` puis, ~300 ms plus tard (round-trip simulé),
  le signal `succeeded()` — confirmé par les logs (`journalctl`,
  `qml6` loggue aussi via le journal systemd quand détaché d'un terminal,
  cohérent avec la découverte de Phase 1.0).
- `tests/LoginScreenHarness.qml` retesté visuellement : le nom affiché
  vient maintenant de `NebulaUserService`/`MockUserAdapter`
  ("Nebula User" au lieu de la chaîne "nebula" codée en dur) — capture
  d'écran comparée, aucune régression visuelle par ailleurs.

### Phase 1.5

- `qmllint` sur `NebulaBackground.qml`, `NebulaWallpaper.qml`,
  `NebulaOverlay.qml`, `NebulaSurface.qml`, `NebulaThemeConfig.qml`
  (nouveaux groupes), `NebulaThemeProvider.qml` (correctif D16),
  `tests/LoginScreenHarness.qml` et `tests/VisualHarness.qml` : aucun
  avertissement — y compris sur les fichiers qui contenaient pourtant des
  bugs réels à l'exécution (D15, D16), invisibles à `qmllint`.
- `NebulaWallpaper` testé réellement avec 3 cas : image valide en mode
  `crop`, chemin invalide (repli couleur confirmé, pas d'icône cassée),
  mode `fit` — capture d'écran pour chacun.
- `NebulaOverlay` testé réellement : voile plat (bug D16 trouvé et
  corrigé ici), puis dégradé — capture d'écran pour chacun.
- `NebulaSurface` testé réellement avec et sans ombre — capture d'écran.
- Composition en couches complète (`Background → Wallpaper → Overlay →
  LoginLayout → Surface → Avatar/Clock/Date/Button`) testée dans
  `tests/LoginScreenHarness.qml` — capture d'écran, aucune erreur
  `journalctl`.
- `tests/VisualHarness.qml` (bonus) exécuté réellement : les 8 composants
  (Button ×4 variantes, Avatar ×2 formes, Clock, Date, Surface, fond en
  couches) s'affichent correctement sur une seule page.
- Référence de performance (bonus) établie par lecture du code réel —
  voir `Rendering-Guidelines.md` §6 pour le détail et les limites de la
  méthodologie (pas de trace `qmlprofiler`, comptage manuel).

### Phase 1.6

- `qmllint` sur `NebulaThemeConfig.qml`, `NebulaThemeProvider.qml`,
  `NebulaButton.qml`, `NebulaSurface.qml`, `NebulaLoginLayout.qml` et
  `tests/ThemeSyncCheck.qml` : aucun avertissement.
- `tests/ThemeSyncCheck.qml` exécuté réellement dans les deux sens :
  retrait temporaire de `interaction` dans `NebulaThemeProvider` →
  échec détecté et message explicite (`FAIL - token group(s) ... :
  interaction`, code de sortie `1`) ; remise en place → succès (`PASS -
  8 token group(s) ...`, code de sortie `0`).
- `tests/VisualHarness.qml` et `tests/LoginScreenHarness.qml` relancés
  après le refactor des tokens — rendu identique à la Phase 1.5 (mêmes
  valeurs numériques, seulement déplacées vers des tokens), confirmé par
  capture d'écran à la taille par défaut et à `QT_SCALE_FACTOR=2`.
- `scripts/check-design-system.sh` exécuté de bout en bout réellement :
  `qmllint` et `ThemeSyncCheck` bloquants confirmés, les deux harnais
  visuels s'ouvrent en séquence sans jamais faire échouer le script sur
  leur code de sortie (voir D21 et `Development-Journal.md` pour la
  limite trouvée en testant la fermeture des fenêtres Wayland).

### Phase 2.0.5

- `qmllint` sur `NebulaThemeLoader.qml`, `themes/template/Main.qml`,
  `tests/ThemeHarness.qml`, `tests/ThemeLoaderHarness.qml` : aucun
  avertissement.
- `tests/ThemeLoaderHarness.qml` exécuté réellement : les 5 scénarios
  requis (thème valide, token inconnu, token absent, fichier vide, valeur
  invalide) passent tous, aucun crash — 2 bugs réels trouvés et corrigés
  pendant cette validation (D23, D24).
- `themes/template/Main.qml` (rebranché sur le Loader) revalidé sous
  `sddm-greeter-qt6 --test-mode` réel sur les 3 écrans de la machine —
  aucune erreur, aucun avertissement QML. Confirmé une deuxième fois avec
  `primaryColor` changé temporairement en magenta dans `theme.conf`
  (round-trip complet re-vérifié après le passage au Loader).
- `tests/ThemeHarness.qml` (rebranché sur le Loader) exécuté en
  standalone (`qml6`) : charge, applique et visualise les tokens
  correctement pour un thème valide, et pour un thème inexistant affiche
  une erreur claire sans crash.
- `scripts/check-theme.sh template` et `scripts/check-design-system.sh`
  ré-exécutés : toujours au vert, aucune régression.

### Phase 2.3

- `qmllint` sur les 4 nouveaux composants, `NebulaPowerService.qml`,
  `SDDMPowerAdapter.qml`, `MockPowerAdapter.qml`, `MockUserAdapter.qml`,
  `themes/template/Main.qml`, `tests/LoginWorkflowHarness.qml` : aucun
  avertissement.
- Chaque composant testé réellement en isolation avant assemblage
  (fichiers `qml6` jetables, un par composant) : `NebulaPasswordField`
  (focus automatique, `submit()` no-op si vide, `hasError`/`isBusy`
  initiaux) ; `NebulaUserList` (3 utilisateurs mock, `selectIndex()`,
  hors-limites sans effet, surbrillance visuelle confirmée par capture
  d'écran) ; `NebulaSessionSelector` (changement de session, pastille
  active confirmée par capture d'écran) ; `NebulaPowerButtons`
  (mécanisme de confirmation en deux clics vérifié directement via
  `_trigger()` : armé puis exécuté).
- `tests/LoginWorkflowHarness.qml` exécuté réellement : écran de
  connexion complet (horloge, date, 3 utilisateurs, mot de passe,
  session, 4 boutons d'alimentation) rendu correctement, confirmé par
  capture d'écran.
- `themes/template/Main.qml` mis à jour et retesté : standalone (`qml6`,
  dégradation propre à vide) et `sddm-greeter-qt6 --test-mode` réel sur
  les 3 écrans de la machine (adapters SDDM réels, toujours des
  squelettes — aucune erreur, aucun avertissement).
- `QT_SCALE_FACTOR=2` sur `tests/LoginWorkflowHarness.qml` : rendu net,
  aucun artefact, confirmé par capture d'écran.
- Installation système réelle non retentée cette phase (Phase 2.2 non
  résolue, voir `Nord-Validation-Report.md`) — limitation déjà connue et
  documentée, pas une nouvelle découverte.

## 5. Documentation à synchroniser (fait dans ce lot)

- [`Design-System.md`](Design-System.md) — `fontWeight` → 
  `fontWeightNormal`/`fontWeightBold` (D4).
- [`Development-Environment.md`](Development-Environment.md) et
  [`.github/workflows/qml-lint.yml`](../.github/workflows/qml-lint.yml) —
  retrait de `--warnings-as-errors` (D6).
- [`Core-API.md`](Core-API.md) — `NebulaClock.format` ajouté (D7),
  `NebulaAvatar.radius` ajouté et `fallbackIcon` confirmé (D8).
- [`Roadmap.md`](Roadmap.md) — Phase 1.2 marquée terminée.
- [`Core-API.md`](Core-API.md) — entrée `NebulaLoginLayout` ajoutée.
- [`Architecture.md`](Architecture.md) — `core/layouts/` (et
  `config/`/`theme/`/`services/`, oubliés lors de la Phase 1.1) ajoutés
  à l'arborescence cible ; `LoginLayout` ajouté à la liste des composants.
- [`Core-MVP.md`](Core-MVP.md) — `NebulaLoginLayout` ajouté au périmètre.
- [`Roadmap.md`](Roadmap.md) — Phase 1.3 marquée terminée.
- [`Development-Journal.md`](Development-Journal.md) — nouveau document
  (Phase 1.3), rétro-rempli avec les découvertes des Phases 1.0 à 1.3.
- [`Core-API.md`](Core-API.md) — entrées `NebulaAuthService`,
  `NebulaUserService`, `NebulaSessionService`, `NebulaPowerService`
  ajoutées ; `Inputs`/`Dependencies` de `NebulaUserList`,
  `NebulaPasswordField`, `NebulaSessionSelector`, `NebulaPowerButtons`
  révisés pour dépendre des Services plutôt que de SDDM directement.
- [`Architecture.md`](Architecture.md) — `platform/` ajouté à
  l'arborescence cible ; Services ajoutés à la liste des composants.
- [`Decisions-Techniques.md`](Decisions-Techniques.md) — DT-0010
  (nommage Services/Adapters), DT-0011 (`QtObject` vs `Item` pour
  `Connections`/`Timer`).
- [`Core-MVP.md`](Core-MVP.md) — Services ajoutés à l'infrastructure,
  composants d'intégration SDDM annotés avec leur Service.
- [`Roadmap.md`](Roadmap.md) — Phase 1.4 marquée terminée.
- [`Services-Architecture.md`](Services-Architecture.md),
  [`Nebula-Principles.md`](Nebula-Principles.md) — nouveaux documents
  (Phase 1.4).
- [`Core-API.md`](Core-API.md) — `NebulaBackground` révisé,
  `NebulaWallpaper`/`NebulaOverlay`/`NebulaSurface` ajoutés.
- [`Design-System.md`](Design-System.md) — `opacityOverlay` retiré (Phase
  0.6, jamais implémenté) ; `overlayOpacity`/`surfaceOpacity`/
  `surfaceBorderWidth` ajoutés (section 6bis).
- [`Decisions-Techniques.md`](Decisions-Techniques.md) — DT-0012
  (séparation Background/Wallpaper), DT-0013 (pas de tokens
  surface dédiés).
- [`Architecture.md`](Architecture.md) — pas de changement structurel
  (composants déjà dans `core/components/`).
- [`Rendering-Guidelines.md`](Rendering-Guidelines.md) — nouveau document
  (Phase 1.5).
- [`Roadmap.md`](Roadmap.md) — Phase 1.5 marquée terminée.
- [`Design-Tokens-Reference.md`](Design-Tokens-Reference.md) — nouveau
  document (Phase 1.6) : référence exhaustive de chaque token, valeur par
  défaut et composants qui l'utilisent.
- [`Design-System.md`](Design-System.md) — section 6ter (groupe
  `interaction`) ajoutée.
- [`Theme-System.md`](Theme-System.md) — contrat de synchronisation
  `NebulaThemeConfig`/`NebulaThemeProvider` explicité, référence à
  `tests/ThemeSyncCheck.qml`.
- [`Core-API.md`](Core-API.md) — dépendance `interaction` ajoutée à
  `NebulaButton` ; `shadowOpacity` ajoutée aux Properties de
  `NebulaSurface`.
- [`Development-Journal.md`](Development-Journal.md) — trois nouvelles
  entrées (Phase 1.6) : énumération d'un `QtObject` via `Object.keys()`,
  `QT_LOGGING_TO_CONSOLE` comme alternative directe à `journalctl`,
  limite de `xdotool`/`wmctrl` sur des fenêtres Wayland natives.
- [`Roadmap.md`](Roadmap.md) — Phase 1.6 marquée terminée.
- [`Theme-SDK.md`](Theme-SDK.md) — anciennement `Theme-Development.md`,
  renommé et étendu (Phase 2.0) : structure du Template, conventions de
  nommage, dossiers réservés, tokens attendus, rôles distincts des trois
  outils de validation. Toutes les références croisées vers l'ancien nom
  mises à jour (`README.md`, `CONTRIBUTING.md`, `Nord-Theme-Specification.md`,
  `Development-Environment.md`, `Decisions-Techniques.md`,
  `Prototype-Results.md`, `tests/LoginScreenHarness.qml`).
- [`Creating-A-Theme.md`](Creating-A-Theme.md) — nouveau document (Phase
  2.0) : tutoriel pas-à-pas, renvoie vers `Theme-SDK.md` pour les règles.
- [`Decisions-Techniques.md`](Decisions-Techniques.md) — DT-0014 (fusion
  documentaire), DT-0015 (pas de `overrides/`), DT-0016
  (`metadata.desktop` réel), DT-0017 (pont `theme.conf` temporaire).
- [`themes/README.md`](../themes/README.md) — `template/` mentionné comme
  base neutre, distincte des thèmes visuels listés.
- [`Roadmap.md`](Roadmap.md) — Phase 2.0 marquée terminée, item 3
  (`ThemeLoader`) annoté avec le point de départ validé (DT-0017).
- [`ThemeLoader.md`](ThemeLoader.md) — nouveau document (Phase 2.0.5) :
  responsabilités, cycle de chargement, stratégie de validation, piège
  des signaux au premier chargement.
- [`Compatibility-Matrix.md`](Compatibility-Matrix.md) — nouveau document
  (Phase 2.0.5) : différences factuelles `qml6`/`sddm-greeter
  --test-mode`/SDDM réel.
- [`Core-API.md`](Core-API.md) — entrée `NebulaThemeLoader` révisée pour
  refléter le design réellement implémenté (lecture directe de fichier,
  pas de nom de thème résolu via SDDM).
- [`Development-Environment.md`](Development-Environment.md) — mention de
  `QT_LOGGING_TO_CONSOLE=1` comme alternative à `journalctl` pour
  `sddm-greeter`, avec renvoi vers `Compatibility-Matrix.md`.
- [`Decisions-Techniques.md`](Decisions-Techniques.md) — résolution de
  DT-0017 documentée, DT-0018 (fichier vide/manquant/lectures désactivées
  traité comme un échec).
- [`Roadmap.md`](Roadmap.md) — item 3 (`ThemeLoader`) coché, Phase 2.0.5
  marquée terminée.
- [`Nord-Validation-Report.md`](Nord-Validation-Report.md) — nouveau
  document (Phase 2.1) : réponse à la question de validation du SDK,
  3 constats détaillés (distribution/packaging critique, composants
  manquants connus, limitation mineure de `ThemeInspector`).
- [`Theme-SDK.md`](Theme-SDK.md), [`Creating-A-Theme.md`](Creating-A-Theme.md),
  [`Compatibility-Matrix.md`](Compatibility-Matrix.md) — limitation de
  distribution documentée dans les trois (révélée par Nord, voir brief
  Phase 2.1 §8 : mise à jour uniquement si un besoin réel apparaît).
- [`Roadmap.md`](Roadmap.md) — Phase 2.1 marquée terminée ; nouvelle
  sous-étape Phase 2.2 (Distribution/Packaging, à faire) ajoutée pour
  tracer le Constat #1.
- [`Login-Architecture.md`](Login-Architecture.md) — nouveau document
  (Phase 2.3) : responsabilités des 4 nouveaux composants, modèle d'état
  d'authentification (DT-0020), flux complet, limite des adapters
  squelettes.
- [`Core-API.md`](Core-API.md) — entrées `NebulaUserList`,
  `NebulaPasswordField`, `NebulaSessionSelector`, `NebulaPowerButtons`
  révisées pour refléter l'implémentation réelle (propriétés/méthodes
  exactes, `canHibernate`/`hibernateRequested()`).
- [`Decisions-Techniques.md`](Decisions-Techniques.md) — DT-0019
  (`canHibernate`/`hibernate()`), DT-0020 (pas de type d'état
  d'authentification dédié), DT-0021 (Phase 2.3 démarrée malgré la
  Phase 2.2 non résolue).
- [`Roadmap.md`](Roadmap.md) — items 9/11/12 de l'ordre de construction
  Phase 1 cochés ; Phase 2.3 marquée terminée.
- [`Deployment-Decision.md`](Deployment-Decision.md) — nouveau document
  (Phase 2.2) : comparaison objective des trois architectures de
  distribution prototypées et testées réellement, choix motivé.
- [`Installation.md`](Installation.md), [`Packaging.md`](Packaging.md) —
  nouveaux documents (Phase 2.2) : installation/désinstallation/mise à
  jour côté utilisateur, architecture de distribution côté packager.
- [`Compatibility-Matrix.md`](Compatibility-Matrix.md) — §7 mis à jour
  (limitation résolue), nouveau §8 (`QML2_IMPORT_PATH` vs chemin QML par
  défaut).
- [`Theme-SDK.md`](Theme-SDK.md), [`Creating-A-Theme.md`](Creating-A-Theme.md)
  — notes de limitation (Phase 2.1) mises à jour pour refléter la
  résolution.
- [`Decisions-Techniques.md`](Decisions-Techniques.md) — DT-0022
  (Core installé comme module QML).
- [`Roadmap.md`](Roadmap.md) — Phase 2.2 marquée terminée.
