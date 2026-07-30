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

## 2. Composants en cours / pas commencés

Tout le reste du périmètre du Core MVP (voir `Core-MVP.md`) :
`NebulaThemeLoader`, `NebulaAvatar`, `NebulaBackground`, `NebulaClock`,
`NebulaDate`, `NebulaUserList`, `NebulaPasswordField`,
`NebulaSessionSelector`, `NebulaKeyboardSelector`, `NebulaPowerButtons`,
`NebulaNotification`, `NebulaAnimationManager` — non commencés.

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

## 5. Documentation à synchroniser (fait dans ce lot)

- [`Design-System.md`](Design-System.md) — `fontWeight` → 
  `fontWeightNormal`/`fontWeightBold` (D4).
- [`Development-Environment.md`](Development-Environment.md) et
  [`.github/workflows/qml-lint.yml`](../.github/workflows/qml-lint.yml) —
  retrait de `--warnings-as-errors` (D6).
