# Compatibility Matrix — Nebula

> Différences réellement observées entre `qml6` standalone,
> `sddm-greeter --test-mode`, et SDDM réel (service système). Document
> factuel — chaque entrée vient d'un test réel, jamais d'une supposition.
> Complète [`SDDM-Compatibility.md`](SDDM-Compatibility.md) (matrice de
> compatibilité des modules Qt) et
> [`Development-Environment.md`](Development-Environment.md) (comment
> lancer chaque environnement). Introduit en Phase 2.0.5 (voir
> `Roadmap.md`).
>
> **Avertissement de portée** : « SDDM réel » désigne ici le service
> système (utilisateur `sddm`, vrai écran de connexion). Ce projet ne l'a
> **jamais testé directement** — toutes les vérifications « sous SDDM »
> de ce document et du reste de la documentation utilisent
> `sddm-greeter --test-mode`, qui charge le même binaire greeter réel
> mais sous l'utilisateur courant, sans authentification de bout en bout
> (voir [`SDDM-Compatibility.md`](SDDM-Compatibility.md), ligne
> « Permissions utilisateur sddm »). Les lignes ci-dessous distinguent
> les deux quand la différence est connue ou probable ; le reste est
> noté « non testé sous SDDM réel ».

---

## 1. Sortie `console.log`/`console.warn`

- **Symptôme** : aucune sortie visible dans le terminal en lançant
  `qml6 fichier.qml` ou `sddm-greeter --test-mode` depuis un script/une
  redirection.
- **Cause** : Qt route les logs vers le journal systemd dès qu'il détecte
  ne pas être attaché à un terminal interactif — vrai pour `qml6` et pour
  `sddm-greeter`/`sddm-greeter-qt6` (confirmé Phase 1.0 et Phase 1.2).
- **Solution** : deux options équivalentes selon le contexte —
  `journalctl --no-pager -n 100 | grep -iE "sddm-greeter|qml"` (fonctionne
  toujours, y compris pour inspecter un processus déjà lancé autrement),
  ou passer `QT_LOGGING_TO_CONSOLE=1` (déprécié mais fonctionnel ; noms
  recommandés par l'avertissement : `QT_ASSUME_STDERR_HAS_CONSOLE=1` et/ou
  `QT_FORCE_STDERR_LOGGING=1`) à l'invocation elle-même — plus direct,
  testé avec succès sur `qml6` **et** sur `sddm-greeter-qt6
  --test-mode` (Phase 2.0.5).
- **Impact** : tous les harnais de ce projet (`tests/*.qml`,
  `scripts/*.sh`) supposent l'une de ces deux méthodes — jamais une
  redirection stdout/stderr nue.

## 2. Propriétés de contexte SDDM (`sddm`, `config`, `userModel`, `sessionModel`, `keyboard`)

- **Symptôme** : `ReferenceError` ou valeur `undefined` en lisant ces
  identifiants depuis un `qml6` standalone.
- **Cause** : ce sont des propriétés de contexte injectées par
  `sddm-greeter` (test-mode ou réel) au chargement du QML racine d'un
  thème — elles n'existent tout simplement pas en dehors de ce
  processus (confirmé Phase 1.0, `Prototype-Results.md` §3.2).
- **Solution** : toujours vérifier `typeof x !== "undefined"` avant
  usage (voir `prototype/Main.qml`) — ou, pour `theme.conf`
  spécifiquement, ne pas dépendre de `config` du tout et lire le fichier
  directement (voir `NebulaThemeLoader`,
  [`ThemeLoader.md`](ThemeLoader.md) §3 — ce choix rend le Loader
  indépendant de cette différence).
- **Impact** : tout composant Core qui lirait une de ces propriétés
  directement casserait en standalone `qml6` — c'est exactement
  l'interdiction déjà posée par
  [`Nebula-Principles.md`](Nebula-Principles.md) §2/§6.
- **Non testé sous SDDM réel** : seul `sddm-greeter --test-mode` a été
  utilisé ; les valeurs réelles de `userModel`/`sessionModel` sous le
  service système (utilisateur `sddm`, vrais comptes) restent à
  confirmer (voir `SDDM-Compatibility.md`, ligne « Permissions
  utilisateur sddm »).

