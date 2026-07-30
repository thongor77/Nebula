# Core Implementation Status — Nebula

> État d'avancement du Core MVP (voir [`Core-MVP.md`](Core-MVP.md) pour le
> périmètre complet, [`Roadmap.md`](Roadmap.md) pour l'ordre de
> construction). Mis à jour à chaque composant livré.

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

## 2. Composants en cours / pas commencés

Reste du périmètre du Core MVP (voir `Core-MVP.md`) : `NebulaThemeLoader`,
`NebulaBackground`, `NebulaUserList`, `NebulaPasswordField`,
`NebulaSessionSelector`, `NebulaKeyboardSelector`, `NebulaPowerButtons`,
`NebulaNotification`, `NebulaAnimationManager` — non commencés.

**Critère de fin de la Phase 1.2 atteint** : un écran de login statique
(avatar + heure + date + bouton) est démontré dans
`tests/LoginScreenHarness.qml`, assemblé uniquement via
`NebulaThemeProvider`, sans dépendre d'un thème ni de l'API SDDM — voir
§4.

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

## 5. Documentation à synchroniser (fait dans ce lot)

- [`Design-System.md`](Design-System.md) — `fontWeight` → 
  `fontWeightNormal`/`fontWeightBold` (D4).
- [`Development-Environment.md`](Development-Environment.md) et
  [`.github/workflows/qml-lint.yml`](../.github/workflows/qml-lint.yml) —
  retrait de `--warnings-as-errors` (D6).
- [`Core-API.md`](Core-API.md) — `NebulaClock.format` ajouté (D7),
  `NebulaAvatar.radius` ajouté et `fallbackIcon` confirmé (D8).
- [`Roadmap.md`](Roadmap.md) — Phase 1.2 marquée terminée.
