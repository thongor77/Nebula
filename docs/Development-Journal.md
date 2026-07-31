# Development Journal — Nebula

> Journal des découvertes techniques faites en développant réellement
> Nebula. **Ce n'est pas une roadmap** (voir [`Roadmap.md`](Roadmap.md))
> **ni un ADR** (voir [`Decisions-Techniques.md`](Decisions-Techniques.md)).
> Une entrée ici documente un fait technique observé pendant le
> développement — pas une décision d'architecture, pas un statut de
> tâche. Reste court : uniquement ce qui a été réellement appris en
> construisant Nebula.

---

## 2026-07-31 — Phase 2.3

**Contexte** : tester `NebulaUserList`/`NebulaSessionSelector`/
`NebulaPowerButtons` sous `sddm-greeter --test-mode` réel, avec
`themes/template/Main.qml` câblé sur les vrais adapters
`platform/sddm/` (toujours des squelettes Phase 1.4 — listes vides,
capacités à `false`), pas les Mock adapters.

**Découverte** : aucune erreur, aucun avertissement. `NebulaUserList`
avec `userService.users` vide se réduit simplement à une largeur nulle
(aucune entrée à répéter) ; `NebulaSessionSelector` de même ;
`NebulaPowerButtons` n'affiche aucun bouton (tous les `can*` à `false`).
`NebulaLoginLayout` absorbe cette taille nulle sans erreur de layout.
Confirmé sur les 3 écrans réels de la machine.

**Impact** : valide empiriquement une propriété de conception déjà
supposée mais jamais vérifiée avec de vrais composants interactifs
(seuls des `console.log`/`Text` la sollicitaient auparavant, voir
`ServicesHarness.qml`) — un composant Core dépendant d'un Service dont
l'adapter est encore un squelette doit rester silencieux et fonctionnel,
jamais crasher. La navigation clavier/souris et le flux complet
d'authentification restent uniquement exercés via les Mock adapters
(`tests/LoginWorkflowHarness.qml`) tant que les adapters SDDM réels ne
sont pas câblés (voir `Login-Architecture.md` §8).

## 2026-07-31 — Phase 2.1

**Contexte** : tester Nord au-delà de `sddm-greeter --test-mode` depuis
le dépôt — copier `themes/nord/` vers son vrai emplacement d'installation
système, `/usr/share/sddm/themes/nord/`, puis le charger de là.

**Découverte** : `import "../../core/theme"` (et les imports similaires
vers `core/`/`platform/`) échoue — `"../../core/theme": no such
directory`. Ces chemins relatifs supposent que `core/`/`platform/`
existent deux niveaux au-dessus du thème, vrai uniquement à l'intérieur
du dépôt Git, jamais pour un thème installé séparément. SDDM lui-même
reste stable : bascule proprement sur son thème de secours intégré avec
un message d'erreur visible à l'écran, confirmé sur les 3 écrans réels de
la machine — aucun crash, aucun risque pour la session graphique réelle.

**Impact** : découverte majeure, voir
[`Nord-Validation-Report.md`](Nord-Validation-Report.md), Constat #1,
pour le détail complet et les options envisagées (module QML partagé via
`QML2_IMPORT_PATH`, Core embarqué par thème, lien symbolique
d'installation). Aucune implémentée cette phase — nécessite une phase de
packaging/distribution dédiée. Concerne tout futur thème de la même
façon, pas seulement Nord.

---

**Contexte** : `tests/ThemeInspector.qml` déclare `property
NebulaThemeConfig baseline: NebulaThemeConfig {}` pour comparer les
valeurs chargées aux valeurs par défaut du Core.

**Découverte** : `Cannot override FINAL property` — `baseline` est un
nom de propriété réservé (déjà déclaré `FINAL` plus haut dans la
hiérarchie de types QML/`Item`), impossible à redéclarer. Le message
d'erreur de compilation était clair et explicite, trouvé immédiatement
en testant.

**Impact** : renommé en `defaultsConfig`. Rappel pour la suite : un nom
de propriété générique et court (`baseline`, `value`, `data`, `state`,
...) risque de collisionner avec une propriété déjà définie sur `Item`/
`QtObject` ou un type Qt Quick de base — préférer un nom plus spécifique
dès le départ pour les nouveaux fichiers QML.

## 2026-07-31 — Phase 2.0.5

**Contexte** : `NebulaThemeLoader.reload()` restaure la valeur
précédente d'un token quand la nouvelle s'avère invalide
(`group[tokenName] = previous`), après avoir capturé `var previous =
group[tokenName]` avant l'assignation.

**Découverte** : la restauration échouait silencieusement — le message
de log affichait la valeur qu'on venait de rejeter (`#000000`, une
couleur invalide résolue en noir) au lieu de la vraie valeur par défaut
(`#4a90d9`). Cause : pour une propriété de type `color` (un objet, pas un
type primitif JS), `var previous = group[tokenName]` capture une
référence vivante vers la propriété, pas une copie — modifier
`group[tokenName]` ensuite modifie aussi ce que `previous` rapporte.
Confirmé isolément : `var previous = colorProp; colorProp = "invalide"`
fait que `previous` affiche également la nouvelle valeur. Les types
primitifs (`real`, `int`, `string`) n'ont pas ce problème (copiés par
valeur en JS).