## 3. `config` est un `QObject` natif sous SDDM réel/test-mode, pas un objet JS

- **Symptôme** : `TypeError: ... hasOwnProperty is not a function` en
  traitant `config` comme un objet JavaScript ordinaire.
- **Cause** : sous `sddm-greeter`, `config` est une instance C++
  (`SDDM::ThemeConfig`) exposée à QML — les méthodes `Object.prototype`
  comme `hasOwnProperty` n'existent pas dessus, contrairement à un objet
  JS `{}` utilisé dans un test standalone (confirmé Phase 2.0, en testant
  `themes/template/Main.qml` sous `sddm-greeter-qt6 --test-mode`).
- **Solution** : utiliser l'accès par crochet suivi d'un test
  `!== undefined` (`obj[key] !== undefined`), qui fonctionne aussi bien
  sur un `QObject` natif que sur un objet JS.
- **Impact** : tout code testé uniquement en standalone `qml6` avec des
  objets JS de substitution peut cacher ce genre de bug — voir la
  recommandation en fin de ce document.

## 4. `XMLHttpRequest` sur fichier local désactivé par défaut

- **Symptôme** : `xhr.send()` sur une URL `file://` renvoie silencieusement
  `status: 0` et `responseText: ""`, sans exception.
- **Cause** : ce build Qt6 désactive les lectures de fichiers locales via
  `XMLHttpRequest` par défaut (message d'avertissement Qt visible
  uniquement avec `QT_LOGGING_TO_CONSOLE=1`, voir §1).
- **Solution** : `QML_XHR_ALLOW_FILE_READ=1`. Identique sous `qml6` et
  sous `sddm-greeter-qt6 --test-mode` (testé sous les deux, Phase 2.0.5).
- **Impact** : `NebulaThemeLoader` (voir `ThemeLoader.md`) et
  `tests/ThemeHarness.qml` en dépendent pour lire `theme.conf`.

## 5. Fichier local manquant, vide, ou lectures désactivées : indistinguables

- **Symptôme** : `status: 0` et `responseText.length: 0` dans les trois
  cas suivants, sans aucun moyen de les différencier depuis QML —
  fichier introuvable, fichier existant mais réellement vide (0 octet),
  et `QML_XHR_ALLOW_FILE_READ` non défini.
- **Cause** : `XMLHttpRequest` sur `file://` ne fournit aucun statut HTTP
  réel ni `statusText` pour distinguer ces cas (vérifié réellement en
  comparant les trois scénarios, Phase 2.0.5).
