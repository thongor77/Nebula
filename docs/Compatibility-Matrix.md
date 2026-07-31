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

## 7. Thème installé séparément du dépôt : le Core ne suit pas

- **Symptôme** : `"../../core/theme": no such directory`, SDDM bascule
  sur son thème de secours intégré.
- **Cause** : `Main.qml` d'un thème importe le Core par chemin relatif
  (`../../core/...`), valide uniquement quand le thème reste à
  l'intérieur du dépôt Git — pas quand il est copié seul vers
  `/usr/share/sddm/themes/<nom>/`, son vrai emplacement d'installation
  (testé réellement avec Nord, Phase 2.1).
- **Solution** : aucune pour l'instant — nécessite une stratégie de
  distribution/packaging du Core (voir
  [`Nord-Validation-Report.md`](Nord-Validation-Report.md), Constat #1,
  pour les options envisagées).
- **Impact** : tout thème conforme au SDK échoue de la même façon une
  fois installé séparément — pas spécifique à Nord. `sddm-greeter
  --test-mode` **depuis le dépôt** (`--theme themes/<nom>`) reste le
  seul mode de test valide tant que ce n'est pas résolu.

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