**Impact** : corrigé par `var previous = "" + group[tokenName]` (force
une conversion en chaîne, donc une vraie copie) avant toute assignation.
Règle générale pour la suite : ne jamais faire confiance à `var x =
uneProprieteObjet` comme snapshot en QML/JS — toujours forcer une copie
(`"" + x`, ou équivalent) si la propriété source va être modifiée avant
que `x` soit relu.

---

**Contexte** : `Text { text: root.tokenLines.length + "..." + root.loader.configPath }`
dans `tests/ThemeHarness.qml`, affichant à la fois le nombre de tokens
chargés et le chemin source du thème.

**Découverte** : `QML Text: Binding loop detected for property "text"`.
Isolé par bissection (plusieurs reproductions minimales) : la cause
n'était ni `wrapMode`, ni `visible`, ni la conversion `.toString()` sur
l'`url` — c'était le fait de lire `loader.configPath` dans le même
binding qu'une valeur dérivée de `reload()` (`tokenLines`, qui dépend de
`loader.loaded`). Or `reload()` est justement déclenché par
`onConfigPathChanged` — donc ce `Text` dépend à la fois de la cause
(`configPath`) et de l'effet (`tokenLines`, mis à jour de façon
synchrone par le handler que ce changement déclenche), une vraie
ré-entrance dans le graphe de bindings, pas un faux positif de Qt.

**Impact** : corrigé en affichant `root.themeName` (une propriété stable,
non liée causalement au rechargement) plutôt que `loader.configPath`
dans ce texte. Règle pour la suite : ne jamais afficher, dans un même
binding, une propriété *et* une valeur dérivée d'un effet que cette
propriété déclenche elle-même via `onXChanged`.

---