- **Solution** : aucune trouvée sans dépendance supplémentaire (ex. un
  vérificateur d'existence de fichier hors QML pur) — jugé disproportionné
  pour le périmètre actuel. `NebulaThemeLoader` traite les trois cas
  comme un échec de chargement (`loadError` renseigné, tokens laissés à
  leur valeur par défaut du Core) plutôt que de risquer qu'un chemin
  mal orthographié réussisse silencieusement.
- **Impact** : un thème avec un `theme.conf` intentionnellement vide
  verra `NebulaThemeLoader` le signaler comme une erreur de chargement,
  pas comme un thème valide à zéro token personnalisé — limitation
  assumée, voir [`Nebula-Principles.md`](Nebula-Principles.md) §9.

## 6. Multi-écran

- **Symptôme** : plusieurs fenêtres s'ouvrent au lancement.
- **Cause** : `sddm-greeter --test-mode` (comme SDDM réel, voir
  `Prototype-Results.md` §3.3) instancie une `QQuickView` par écran
  physique connecté, chacune chargeant `Main.qml` indépendamment.
  `qml6` standalone n'ouvre toujours qu'une seule fenêtre, quel que soit
  le nombre d'écrans.
- **Cause profonde** : différence de comportement du binaire hôte
  (`sddm-greeter` vs `qml`), pas du QML lui-même.
- **Solution** : `Main.qml` d'un thème ne doit jamais supposer une seule
  vue ni une résolution fixe (déjà le cas — voir `NebulaLoginLayout`,
  dimensionnement responsive).
- **Impact** : tester un thème avec `sddm-greeter --test-mode` sur une
  machine multi-écran fait apparaître une fenêtre par écran — normal, pas
  un bug (vérifié à nouveau en Phase 2.0/2.0.5 avec 3 écrans réels).

## 7. Thème installé séparément du dépôt : le Core ne suit pas (résolu en Phase 2.2)

- **Symptôme** : `"../../core/theme": no such directory`, SDDM bascule
  sur son thème de secours intégré.
- **Cause** : `Main.qml` d'un thème importe le Core par chemin relatif
  (`../../core/...`), valide uniquement quand le thème reste à
  l'intérieur du dépôt Git — pas quand il est copié seul vers
  `/usr/share/sddm/themes/<nom>/`, son vrai emplacement d'installation
  (testé réellement avec Nord, Phase 2.1).
- **Solution** : `core/`/`platform/sddm/` s'installent comme module QML
  (`import Nebula`/`import Nebula.Platform.Sddm`) via
  `scripts/install-nebula.sh` — voir
  [`Deployment-Decision.md`](Deployment-Decision.md) et DT-0022. Résolu
  en Phase 2.2, testé réellement (installation système complète,
  chargement confirmé sans aucune variable d'environnement).
- **Impact** : `sddm-greeter --test-mode --theme themes/<nom>` **depuis
  le dépôt** reste la méthode de test pendant le développement (imports
  relatifs inchangés dans le dépôt, voir `Deployment-Decision.md` §3) ;
  `scripts/install-nebula.sh` est la méthode pour tester/déployer un
  thème réellement installé, hors dépôt.

## 8. `QML2_IMPORT_PATH` vs chemin QML par défaut de Qt

- **Symptôme** : `import Nebula` échoue (`module "Nebula" is not
  installed`) même quand le module existe sur disque, à moins de définir
  `QML2_IMPORT_PATH` pointant dessus.
- **Cause** : un chemin de module QML n'est recherché automatiquement
  que s'il fait partie des chemins d'import par défaut de Qt
  (`qmake6 -query QT_INSTALL_QML`, ex. `/usr/lib/qt6/qml/` sur cette
  distribution) — sinon `QML2_IMPORT_PATH` doit être défini
  explicitement dans l'environnement du processus qui charge le QML, ce
  que le vrai service systemd de SDDM ne fait pas par défaut.
- **Solution** : installer le module directement dans le chemin QML par
  défaut de Qt (ce que fait `scripts/install-nebula.sh`) élimine le
  besoin de `QML2_IMPORT_PATH` entièrement — vérifié réellement dans les
  trois configurations (aucune variable : échec ; `QML2_IMPORT_PATH`
  défini : succès ; chemin par défaut sans variable : succès), voir
  `Development-Journal.md`, Phase 2.2.
- **Impact** : a directement determiné le choix de la Solution B dans
  `Deployment-Decision.md` — sans ce chemin par défaut, la crainte
  initiale (variable d'environnement absente de l'environnement
  systemd du service SDDM réel) aurait rendu cette architecture
  beaucoup plus fragile à déployer.

## 9. `XMLHttpRequest` local sous le vrai service SDDM : `GreeterEnvironment=` requis (résolu en Phase 3.0)

- **Versions concernées** : SDDM 0.21.0-7, Qt6 6.11.1 (`qt6-base`/
  `qt6-declarative`), système Arch/EndeavourOS — configuration réelle de
  la machine de développement au moment du test. Non vérifié sur d'autres
  versions ; le comportement décrit en §4 (XHR local désactivé par
  défaut) n'est a priori pas spécifique à cette version de Qt6, mais
  seule celle-ci a été testée.
- **Symptôme** : un thème installé via `scripts/install-nebula.sh`
  charge et s'affiche sans erreur QML visible, mais garde les couleurs
  par défaut du Core (`#2a2a2a`/`#1e1e1e`/`#f0f0f0`, celles codées en dur
  dans `NebulaThemeConfig`) au lieu de celles de son `theme.conf` — quel
  que soit le thème (Nord, Template, Glass), et quelle que soit la
  variante (`glass-dark`/`glass-light`).
- **Cause** : §4 documentait déjà que `QML_XHR_ALLOW_FILE_READ=1` est
  nécessaire sous `qml6` et `sddm-greeter --test-mode`, mais aucune
  vérification n'avait été faite sur ce que reçoit réellement le
  processus greeter lancé par le vrai service `sddm.service` (via
  systemd) — celui-ci ne définit cette variable nulle part par défaut
  (confirmé : ni dans `/etc/sddm.conf`, ni dans
  `/usr/lib/sddm/sddm.conf.d/default.conf`, ni dans l'unité systemd
  `sddm.service`). Découvert en testant Glass sous
  `sddm-greeter-qt6 --test-mode` sans avoir exporté la variable dans le
  shell — l'échec silencieux de `NebulaThemeLoader` (voir §5, DT-0018)
  masquait le vrai thème derrière les valeurs par défaut du Core,
  visuellement plausible pour `glass-dark` par coïncidence (les deux
  sont des gris sombres) mais immédiatement visible pour `glass-light`
  (fond de carte resté sombre au lieu de blanc — voir
  `Glass-Theme-Report.md`).
- **Solution** : `GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1` dans
  `/etc/sddm.conf.d/`, sous `[General]` — mécanisme officiel de SDDM
  pour définir des variables d'environnement pour le processus greeter
  (confirmé réellement présent dans le binaire `/usr/bin/sddm` installé,
  via recherche de chaîne UTF-16LE — les chaînes Qt `QString` ne sont pas
  visibles avec un `strings` ASCII classique, piège rencontré pendant
  cette investigation). `scripts/install-nebula.sh` écrit désormais ce
  fichier automatiquement ; `scripts/uninstall-nebula.sh --core`/`--all`
  le retire. Voir DT-0023 dans `Decisions-Techniques.md` et
  `Installation.md`.
- **Limite de la vérification** : confirmer que `GreeterEnvironment=`
  atteint réellement le sous-processus greeter demanderait de redémarrer
  le vrai service `sddm.service` — non fait dans cette session (risque
  de couper la session graphique active, hors du périmètre accepté pour
  cette découverte). La présence réelle de la chaîne dans le binaire
  installé et la description officielle de la clé (« Comma-separated
  list of environment variables to be set ») donnent une confiance forte
  mais pas une vérification de bout en bout.
- **Impact** : sans ce correctif, *tout* thème Nebula installé
  système-wide affiche les mauvaises couleurs en usage réel, silencieusement
  — un problème d'architecture de déploiement (Phase 2.2), pas un défaut
  du thème testé au moment de sa découverte (Glass, Phase 3.0).

## 10. Clavier virtuel (`InputMethod=qtvirtualkeyboard`) démesuré sur écran multi-moniteur à tailles physiques mixtes

> **Mise à jour 2026-08-03** : diagnostic complet dans
> `docs/Investigations/VK-001-VirtualKeyboard.md` (investigation VK-001).
> La conclusion "pas un bug Nebula" ci-dessous, écrite le 2026-07-31 sur
> la base d'un simple `grep` sans preuve expérimentale complète, est
> **fausse sur un point clé** — conservée ici pour l'historique, mais
> voir VK-001 pour l'analyse correcte et sourcée (symboles binaires
> réels de `libQt6VirtualKeyboard.so`).

- **Contexte de vérification** : contrairement à toutes les entrées
  précédentes de ce document, celle-ci a été observée sous le **vrai
  service `sddm.service`** (pas `--test-mode`) — premier cas où l'écart
  de portée signalé en tête de document (aucune vérification directe
  sous SDDM réel) est levé, pour ce point précis.
- **Symptôme** : au focus du champ mot de passe, le clavier virtuel Qt
  (`qtvirtualkeyboard`) s'affiche sur l'écran "actif" (celui qui a le
  focus/priorité KWin le plus haut, ici un moniteur 4K) à une échelle
  démesurée — une dizaine de touches remplissent presque toute la
  largeur de l'écran — pendant que la fenêtre de connexion du thème
  elle-même reste correctement dimensionnée sur un autre écran (ici le
  panneau interne du laptop). Constaté avec `glass-dark` actif, mais le
  déclencheur est la présence d'un champ mot de passe recevant le focus,
  indépendant du thème.
- **Cause (diagnostic provisoire du 2026-07-31, partiellement erroné —
  voir mise à jour ci-dessus)** : le greeter SDDM tourne sous un
  **serveur X11 classique** (`journalctl -u sddm` :
  `Running: /usr/bin/X -nolisten tcp ...`), même sur une session
  utilisateur Wayland/KWin par ailleurs — X11 n'a pas de notion native de
  scale-factor par écran. Ce constat DPI reste vrai (confirmé et chiffré
  par VK-001, Partie 2 : 94 à 210 dpi réels selon l'écran, contre un
  `devicePixelRatio` figé à 1 partout côté greeter) — mais VK-001 Partie
  3 prouve que forcer `QT_SCALE_FACTOR`/`QT_AUTO_SCREEN_SCALE_FACTOR` n'a
  **aucun effet sur le clavier**, alors que ça change bien le reste de
  l'UI. Le DPI mal détecté est un facteur réel mais secondaire, pas la
  cause du symptôme précis observé.
- **Cause réelle, confirmée par VK-001** : Nebula ne fournit nulle part
  de composant `InputPanel` ("Application Integration", le patron que
  `breeze` utilise via son `VirtualKeyboardLoader`). En l'absence d'un
  tel composant enregistré, Qt Virtual Keyboard retombe sur
  `QtVirtualKeyboard::DesktopInputPanel` — une fenêtre de secours
  entièrement séparée de l'arbre QML de l'application, avec ses propres
  dimensions et sa propre logique de repositionnement. C'est confirmé au
  niveau des symboles binaires réels de `libQt6VirtualKeyboard.so`, pas
  une hypothèse. Détail complet :
  `docs/Investigations/VK-001-VirtualKeyboard.md`.
- **"Confirmation que ce n'est pas un bug Nebula" (2026-07-31, erroné)** :
  le raisonnement d'origine — aucun fichier de `core/`, `themes/`, ou
  `platform/` ne référence `VirtualKeyboard`/`InputPanel`/`InputMethod`,
  donc "Nebula n'a aucune prise dessus" — confond correctement
  l'observation (aucune référence) avec la conclusion (donc pas
  responsable). C'est l'absence elle-même qui cause le problème :
  Nebula est la seule pièce du système qui pourrait enregistrer un
  `AppInputPanel` comme `breeze` le fait, et ne le fait nulle part.
