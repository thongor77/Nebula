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

## 2. Composants en cours / pas commencés

Reste du périmètre du Core MVP (voir `Core-MVP.md`) : `NebulaThemeLoader`,
`NebulaBackground`, `NebulaUserList`, `NebulaPasswordField`,
`NebulaSessionSelector`, `NebulaKeyboardSelector`, `NebulaPowerButtons`,
`NebulaNotification`, `NebulaAnimationManager` — non commencés. Leur
contrat `Core-API.md` a cependant déjà été mis à jour pour dépendre des
Services (Phase 1.4) plutôt que de SDDM directement.

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

**Critère de fin de la Phase 1.4 atteint** : aucun composant Core
n'appelle `sddm.*` directement (aucun n'existe encore qui le pourrait —
mais le contrat `Core-API.md` l'interdit désormais explicitement pour
`NebulaUserList`/`NebulaPasswordField`/`NebulaSessionSelector`/
`NebulaPowerButtons`). `tests/LoginScreenHarness.qml` continue de
fonctionner sans SDDM, désormais via `NebulaUserService`/
`NebulaAuthService` réels (avec adapters fictifs) plutôt que des valeurs
codées en dur.

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