**Contexte** : `NebulaThemeLoader` déclare `signal themeLoaded()` /
`themeLoadFailed(reason)`, émis depuis `reload()`, lui-même appelé par
`onConfigPathChanged` — donc dès que `configPath` reçoit sa valeur
initiale à la construction (cas courant : fourni comme littéral dans le
même bloc que l'instanciation du Loader).

**Découverte** : un handler `onThemeLoaded: ...` déclaré dans ce même
bloc d'objet ne reçoit jamais ce tout premier signal — reproduit
minimalement (un objet enfant qui change une propriété littérale à la
construction et émet un signal personnalisé depuis son propre
`onXChanged`, un objet parent avec un handler pour ce signal déclaré
dans le même bloc que l'instanciation de l'enfant). Le changement de
propriété ET l'émission ont bien lieu, mais le handler du parent n'est
pas encore connecté à ce stade de la construction — QML termine de
câbler les handlers déclarés dans un bloc après avoir résolu les
bindings de ce même bloc, pas avant.

**Impact** : `NebulaThemeLoader` documente ce piège explicitement (voir
`docs/ThemeLoader.md` §6) — les consommateurs doivent lire
`loaded`/`loadError`/`config` directement (fiables et synchrones dès que
leur propre code s'exécute), pas se fier aux signaux pour le tout premier
chargement. Les signaux restent utiles pour un changement de
`configPath` survenant après la construction initiale.

---

**Contexte** : distinguer, dans `NebulaThemeLoader._readIniGeneral()`, un
`theme.conf` manquant, un `theme.conf` réellement vide, et
`QML_XHR_ALLOW_FILE_READ` non défini.

**Découverte** : les trois cas produisent exactement le même résultat
via `XMLHttpRequest` sur `file://` — `status: 0`, `responseText.length:
0`, `readyState: 4`, `statusText: ""` — aucune différenciation possible
depuis QML. Vérifié en comparant les trois scénarios réels côte à côte.

**Impact** : voir [`Compatibility-Matrix.md`](Compatibility-Matrix.md)
§5 pour la décision prise (traiter les trois comme un échec de
chargement) et sa justification.

---

## 2026-07-31 — Phase 2.0

**Contexte** : `themes/template/Main.qml` doit peupler son propre
`NebulaThemeConfig` avec les valeurs de `theme.conf`, en l'absence de
`NebulaThemeLoader` (toujours non implémenté, voir `Roadmap.md`, Phase 1,
item 3). Tentative naturelle : surcharger les tokens un par un à
l'instanciation, comme le permet la syntaxe QML de propriété groupée
(`anchors.top: ...`).

**Découverte** : ça ne fonctionne pas. `NebulaThemeConfig { colors.primaryColor:
"red" }` échoue à la compilation (`Cannot assign to non-existent property
"primaryColor"`) — testé réellement avant d'écrire le vrai code. La
syntaxe de propriété groupée exige que le compilateur QML connaisse le
type exact de la propriété groupée (comme `anchors`, un type QtQuick
dédié) ; un `readonly property QtObject colors: QtObject { ... }`
générique et anonyme ne qualifie pas. En revanche, l'assignation
impérative après construction (`config.colors.primaryColor = "red"`)
fonctionne parfaitement : `colors` est en lecture seule (on ne peut pas
remplacer l'objet), mais `primaryColor` à l'intérieur ne l'est pas.

**Impact** : `Main.qml` et `ThemeHarness.qml` peuplent leur config via une
fonction `applyFlatValues()` qui fait cette assignation impérative,
groupe par groupe, plutôt que via une syntaxe déclarative. Voir
l'audit ci-dessous pour la suite (D22, `Core-Implementation-Status.md`).

---

**Contexte** : la même fonction `applyFlatValues()`, une fois testée sous
`sddm-greeter --test-mode` réel (pas seulement `qml6` standalone) avec la
vraie propriété de contexte `config`.

**Découverte** : deux bugs réels, invisibles en test standalone parce que
mes tests utilisaient des objets JS litéraux (`{}`) au lieu du vrai
`config` :
1. `flatValues.hasOwnProperty(tokenName)` lève `TypeError: ... is not a
   function` — `config` sous `sddm-greeter` est un vrai `QObject` natif
   (`SDDM::ThemeConfig`), pas un objet JS ; `hasOwnProperty` n'existe pas
   dessus. Remplacé par `flatValues[tokenName] !== undefined`, qui
   fonctionne sur les deux.
2. Avec ce correctif seul, nouveau crash : `Cannot assign to read-only
   property "objectNameChanged"`. `Object.keys(group)` (voir l'entrée
   Phase 1.6 sur l'énumération des `QtObject`) renvoie aussi
   `objectName` et chaque signal `xxxChanged` — et l'accès par crochet à
   `config["objectNameChanged"]` renvoie bien quelque chose (le signal
   lui-même), pas `undefined`, donc le code tentait d'assigner dessus.
   Corrigé en filtrant `tokenNames` sur `key !== "objectName" &&
   typeof group[key] !== "function"`.

**Impact** : les deux bugs corrigés et revérifiés avec un vrai
`sddm-greeter-qt6 --test-mode --theme themes/template` sur les 3 écrans
réels de la machine (`primaryColor` changé temporairement en `#ff00ff`
pour confirmer visuellement que la chaîne `theme.conf → config →
applyFlatValues → NebulaThemeProvider → NebulaButton` fonctionne
réellement de bout en bout). Rappel pour la suite : tester un mécanisme
touchant une propriété de contexte SDDM réelle (`config`, `sddm`,
`userModel`, ...) toujours sous `sddm-greeter --test-mode`, jamais
seulement en `qml6` standalone avec des objets JS de substitution — les
deux se comportent différemment.

---

**Contexte** : lire `theme.conf` depuis `tests/ThemeHarness.qml`, qui
doit fonctionner en standalone (`qml6`, sans SDDM, donc sans la véritable
propriété de contexte `config`).

**Découverte** : `XMLHttpRequest` sur un fichier local (`file://`) est
désactivé par défaut dans ce build Qt6 — `xhr.send()` renvoie un statut
`0` silencieusement plutôt que de lever une erreur claire. Il faut
`QML_XHR_ALLOW_FILE_READ=1` pour l'activer.

**Impact** : `tests/ThemeHarness.qml` documente cette variable
d'environnement dans son commentaire d'usage, et distingue explicitement
« statut 0 avec réponse vide » (probablement la variable d'environnement
manquante) de tout autre échec dans son message d'erreur affiché à
l'écran, pour éviter à un futur contributeur de chercher au mauvais
endroit.

---

**Contexte** : premier texte affiché par `tests/ThemeHarness.qml`
(titre, statut de chargement, libellés de section) — écrit en blanc
(`color: "white"`), comme les autres harnais du projet.

**Découverte** : `Item` n'a pas de fond propre ; sans couleur de fond
explicite, ce texte blanc s'affichait sur le fond blanc par défaut du
runtime QML — totalement invisible, confirmé par capture d'écran avant
correction.

**Impact** : ajout d'un `Rectangle` de fond (`#1e1e1e`) derrière le
contenu. Rappel pour tout futur harnais autonome (root `Item`, pas
`Window`/thème réel qui fournit déjà un fond) : ne jamais assumer un
fond sombre implicite.

## 2026-07-31 — Phase 1.6

**Contexte** : écrire `tests/ThemeSyncCheck.qml`, qui doit détecter
automatiquement tout token présent dans `NebulaThemeConfig` mais oublié
dans `NebulaThemeProvider` (voir l'entrée Phase 1.5 ci-dessous — c'est
exactement ce bug que ce test doit attraper mécaniquement).

**Découverte** : un `QtObject` déclaré en QML est bien énumérable côté
JavaScript — `Object.keys(obj)` et `for (var k in obj)` renvoient les
noms de toutes ses `property` déclarées (plus `objectName` et les
signaux `xxxChanged`). Testé réellement avec un fichier `qml6` minimal
avant de l'utiliser dans le vrai test. Cela permet de comparer les
groupes de tokens exposés par deux objets sans lister leurs noms à la
main (donc sans avoir à maintenir cette liste séparément du code réel).

**Impact** : `ThemeSyncCheck.qml` compare `Object.keys(config)` à
`Object.keys(provider)` (filtrés aux propriétés de type objet) et échoue
avec `Qt.exit(1)` si un groupe manque — vérifié réellement dans les deux
sens (retrait temporaire de `interaction` dans `NebulaThemeProvider` →
échec détecté ; remise en place → succès).

---

**Contexte** : lire la sortie `console.log`/`console.error` de `qml6`
directement dans ce terminal, sans passer par `journalctl` (voir l'entrée
Phase 1.2 ci-dessous, qui documentait déjà que `qml6` route ses logs vers
le journal quand il tourne détaché d'un terminal interactif).

**Découverte** : la variable d'environnement `QT_LOGGING_TO_CONSOLE=1`
(ou les remplaçants recommandés par l'avertissement de dépréciation,
`QT_ASSUME_STDERR_HAS_CONSOLE=1`/`QT_FORCE_STDERR_LOGGING=1`) force Qt à
écrire directement sur stderr, sans redirection ni `journalctl`
intermédiaire. Plus direct que le contournement documenté en Phase 1.2
pour ce cas précis (lire la sortie d'un script qu'on vient de lancer
soi-même) — `journalctl` reste nécessaire quand on inspecte les logs
*a posteriori* d'un processus déjà lancé autrement (ex. le vrai greeter
SDDM).

**Impact** : `tests/ThemeSyncCheck.qml` et `scripts/check-design-system.sh`
s'appuient sur cette variable pour rester silencieux/lisibles en usage
normal (terminal interactif) tout en produisant une sortie exploitable
quand on les lance depuis un script ou un outil automatisé.

---

**Contexte** : faire fermer automatiquement les fenêtres de
`VisualHarness.qml`/`LoginScreenHarness.qml` ouvertes par
`scripts/check-design-system.sh`, pour tester le script de bout en bout
sans intervention manuelle.

**Découverte** : `xdotool search`/`windowclose` ne voit aucune fenêtre
`qml6` sur cette session — normal, ce sont des clients Wayland natifs
(`WAYLAND_DISPLAY=wayland-0`), et `xdotool`/`wmctrl` n'ont accès qu'aux
fenêtres X11/XWayland. Aucun équivalent (`kdotool`, `ydotool`) n'est
installé. Envoyer `SIGTERM` au processus (`pkill`) fonctionne pour
l'arrêter mais produit un code de sortie non nul (`143`), contrairement
à une fermeture propre par clic sur le bouton de fermeture — deux
chemins de sortie différents, seul le premier a pu être testé ici.

**Impact** : `scripts/check-design-system.sh` ne conditionne jamais son
propre succès au code de sortie des harnais visuels (`|| true`) — ce
sont des vérifications manuelles à l'œil, jamais un pass/fail
automatique, donc peu importe lequel des deux chemins de sortie se
produit en usage réel.

---

## 2026-07-31 — Phase 1.5

**Contexte** : test manuel de `NebulaBackground`/`NebulaWallpaper` en
plaçant plusieurs instances de `NebulaBackground` côte à côte dans un
`Row`, pour comparer visuellement plusieurs configurations à la fois.

**Découverte** : le rendu était incohérent (les trois panneaux censés
être séparés semblaient fusionner en une seule image continue).
`journalctl` a révélé l'avertissement réel : `QML Row: Cannot specify
left, right, horizontalCenter, fill or centerIn anchors for items inside
Row. Row will not function.`

**Cause** : `NebulaBackground` utilise `anchors.fill: parent` en interne
(cohérent avec son rôle de conteneur plein écran). Les positionneurs Qt
Quick (`Row`, `Column`, `Grid`) gèrent eux-mêmes la position de leurs
enfants et interdisent explicitement `fill`/`centerIn`/ancrages sur ces
enfants directs.

**Solution** : ce n'est pas un bug de `NebulaBackground` — c'est un usage
invalide. Le harnais de test a été corrigé pour tester chaque
configuration séparément (une fenêtre entière à la fois) plutôt que côte
à côte dans un `Row`. Documenté comme contrainte d'usage explicite dans
`Core-API.md`.

**Impact** : tout composant Core qui utilise `anchors.fill: parent` en
interne (`NebulaBackground`, `NebulaLoginLayout`) ne doit jamais être
placé comme enfant direct d'un `Row`/`Column`/`Grid`. Règle ajoutée à
`Rendering-Guidelines.md`.

---

## 2026-07-31 — Phase 1.5

**Contexte** : ajout des groupes `overlay`/`surface` dans
`NebulaThemeConfig.qml` pour `NebulaOverlay`. Rendu testé réellement
(`qml6` + capture d'écran) par-dessus un `NebulaWallpaper` déjà validé.

**Découverte** : le voile s'affichait totalement opaque (fond noir uni),
cachant complètement le wallpaper en dessous — alors que
`overlayOpacity` valait `0.35` par défaut.

**Cause** : `theme.overlay.overlayOpacity` levait
`TypeError: Cannot read property 'overlayOpacity' of undefined` —
visible uniquement via `journalctl`. Le groupe `overlay` avait bien été
ajouté à `NebulaThemeConfig.qml`, mais pas répercuté dans
`NebulaThemeProvider.qml`, qui ré-expose chaque groupe une par une
(`readonly property QtObject colors: config.colors`, etc.) plutôt que de
déléguer génériquement à `config`. Le binding `opacity:` en échec a
laissé la propriété à sa valeur par défaut (opaque), plutôt que de
propager visiblement une erreur.

**Solution** : ajout de `readonly property QtObject overlay:
config.overlay` et `surface: config.surface` dans
`NebulaThemeProvider.qml`.

**Impact** : chaque nouveau groupe de tokens ajouté à
`NebulaThemeConfig.qml` doit être répercuté manuellement dans
`NebulaThemeProvider.qml` — ce n'est pas automatique. À surveiller à
chaque futur ajout de token tant que ce passage un par un n'est pas
remplacé par un mécanisme générique.

---

## 2026-07-30 — Phase 1.4

**Contexte** : `NebulaAuthService.qml` (racine `QtObject`) devait réagir
au signal `loginResult` émis par son `adapter`, injecté dynamiquement via
une propriété. Écrit avec un bloc `Connections { target: root.adapter;
... }` déclaré comme enfant direct du `QtObject`.

**Découverte** : `qmllint` ne signale rien, mais `qml6` refuse de charger
le fichier — `Cannot assign to non-existent default property` (visible
via `journalctl`, comme systématiquement pour les outils Qt détachés d'un
terminal — voir entrées Phase 1.0/1.2 ci-dessous).

**Cause** : `QtObject` ne déclare pas de "default property" pour
recevoir un enfant anonyme comme `Connections { ... }`. `Item`, lui, en
déclare une (`default property list<QtObject> data`) — mais `QtObject`
seul n'a rien de tel.

**Solution** : connecter le signal en JavaScript impératif
(`adapter.loginResult.connect(...)` dans un handler `onAdapterChanged`)
plutôt que via un bloc déclaratif. Le même piège existait dans
`tests/mocks/MockAuthAdapter.qml`, qui avait lui un vrai besoin d'un
`Timer` enfant (pas contournable en JS) — corrigé en changeant son type
racine de `QtObject` à `Item`.

**Impact** : règle générale pour tout futur composant non-visuel du
Core — voir DT-0011 dans `Decisions-Techniques.md`. `QtObject` reste le
type par défaut pour la logique pure ; passer à `Item` uniquement quand
un enfant déclaratif (`Timer`, `Connections`, ...) est réellement
nécessaire.

---

## 2026-07-30 — Phase 1.3

**Contexte** : intégration de `NebulaLoginLayout` dans
`tests/LoginScreenHarness.qml`, en centrant le contenu (`Column`) à
l'intérieur d'une zone dont la hauteur se calcule elle-même à partir de
ce même contenu (`height: childrenRect.height`).

**Découverte** : `qml6` refuse de démarrer proprement et logue
`QML Item: Binding loop detected for property "height"` (visible
uniquement via `journalctl`, comme pour `sddm-greeter` — voir entrée du
2026-07-30, Phase 1.0, plus bas).

**Cause** : le contenu utilisait `anchors.centerIn: parent`. Centrer un
élément dépend de la hauteur de son parent ; mais la hauteur de ce
parent (`mainArea`) est elle-même dérivée de `childrenRect`, qui dépend
de la position/taille de ce même contenu — boucle.

**Solution** : quand une zone se dimensionne sur son contenu
(`childrenRect`-based), ce contenu doit se centrer **horizontalement
seulement** (`anchors.horizontalCenter: parent.horizontalCenter`), jamais
avec `anchors.centerIn: parent`. Documenté comme contrat explicite dans
`core/layouts/NebulaLoginLayout.qml`.

**Impact** : tout futur contenu placé dans `mainContent`/`statusContent`
de `NebulaLoginLayout` doit respecter cette règle. À surveiller si
d'autres layouts "hug content" sont ajoutés plus tard.

---

## 2026-07-30 — Phase 1.3

**Contexte** : test de `NebulaLoginLayout` à plusieurs tailles/ratios de
fenêtre (large 16:9, portrait étroit, très bas et large ~3:1).

**Découverte** : sur une fenêtre très basse et large (ex. 900×300), le
contenu déborde verticalement — l'horloge est coupée en haut, le bouton
en bas.

**Cause** : le contenu se centre verticalement dans l'écran entier sans
jamais réduire sa propre taille (espacement, police) quand la hauteur
disponible devient très petite — aucune logique de rétrécissement
adaptatif n'existe encore.

**Solution** : aucune pour l'instant — limitation assumée et documentée
plutôt que traitée par une complexité non demandée à ce stade (voir
`Core-Implementation-Status.md`, Phase 1.3).

**Impact** : les résolutions d'écran réelles (voir
`SDDM-Compatibility.md`) ont toutes un ratio nettement moins extrême que
3:1, donc non bloquant pour le Core MVP. À revisiter si un thème doit un
jour supporter un écran très bas (ex. bandeau d'affichage embarqué).

---

## 2026-07-30 — Phase 1.2

**Contexte** : vérification ad hoc de `NebulaAvatar` avec une vraie image
dans un fichier QML de test placé dans `/tmp`, important le Core par
chemin absolu (`import "/home/luust/.../core/theme"`).

**Découverte** : `qml6` échoue avec un message générique et peu clair,
`Did not load any objects, exiting`.

**Cause** : le moteur QML n'accepte pas un chemin d'import absolu sans
schéma d'URL. La vraie raison n'apparaissait que dans `journalctl` :
`"... is not a valid import URL ... Try "file:/...".`.

**Solution** : toujours utiliser des chemins **relatifs** pour les
imports internes du Core (`import "../theme"`) — jamais de chemin
absolu, même dans un fichier de test jetable.

**Impact** : évite de reperdre du temps à rediagnostiquer la même erreur
peu explicite plus tard.

---

## 2026-07-30 — Phase 1.1

**Contexte** : premiers tokens par défaut de `NebulaThemeConfig`, testés
visuellement avec `NebulaButton` (focus clavier, contour `accentColor`).

**Découverte** : le contour de focus était invisible sur un bouton
`primary` — capture d'écran à l'appui.

**Cause** : `accentColor` avait été défini avec exactement la même valeur
que `primaryColor` dans la palette de repli par défaut.

**Solution** : `accentColor` mis à une teinte nettement distincte
(ambre, `#f0a030`), revérifié visuellement.

**Impact** : leçon générale, pas seulement un bug ponctuel —
`accentColor` doit toujours rester visuellement distinct de
`primaryColor`/`secondaryColor` dans n'importe quelle palette, sous peine
de rendre les indicateurs de focus inutiles pour l'accessibilité.

---

## 2026-07-30 — Phase 1.1

**Contexte** : mise en place du lint QML local et en CI
(`.github/workflows/qml-lint.yml`), documentée depuis la Phase 0.5 avec
le flag `--warnings-as-errors`.

**Découverte** : `qmllint --warnings-as-errors` échoue avec
`Unknown option 'warnings-as-errors'` sur le `qmllint` réellement
installé (Qt 6.11.1).

**Cause** : ce flag n'existe pas sur ce binaire (`qmllint --help` ne le
liste pas) — documenté sans avoir été vérifié au moment de l'écrire.

**Solution** : retiré. Vérifié que `qmllint` sans option échoue déjà
(code de sortie non nul) sur une vraie erreur de syntaxe, donc le flag
n'apportait rien.

**Impact** : rappel à se méfier des flags d'outils documentés sans
vérification empirique — voir aussi l'entrée Phase 1.0 ci-dessous sur le
même thème (vérifier plutôt que supposer).

---

## 2026-07-30 — Phase 1.0

**Contexte** : premier test réel de `sddm-greeter-qt6 --test-mode` avec
un prototype minimal (`prototype/Main.qml`), sortie redirigée vers un
fichier (`> out.log 2>&1`).

**Découverte** : le fichier de log reste vide alors que le greeter tourne
normalement (fenêtre visible, aucun crash).

**Cause** : `sddm-greeter` bascule sur le journal systemd dès qu'il
détecte ne pas être attaché à un terminal interactif — ce qui est
systématiquement le cas derrière une redirection shell.

**Solution** : utiliser `journalctl --no-pager -n 100 | grep ...` pour
lire les logs du greeter, jamais une redirection stdout/stderr classique.

**Impact** : appliqué ensuite à `qml6` lui-même (voir entrée Phase 1.2
ci-dessus) — le même piège existe dès qu'un outil Qt tourne détaché d'un
terminal.

---

## 2026-07-30 — Phase 1.0

**Contexte** : `prototype/Main.qml` tentait de lire
`screenModel.count` directement pour afficher le nombre d'écrans exposés
par SDDM.

**Découverte** : `TypeError: Cannot call method 'toString' of undefined`
— visible seulement via `journalctl` (voir entrée précédente).

**Cause** : `screenModel` est un `QAbstractItemModel`, pas un objet avec
une propriété `.count` accessible directement.

**Solution** : lier `screenModel` à un `Repeater` invisible et lire
`repeater.count` à la place.

**Impact** : tout composant Core consommant un modèle exposé par SDDM
(`userModel`, `sessionModel`, ...) doit passer par un vrai modèle QML
(`Repeater`/`ListView`), jamais supposer une API de type objet simple.
