# Development Journal — Nebula

> Journal des découvertes techniques faites en développant réellement
> Nebula. **Ce n'est pas une roadmap** (voir [`Roadmap.md`](Roadmap.md))
> **ni un ADR** (voir [`Decisions-Techniques.md`](Decisions-Techniques.md)).
> Une entrée ici documente un fait technique observé pendant le
> développement — pas une décision d'architecture, pas un statut de
> tâche. Reste court : uniquement ce qui a été réellement appris en
> construisant Nebula.

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