- **Solution** : un composant Core dédié (`InputPanel` réel, `width` lié
  à l'écran, même patron que `breeze`) résoudrait le problème avec un
  haut degré de confiance — voir VK-001 pour le détail. Non implémenté à
  ce jour (décision produit séparée, voir `Roadmap.md`). Le contournement
  système (désactiver `InputMethod=qtvirtualkeyboard` via
  `/etc/sddm.conf.d/`) reste disponible en attendant — voir
  [[nebula-virtual-keyboard-scaling]] côté mémoire.
- **Impact** : concerne toute installation Nebula sur une machine qui a
  `InputMethod=qtvirtualkeyboard` actif (par défaut sur EndeavourOS via
  `10-endeavouros.conf`) et utilisant un vrai champ de saisie — donc
  tous les thèmes sauf `nord` actuellement (qui n'a pas de champ password
  du tout, voir VK-001 Partie 1), indépendamment du nombre d'écrans ou de
  leur taille physique (VK-001 Partie 3 : le symptôme ne dépend pas du
  DPI réel, seulement de l'absence d'`InputPanel`).

---

## Recommandation

Les différences §2, §3 et §4 ci-dessus ont toutes été trouvées en testant
sous `sddm-greeter --test-mode` un mécanisme qui fonctionnait déjà en
`qml6` standalone avec des substituts (objets JS littéraux, adaptateurs
mock). **Toujours valider un mécanisme touchant une propriété de contexte
réelle ou une opération I/O sous `sddm-greeter --test-mode` avant de le
considérer terminé** — un test standalone seul peut donner une fausse
confiance (voir `Development-Journal.md`, Phase 2.0 et 2.0.5, pour les
bugs concrets trouvés de cette façon).
