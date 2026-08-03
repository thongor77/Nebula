# Development Journal — Nebula

> Journal des découvertes techniques faites en développant réellement
> Nebula. **Ce n'est pas une roadmap** (voir [`Roadmap.md`](Roadmap.md))
> **ni un ADR** (voir [`Decisions-Techniques.md`](Decisions-Techniques.md)).
> Une entrée ici documente un fait technique observé pendant le
> développement — pas une décision d'architecture, pas un statut de
> tâche. Reste court : uniquement ce qui a été réellement appris en
> construisant Nebula.

---

## 2026-08-02 — Phase 3.2 (3.2.4, code — validation réelle en attente)

**Contexte** : implémentation de `SDDMAuthAdapter` (voir `Roadmap.md`,
3.2.4) et de la property `NebulaAuthService.sessionService` (DT-0024).
Dernier des 4 adapters, seul à ne pas pouvoir être validé de bout en
bout depuis ce terminal — `Prototype-Results.md` §3.5 confirme qu'aucun
backend d'authentification réel n'est jamais connecté en `--test-mode`.

**Implémenté** :

- `NebulaAuthService.authenticate()` lit désormais
  `sessionService.currentIndex` (si `sessionService` est défini) et le
  transmet en 3e argument à `adapter.login()` — signature publique
  d'`authenticate(username, password)` inchangée, conformément à
  DT-0024.
- `SDDMAuthAdapter.login(username, password, sessionIndex)` appelle
  `sddm.login(username, password, resolvedIndex)`, avec repli sur
  `sessionModel.lastIndex` si `sessionIndex` est `-1`/absent.
- Écoute imperative (`Component.onCompleted`, `QtObject` — pas besoin
  d'`Item` ici, aucun enfant déclaratif requis, contrairement à
  `SDDMUserAdapter`/`SDDMSessionAdapter`) de `sddm.loginSucceeded()`/
  `loginFailed()`, confirmés sans argument en 3.2.0 : `reason` transmis
  à `NebulaAuthService` reste donc toujours un texte générique
  ("Authentication failed"), jamais un message SDDM.
- `cancel()` est un no-op documenté : SDDM n'expose aucune API pour
  interrompre un `sddm.login()` en cours, seuls `loginSucceeded`/
  `loginFailed` existent — limitation réelle assumée, pas un oubli.
- `themes/glass-dark/Main.qml` et `themes/glass-light/Main.qml` (seuls
  thèmes avec un sélecteur de session) mis à jour :
  `authService.sessionService: sessionService`. `nord` n'a pas de
  sélecteur de session, laissé inchangé (repli sur `sessionModel.lastIndex`
  dans l'adapter, comportement correct pour ce thème).

**Vérification faite** : `qmllint` propre sur les 4 fichiers touchés
(exit 0, seulement les avertissements attendus `Unqualified access` sur
les vraies propriétés `sddm`/`sessionModel`). Chargement passif sous
`sddm-greeter-qt6 --test-mode` sur les 3 thèmes (`nord`, `glass-dark`,
`glass-light`) sans authentifier : aucune erreur QML, en particulier
aucune `TypeError` sur `sddm.loginSucceeded.connect`/`loginFailed.connect`
— confirme que ces signaux existent bien et sont connectables même en
mode test (ce qui n'était pas garanti a priori). Une ligne
`[destroyed object]: error 1: xdg_wm_base was destroyed before children`
observée une fois sur `glass-dark` — artefact de fermeture Wayland causé
par `timeout` qui tue le process pendant le teardown du protocole, sans
rapport avec le code Nebula (déjà vu ailleurs quand un client Wayland est
tué brutalement).

**Vérification NON faite, volontairement** : le round-trip réel d'un
`sddm.login()` complet (identifiants corrects → session lancée,
identifiants incorrects → `loginFailed` réellement reçu). Nécessite le
vrai `sddm.service`, jamais `--test-mode` — à faire sous le protocole
sûr déjà documenté pour l'incident VT/DRM du même jour, avec la
participation active de l'utilisateur (redémarrage, rester sur le
greeter, aucune session bureau `kwin_wayland` vivante en parallèle).

## 2026-08-02 — Phase 3.2 (3.2.3)

**Contexte** : implémentation réelle de `SDDMUserAdapter` (voir
`Roadmap.md`, 3.2.3), même patron `Instantiator` + accès explicite
`model.<rôle>` que `SDDMSessionAdapter` (3.2.2) — leçon de 3.2.2
appliquée dès la première version cette fois, pas de tentative
d'identifiant nu.

**Décision de périmètre** : `userModel` expose 10 rôles confirmés en
3.2.0, mais `NebulaUserList`/`NebulaAvatar` (lecture directe du code,
`Core-API.md`) ne consomment que `.icon` et `.displayName` sur chaque
objet de `users`, et les thèmes (`nord`/`glass-dark`, lecture directe de
leurs `Main.qml`) ne consomment en plus que `.name` (transmis tel quel à
`authenticate(username, ...)`, donc à `sddm.login()` au final). Seuls
`name`, `realName` (repli sur `name` si vide — logique reprise
identique à `UserList.qml` du vrai `breeze`) et `icon` sont donc mappés
— ne pas ajouter `homeDir`/`needsPassword`/`vtNumber`/... sans un besoin
réel démontré par un composant ou un thème (principe de travail du
workspace).

**Vérification réelle** (`console.warn` temporaire, retiré après coup) :
sous `sddm-greeter-qt6 --test-mode` avec `glass-dark`, les deux vrais
comptes de la machine apparaissent correctement : `claudesvc` (pas de
`realName` défini, repli confirmé fonctionnel : `displayName` devient
`"claudesvc"`) et `luust` (`realName` = `"luust"`). Icônes réelles
résolues vers `file:///usr/share/sddm/themes/breeze/faces/.face.icon`
(image de visage par défaut du thème `breeze`, utilisée par SDDM pour
tout compte sans photo personnalisée — cohérent avec
`NebulaAvatar.source`, qui accepte directement une URL `file://`).
Reproduit à l'identique sur `nord` (qui câble aussi `SDDMUserAdapter`,
contrairement à `SDDMPowerAdapter`/`SDDMSessionAdapter` qu'il n'utilise
pas). Aucune erreur QML dans les deux cas.

**Étape 3.2.3 marque la fin de la partie "lecture seule" de la Phase
3.2** : `SDDMPowerAdapter`, `SDDMSessionAdapter` et `SDDMUserAdapter`
sont désormais réels et tous les trois vérifiés sous `--test-mode`. Il
ne reste que `SDDMAuthAdapter` (3.2.4), qui exige le vrai `sddm.service`
et le protocole sûr déjà documenté.

## 2026-08-02 — Phase 3.2 (3.2.2)

**Contexte** : implémentation réelle de `SDDMSessionAdapter` (voir
`Roadmap.md`, 3.2.2) — matérialiser `sessionModel` (rôle `name`
confirmé en 3.2.0) en tableau JS consommable par
`NebulaSessionService`/`NebulaSessionSelector`.

**Découverte (trouvée en testant, pas en lisant la doc)** : une première
version du délégué de l'`Instantiator` déclarait `property string name:
""` et s'attendait à ce que le rôle `name` du modèle remplisse cette
property automatiquement par identifiant nu (injection de contexte
implicite classique des vues QML). Résultat réel, observé via un
`console.warn` temporaire sous `sddm-greeter-qt6 --test-mode` : la valeur
restait vide (`"TEMP-DEBUG SDDMSessionAdapter added: 0 "`, rien après
l'index). Corrigé en accédant explicitement à `model.name` — exactement
le style déjà utilisé par le vrai `SessionButton.qml` de Breeze
(`text: model.name`), qui aurait dû être suivi à la lettre dès le départ
plutôt que supposé équivalent à un accès par identifiant nu pour un
délégué `QtObject` sous `Instantiator`. `qmllint` confirme d'ailleurs
après coup que `model` est "implicitement injecté" dans ce délégué —
l'identifiant nu, lui, n'a jamais été injecté de la même façon ici.

**Vérification réelle** : même `console.warn` temporaire, retiré après
coup, a confirmé les deux vraies sessions de la machine correctement
matérialisées : `"Plasma (Wayland)"` (index 0) et `"Plasma (X11)"`
(index 1) — cohérent avec les fichiers `.desktop` réellement lus par le
greeter (`/usr/share/wayland-sessions/plasma.desktop`,
`/usr/share/xsessions/plasmax11.desktop`, visibles dans les logs de
démarrage). Reproduit à l'identique sur les 3 écrans réels de la
machine. Aucune erreur QML après retrait du debug.

**Impact** : confirme que le patron "rôle de modèle exposé par un
identifiant nu dans un délégué `QtObject`" ne doit **pas** être supposé
pour `SDDMUserAdapter` (3.2.3, même patron de matérialisation, plus de
rôles) — utiliser systématiquement `model.<rôle>` explicite dès la
première version, pas comme correctif après coup.

## 2026-08-02 — Phase 3.2 (3.2.1)

**Contexte** : implémentation réelle de `SDDMPowerAdapter` (voir
`Roadmap.md`, 3.2.1), premier des 4 adapters, choisi en premier car
présenté comme le plus simple — aucune inconnue de rôle de modèle, juste
un mapping direct de propriétés/méthodes.

**Découverte** : décalage de nommage réel entre notre propre contrat
(`canShutdown`/`shutdown()`, hérité du vocabulaire de
`NebulaPowerButtons`) et l'API SDDM réelle, qui n'a pas de
`canShutdown`/`shutdown()` — seulement `canPowerOff`/`powerOff()`
(confirmé par `Prototype-Results.md` §3.2 et par l'usage réel dans
`breeze/Main.qml`). Sans cette vérification, un mapping naïf
(`canShutdown: sddm.canShutdown`) aurait échoué silencieusement
(`undefined` côté SDDM, jamais d'erreur QML visible).

**Vérification (prudente, sans déclencher d'action système réelle)** :
`sddm-greeter-qt6 --test-mode --theme themes/glass-dark` (seul thème
câblant `NebulaPowerButtons` à ce jour ; `nord` ne l'utilise pas encore)
lancé avec `timeout 6` et sans aucune interaction clavier/souris —
uniquement pour observer les logs (`QT_LOGGING_TO_CONSOLE=1`,
`QML_XHR_ALLOW_FILE_READ=1`, voir `Development-Environment.md`).
Résultat : chargement propre sur les 3 écrans réels de la machine
(`eDP-1`, `DP-7`, `DP-9`), aucune erreur QML référençant `sddm` ou
`SDDMPowerAdapter` — le binding `readonly property bool canShutdown:
sddm.canPowerOff` s'évalue donc correctement. Volontairement **aucun
clic sur un bouton d'action** pendant ce test : contrairement à
`sddm.login()` (jamais connecté à un vrai backend en `--test-mode`, voir
§3.5 de `Prototype-Results.md`), rien ne confirme que
`sddm.powerOff()`/`reboot()`/`suspend()`/`hibernate()` soient eux aussi
neutralisés en mode test — un clic réel aurait pu déclencher une vraie
action système sur la machine de développement. Reste donc non vérifié
directement : le comportement réel d'un clic sur ces boutons (que ce
soit en `--test-mode` ou sous le vrai service) — à traiter avec la même
prudence que 3.2.4 (`SDDMAuthAdapter`) si un jour un test actif de ces
actions devient nécessaire.

## 2026-08-02 — Phase 3.2

**Contexte** : étape 3.2.0 (voir `Roadmap.md`) — avant d'implémenter les
4 adapters `platform/sddm/` réels, lever les inconnues bloquantes
identifiées lors de la revue de code (rôles réels exposés par
`userModel`/`sessionModel`, forme réelle des signaux de résultat de
`sddm.login()`) sans manipuler le greeter actif de la machine — le
risque de course DRM/VT documenté le même jour (`nebula-vt-switch-freeze`)
rendait hors de question un test actif superflu.

**Méthode** : plutôt qu'un test actif (`sddm-greeter --test-mode` avec un
thème jetable, comme en Phase 1.0), lecture statique du thème `breeze`
réellement installé et utilisé en production sur cette machine
(`/usr/share/sddm/themes/breeze/*.qml` et le composant partagé
`/usr/lib/qt6/qml/org/kde/breeze/components/UserList.qml`). Zéro
exécution du greeter, zéro risque — et une source plus fiable qu'une
sonde ad hoc écrite pour l'occasion, puisque c'est le code que KDE fait
réellement tourner sur cette machine.

**Découvertes** :

- `userModel` : rôles confirmés par le commentaire de type de
  `UserList.qml` (composant KDE partagé, pas spécifique à Breeze) et par
  leur usage réel dans le délégué : `name`, `realName`, `homeDir`,
  `icon`, `iconName?`, `needsPassword?`, `displayNumber?`, `vtNumber?`,
  `session?`, `isTty?`.
- `sessionModel` : rôle `name` confirmé (`SessionButton.qml` de Breeze :
  `model.name`), sélectionné par index de ligne — aucun rôle "id" dédié
  observé, l'index sert directement de `sessionIndex`.
- `sddm.login(username, password, sessionIndex)` confirmé avec 3
  arguments positionnels réels (`Main.qml:243` et `:350` de Breeze).
- Signaux réels `sddm.loginSucceeded()` / `sddm.loginFailed()` confirmés
  — **sans aucun argument** (`Connections { target: sddm; function
  onLoginFailed() {...} }`, `Main.qml:513-528` et `Login.qml:134-140` de
  Breeze). Le vrai SDDM ne transmet donc jamais de message de raison
  d'échec au greeter, contrairement à ce que suggérait le contrat actuel
  `NebulaAuthService.failed(reason)`/`errorMessage` : `reason` restera
  toujours un texte générique choisi par Nebula, jamais une chaîne
  fournie par SDDM. Pas un bug à corriger — SDDM ne l'expose simplement
  pas.

**Impact** : lève les deux inconnues qui bloquaient l'implémentation des
4 adapters réels, sans le moindre risque pour le greeter actif. Une
inconnue reste non levée par lecture statique : le comportement réel
d'un appel `sddm.login()` complet (round-trip) ne peut être vérifié que
sous le vrai `sddm.service` (`Prototype-Results.md` §3.5 : aucun backend
d'authentification en `--test-mode`) — reportée à l'étape 3.2.4, seule
étape de la Phase 3.2 nécessitant le protocole sûr déjà documenté pour
l'incident VT/DRM.

## 2026-07-31 — Phase 3.1

**Contexte** : revue de consolidation du Core (Phase 3.1, voir
`Core-Refinement-Review.md`) — vérifier si `KeyNavigation.tab` ciblant
`NebulaPasswordField` amène réellement le focus clavier sur le champ
saisissable, pas seulement sur le composant lui-même.

**Découverte** : `NebulaPasswordField` est un `Rectangle` simple, pas un
`FocusScope`. `KeyNavigation.tab: passwordField` appelle
`passwordField.forceActiveFocus()`, qui donne `activeFocus` au
`Rectangle` racine — pas au `TextInput` interne. Vérifié avec un
harnais jetable : `Window.activeFocusItem === passwordField` (`true`)
avant correctif, `.echoMode` de cet item `undefined` (confirme que ce
n'est pas le `TextInput`, qui seul possède cette propriété). Après
ajout de `activeFocusOnTab: true` +
`onActiveFocusChanged: if (activeFocus) input.forceActiveFocus()` sur
la racine : `activeFocusItem === passwordField` devient `false`, et son
`.echoMode` vaut `2` (`TextInput.Password`, une vraie valeur numérique)
— confirme que le focus réel est bien redirigé vers le `TextInput`.

**Méthode de vérification sans clavier réel** : `xdotool` ne fonctionne
pas du tout sur cette session Wayland native (déjà noté en Phase 3.0,
reconfirmé : même la recherche de fenêtre échoue, pas seulement
l'injection de touches). `forceActiveFocus()` appelé directement en QML
reproduit fidèlement ce que `KeyNavigation.tab` déclenche en interne
(même appel), donc un harnais jetable qui l'appelle puis inspecte
`Window.activeFocusItem` vérifie le comportement réel sans avoir besoin
d'une vraie frappe clavier.

**Impact** : bug réel, présent depuis la Phase 2.3, touchant tout thème
utilisant `NebulaPasswordField` (Glass, Template) — jamais remarqué
avant car aucun test précédent n'avait vérifié l'identité de
`activeFocusItem` après un `Tab`, seulement l'apparence visuelle de la
bordure de focus (qui, elle, restait correcte car liée à
`input.activeFocus` dans le binding de couleur de bordure — la
bordure semblait donc juste, masquant que le focus clavier réel n'était
pas là où il semblait être).

**Découverte n°2** : tenter d'ajouter `iconColor` (property color) à
`NebulaButton`/`NebulaPasswordField`/`NebulaPowerButtons`, comme
suggéré en exemple par le brief de la Phase 3.1 — impossible en QtQuick
pur : teinter une `Image` arbitraire nécessite un `ShaderEffect` ou
`MultiEffect`/`Qt5Compat.GraphicalEffects`, tous deux explicitement
interdits dans `core/` (`Rendering-Guidelines.md` §2). Propriété non
implémentée plutôt que contournée avec un effet interdit — documenté
dans `Core-API.md`/`Core-Refinement-Review.md` §2.

**Découverte n°3** (mesure, pas une hypothèse) : calcul réel des ratios
de contraste WCAG (luminance relative sRGB, formule standard) sur les
couleurs effectivement utilisées par chaque `theme.conf`. Le libellé du
bouton Unlock de Nord (`textPrimary` sur `primaryColor`) mesure
**1.74:1** — largement sous le seuil WCAG AA (4.5:1) — visible à l'œil
sur une capture d'écran réelle (bouton et texte au contraste très
faible, tous deux clairs). Glass Dark/Light mesurent ~3.6:1, conformes
seulement pour du texte large. Cause structurelle : `NebulaButton`
utilise `theme.colors.textPrimary` pour tout `variant`, sans token dédié
« texte sur couleur primaire ». Documenté comme besoin réel pour une
future phase Design Tokens plutôt que corrigé cette phase (voir
`Core-Refinement-Review.md` §6).

## 2026-07-31 — Phase 3.0

**Contexte** : valider Glass (HiDPI + multi-écran) sous
`sddm-greeter-qt6 --test-mode`, en réutilisant les commandes déjà
établies pour Nord/Template — sans réexporter
`QML_XHR_ALLOW_FILE_READ=1` dans le même appel (habitude prise pour
`qml6`/`ThemeHarness.qml`, oubliée pour `sddm-greeter-qt6` lui-même dans
cette session).

**Découverte** : `glass-dark` s'affichait sans aucune erreur QML visible
et semblait correct au premier coup d'œil — mais `glass-light`, testé
juste après avec la même omission, a montré une carte au fond sombre et
texte clair au lieu de blanc/texte sombre attendu, alors que le fond
d'écran chargé était bien le bon (clair). Vérification via
`tests/ThemeHarness.qml -- glass-light` : les tokens se chargent
correctement (`surfaceColor -> #ffffff` confirmé dans les logs). Un test
isolé imprimant directement `theme.colors.surfaceColor` après le même
chemin de chargement que `Main.qml` (`NebulaThemeLoader` +
`NebulaThemeProvider`) a montré la vraie cause :
`NebulaThemeLoader` échouait à lire `theme.conf`
(`FAILED to load ...: Error: Invalid state`) et
`NebulaThemeConfig` gardait ses valeurs par défaut du Core
(`surfaceColor: #2a2a2a`, pas celles de Glass) — `QML_XHR_ALLOW_FILE_READ`
n'était simplement pas défini pour cet appel précis de
`sddm-greeter-qt6`. `glass-dark` avait paru correct par pure coïncidence
de teinte (defaults du Core et palette de `glass-dark` sont tous deux
des gris sombres), masquant le même échec de chargement dans les deux
cas.

**Découverte n°2** : en creusant si ce même oubli pouvait se produire
sous le vrai service `sddm.service` (pas seulement dans un terminal de
développement où on peut oublier d'exporter une variable) — confirmé
qu'aucun mécanisme actuel n'y remédie : ni `/etc/sddm.conf`, ni
`/usr/lib/sddm/sddm.conf.d/default.conf`, ni l'unité systemd
`sddm.service` ne définissent `QML_XHR_ALLOW_FILE_READ`. SDDM fournit
pourtant une clé faite pour ça, `GreeterEnvironment=` (visible en
commentaire dans `default.conf`) — mais une première vérification par
`strings -a /usr/bin/sddm` (ASCII) ne trouvait la chaîne pour aucune clé
de configuration connue, y compris des clés dont le fonctionnement réel
est pourtant certain (`ThemeDir`, `SessionDir`) — fausse alerte : les
littéraux `QString` de Qt sont stockés en UTF-16 dans le binaire ;
`strings -e l -a` (UTF-16LE) les révèle correctement, confirmant que
`GreeterEnvironment` est une clé réellement implémentée dans ce binaire
SDDM 0.21.0-7, pas un reliquat de template inutilisé.

**Impact** : révèle une lacune de l'architecture de déploiement
(Phase 2.2), pas un défaut du thème en cours de validation — voir
DT-0023. `scripts/install-nebula.sh` écrit désormais
`/etc/sddm.conf.d/nebula.conf` avec
`GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1` ;
`scripts/uninstall-nebula.sh --core`/`--all` le retire ;
`scripts/check-installation.sh` vérifie sa présence. Sans ce correctif,
*tout* thème Nebula installé système-wide (Nord, Template, Glass)
aurait affiché les couleurs par défaut du Core au lieu des siennes en
usage réel, silencieusement. Voir `Compatibility-Matrix.md` §9 pour le
détail complet et la limite de vérification assumée (pas de redémarrage
du vrai `sddm.service` testé, pour ne pas risquer de couper la session
graphique active de la machine de développement).

## 2026-07-31 — Phase 2.2

**Contexte** : trouver comment un thème installé séparément du dépôt
(`/usr/share/sddm/themes/<nom>/`) peut charger le Core sans copie locale
(Constat #1 de `Nord-Validation-Report.md`) — Solution B envisagée
(module QML `Nebula`), crainte principale : le service SDDM réel,
lancé par systemd, n'a aucune raison d'avoir `QML2_IMPORT_PATH` défini
dans son environnement.

**Découverte** : `qmake6 -query QT_INSTALL_QML` renvoie un chemin
(`/usr/lib/qt6/qml` sur cette distribution) qui est recherché par
**défaut** par tout moteur QML — aucune variable d'environnement
requise. Confirmé réellement en comparant trois configurations :
`import Nebula` sans aucune variable QML dans l'environnement → échec
(`module "Nebula" is not installed`, SDDM bascule sur son thème de
secours) ; avec `QML2_IMPORT_PATH` pointant vers un chemin arbitraire →
succès ; module installé directement dans le chemin retourné par
`qmake6 -query QT_INSTALL_QML`, **sans aucune variable** (`env | grep
-i QML` vide, confirmé) → succès, sur les 3 écrans réels de la machine.

**Impact** : décide la Solution B (`Deployment-Decision.md`, DT-0022) —
installer directement dans ce chemin élimine le risque identifié au
départ. `scripts/install-nebula.sh` résout ce chemin dynamiquement à
chaque exécution plutôt que de le coder en dur, pour rester correct si
une distribution différente le place ailleurs (non vérifié — une seule
distribution testée réellement à ce jour).

---

**Contexte** : aplatir tous les fichiers `core/**/*.qml` dans un seul
dossier de module QML (`Nebula/`) pour le prototype de la Solution B.

**Découverte** : les imports internes relatifs (`import "../theme"`,
`import "../services"`, etc.) doivent être retirés, pas seulement rendus
inoffensifs — une fois aplatis dans un seul dossier, les types d'un même
module QML se résolvent automatiquement entre eux sans import explicite
(confirmé réellement) ; laisser `import "../theme"` provoquerait une
erreur de dossier introuvable puisque `../theme` n'existe plus dans la
structure aplatie.

**Impact** : `scripts/install-nebula.sh` retire systématiquement ces
lignes (`sed`) à la copie de chaque fichier vers le module installé.

---

**Contexte** : un second module QML pour les adapters
(`platform/sddm/`), nommé `Nebula.Platform.Sddm` (espace de noms à
points) plutôt que `Nebula` directement, pour rester distinct du Core.

**Découverte** : un module à espace de noms à points fonctionne sans
qu'aucun dossier intermédiaire (`Nebula/`, `Nebula/Platform/`) n'ait
besoin de son propre `qmldir` — seul le dossier final
(`Nebula/Platform/Sddm/`) en a besoin. Confirmé réellement avec un
module de test minimal avant de l'utiliser dans le vrai script
d'installation.

---

**Contexte** : `scripts/install-nebula.sh` lit le commit Git du dépôt
(`git rev-parse HEAD`) pour écrire un marqueur de version, lancé via
`sudo`/`su` (dépôt appartenant à l'utilisateur normal, pas à root).

**Découverte** : `git rev-parse HEAD` échoue silencieusement (capturé
par le script, pas une erreur visible) quand il tourne en `root` sur un
dépôt appartenant à un autre utilisateur — protection Git
`safe.directory` (post CVE-2022-24765). Le marqueur de version affiche
alors `installed_from=unknown` plutôt que le commit réel.

**Impact** : comportement dégradé gracieusement (pas de crash, juste une
information manquante), documenté comme cas normal dans
`Installation.md` plutôt que corrigé — corriger nécessiterait soit de
changer le propriétaire du dépôt, soit d'ajouter une exception
`safe.directory`, deux actions hors du périmètre d'un script
d'installation.

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
