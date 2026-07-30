# Prototype Results — Nebula (Phase 1.0)

> Résultats du prototype technique (`prototype/`) exécuté réellement sur
> une machine EndeavourOS avec SDDM 0.21 installé. Objectif : lever les
> inconnues critiques de [`Architecture.md`](Architecture.md) §4 par un
> test réel plutôt que par de la documentation supplémentaire — voir
> `Architecture-Review.md` §7, qui annonçait que seul un test réel pouvait
> les clore.

---

## 1. Environnement testé

| Élément            | Valeur constatée |
| --------------------- | ------------------- |
| Distribution           | EndeavourOS (Arch-based, rolling) |
| SDDM                   | 0.21.0-7 |
| Plasma                 | 6.7.3 |
| Session active          | Wayland (`XDG_SESSION_TYPE=wayland`) |
| Qt (qmake6)             | 6.11.1 |
| Qt (qmake, Qt5 aussi présent) | 5.15.19 (coexistence Qt5/Qt6, sans impact sur ce prototype) |
| Paquet `qt6-declarative` | 6.11.1-3 — fournit `QtQuick`, `QtQuick.Controls` (styles Basic/Fusion/Material/Universal/FluentWinUI3), `QtQuick.Shapes` |
| Paquets GPU/effets      | `qt6-shadertools`, `qt6-quick3d` installés (disponibilité du *paquet*, pas testée à l'exécution — voir §6, hors périmètre) |
| Écrans connectés        | 3 : `eDP-1` (panneau interne, 2560×1440 physique, échelle 1.4), `DP-7` (3840×2160 physique, échelle 1.4), `DP-9` (1920×1200 physique, échelle 1) |
| Thèmes SDDM déjà installés | `breeze`, `eos-breeze`, `Ant-Dark-Plasma-6`, `MyBreeze-SDDM-6`, etc. — utilisés comme référence de l'API réelle (voir §3) |

## 2. Commandes utilisées

```bash
# Lint (aucun avertissement)
qmllint prototype/Main.qml

# Exécution standalone (hors contexte SDDM)
qml6 prototype/Main.qml

# Exécution réelle via SDDM, mode test
sddm-greeter-qt6 --test-mode --theme "$(pwd)/prototype"

# Les logs de sddm-greeter ne sortent PAS sur stdout/stderr redirigés —
# ils passent par le journal systemd (voir §5, limitation découverte) :
journalctl --no-pager -n 50 | grep -iE "nebula|Main\.qml"
```

Captures d'écran prises avec `spectacle -b -n -m -o <fichier> -d 500`
pendant l'exécution, pour vérifier visuellement le rendu.

## 3. Résultats

### 3.1 Fonctionnalités minimales demandées

| Fonctionnalité                     | Résultat |
| -------------------------------------- | ---------- |
| Fenêtre QML valide                      | ✅ Rendu confirmé par capture d'écran, standalone et sous SDDM |
| Texte "Nebula Prototype"                | ✅ |
| Horloge simple                          | ✅ `Timer` + réaffectation de `text` (voir §4, pas d'`Animation`/`Behavior`) |
| Résolution écran détectée                | ✅ Via `Screen.width`/`Screen.height` (attaché à l'`Item` racine) |
| Nom d'utilisateur courant si accessible  | ⚠️ Voir §3.4 — `userModel.lastUser` existe mais reste vide en mode test |

### 3.2 API SDDM réelle (inconnue critique levée)

Confirmé en lisant `/usr/share/sddm/themes/breeze/Main.qml` puis en
vérifiant directement dans le prototype (`typeof x` loggé pour chaque
propriété de contexte) : sous `sddm-greeter-qt6 --test-mode`, les
propriétés de contexte suivantes existent bien et sont du type `object` :

- `sddm` — actions système : `sddm.login(username, password, sessionIndex)`,
  `sddm.hibernate()`/`canHibernate`, `sddm.suspend()`/`canSuspend`,
  `sddm.reboot()`/`canReboot`, `sddm.powerOff()`/`canPowerOff`.
- `userModel` — modèle des utilisateurs ; `userModel.lastUser` (string) et
  `userModel.lastIndex` (int) confirmés utilisés directement (sans
  passer par un `Repeater`) dans le thème Breeze.
- `sessionModel` — modèle des sessions ; `sessionModel.lastIndex` observé
  utilisé directement dans `SessionButton.qml` de Breeze.
- `keyboard` — `keyboard.currentLayout` (int, lecture/écriture),
  `keyboard.layouts` (array d'objets avec `.longName`).
- `screenModel` — modèle des écrans, exposant un rôle `geometry`
  (x/y/width/height) par écran. **Contrairement aux quatre précédents,
  `screenModel` n'a pas de propriété `.count` accessible directement** —
  voir §3.3, c'est un `QAbstractItemModel` pur, à consommer via un
  `Repeater`/`ListView` (`model: screenModel`), pas comme un objet à
  propriétés.
- `config` — passthrough direct des clés de `theme.conf` (`[General]` →
  `config.cléIni`), confirmé par Breeze (`config.type`, `config.color`,
  `config.background`) et par nos propres logs
  ("Loading theme configuration from ... theme.conf").

Ceci confirme et précise DT-0003 et `Core-API.md` : les composants Core
(`NebulaUserList`, `NebulaSessionSelector`, `NebulaKeyboardSelector`,
`NebulaPowerButtons`) s'appuieront directement sur ces propriétés de
contexte réelles plutôt que sur une API imaginée.

### 3.3 Multi-écran (inconnue critique levée)

**Une fenêtre (`QQuickView`) par écran physique, chacune chargeant
`Main.qml` indépendamment** — pas une fenêtre unique partagée avec un
`Repeater` interne sur tous les écrans à la fois. Log réel :

```text
Adding view for "eDP-1" QRect(244,1543 1829x1029)
Loading file:///.../prototype/Main.qml...
Adding view for "DP-7" QRect(0,0 2743x1543)
Loading file:///.../prototype/Main.qml...
Adding view for "DP-9" QRect(2743,343 1920x1200)
Loading file:///.../prototype/Main.qml...
```

Sur l'écran `eDP-1`, notre prototype a affiché "Screens exposed by SDDM
(screenModel.count): 1" — confirmant que **chaque vue reçoit un
`screenModel` propre à son propre écran** (count = 1 dans cette vue), et
non un modèle global partagé listant les trois écrans dans chaque fenêtre.

Ceci répond directement à l'inconnue d'`Architecture.md` §4 ("une fenêtre
de login par écran ? partagée ?") : **une fenêtre par écran**, confirmé.

### 3.4 HiDPI (inconnue partiellement levée)

Les géométries de fenêtre logguées sont en coordonnées **logiques**
(post-scaling), pas physiques :

| Écran   | Résolution physique | Échelle | Résolution logique observée |
| --------- | ---------------------- | --------- | ------------------------------- |
| `eDP-1`   | 2560×1440               | 1.4       | 1829×1029 (2560/1.4, 1440/1.4)   |
| `DP-7`    | 3840×2160               | 1.4       | 2743×1543 (3840/1.4, 2160/1.4)   |
| `DP-9`    | 1920×1200               | 1         | 1920×1200                       |

`Screen.width`/`Screen.height` dans notre prototype ont bien remonté la
valeur logique (`1829x1029` sur `eDP-1`), cohérent avec le log. Le log
mentionne aussi explicitement `High-DPI autoscaling Enabled`.

**Ce qui reste "à vérifier"** (non testé ici, hors périmètre du
prototype) : le rendu visuel réel à ces échelles (netteté des icônes/
polices, artefacts éventuels) — seule la géométrie a été vérifiée, pas le
rendu pixel. Voir `SDDM-Compatibility.md`.

### 3.5 `sddm-greeter --test-mode` : limitations découvertes

- **Pas de backend d'authentification réel** : `Socket error:
  "QLocalSocket::connectToServer: Invalid name"` apparaît systématiquement
  en mode test. `sddm.login()` ne peut donc pas être testé de bout en bout
  en mode test — seul un vrai lancement du service SDDM le permettrait
  (voir §3.6, délibérément non tenté).
- **`userModel.lastUser` reste vide en mode test** sur cette machine : le
  champ "Current user" du prototype est resté à sa valeur de repli. Cause
  probable : le mode test ne peuple pas de vraie liste d'utilisateurs
  system (cohérent avec l'absence de backend d'authentification
  ci-dessus). Non bloquant pour le Core MVP : `NebulaUserList`/`NebulaAvatar`
  devront être testés via un vrai lancement SDDM (§3.6) ou avec un modèle
  simulé, pas uniquement en mode test.
- **Les logs ne sortent pas sur stdout/stderr redirigés** — `sddm-greeter`
  utilise le logging systemd (journald) dès qu'il détecte ne pas être
  attaché à un terminal interactif. Une redirection `> fichier.log 2>&1`
  classique donne un fichier vide alors que le processus fonctionne
  normalement. Il faut utiliser `journalctl` pour voir les messages —
  **`docs/Development-Environment.md` ne mentionnait pas ce point et a été
  corrigé** (voir §6).

### 3.6 Lancement normal (délibérément non testé)

Le brief demandait de tester "lancement normal ; mode test ; Plasma 6 ;
Wayland". **Le lancement normal (remplacer le greeter actif du service
SDDM système) n'a pas été tenté.** Remplacer temporairement la
configuration SDDM active de cette machine réelle pour tester un
prototype jetable est une action à fort rayon d'action (le service de
connexion de la machine) et difficile à annuler proprement en cas
d'erreur (risque de blocage de session graphique) — hors de proportion
avec la valeur d'un test pour un prototype qui sera de toute façon
supprimé. Le mode test (`sddm-greeter --test-mode`) donne déjà accès à
l'API réelle et au rendu réel (voir §3.2 et §3.3), ce qui couvre
l'essentiel du besoin de validation de cette phase. Si un test "lancement
normal" devient nécessaire plus tard (ex. pour valider `sddm.login()` de
bout en bout), il faudra le faire consciemment, avec une sauvegarde de
`/etc/sddm.conf.d/` et un moyen de revenir en arrière (VT alternative,
accès SSH).

Plasma 6 (6.7.3) et Wayland ont été confirmés présents et actifs tout au
long des tests ci-dessus — aucun test séparé n'était nécessaire, l'un et
l'autre étant la session dans laquelle tous les tests ont tourné.

## 4. Écart assumé : "pas d'animations"

Le brief liste "horloge simple" dans les fonctionnalités minimales
requises, et "ne pas créer d'animations" dans les exclusions. Le
prototype résout cette tension en implémentant l'horloge avec un simple
`Timer` qui réaffecte une propriété `text` (aucun `Animation`, `Behavior`,
`NumberAnimation` ou transition) — conforme à l'exclusion tout en
satisfaisant l'exigence fonctionnelle.

## 5. Bug trouvé et corrigé pendant le test

Première version : `screenCountText = screenModel.count.toString()`
levait `TypeError: Cannot call method 'toString' of undefined` (visible
uniquement via `journalctl`, pas sur stdout — voir §3.5), qui interrompait
le reste de `Component.onCompleted` — expliquant pourquoi le champ
utilisateur restait aussi bloqué sur sa valeur de repli lors du premier
test. Corrigé en liant `screenModel` à un `Repeater` invisible et en
lisant `screenRepeater.count` (voir `prototype/Main.qml`). Cette
correction elle-même est une donnée utile pour `Core-API.md` : la
propriété `count` de `NebulaThemeLoader`/composants qui consomment
`screenModel` doit être obtenue via un modèle, jamais via un accès direct.

## 6. Répercussions sur la documentation existante

Voir les fichiers modifiés dans le même lot que ce document :

- [`SDDM-Compatibility.md`](SDDM-Compatibility.md) — lignes QML, QtQuick,
  QtQuick.Controls, QtQuick.Shapes, Multi écran et HiDPI (géométrie)
  passées à "Vérifié", avec référence à ce document.
- [`Core-API.md`](Core-API.md) — `Inputs` de `NebulaUserList`,
  `NebulaSessionSelector`, `NebulaKeyboardSelector`, `NebulaPowerButtons`
  précisés avec les noms réels (`userModel`, `sessionModel`, `keyboard`,
  `sddm`).
- [`Development-Environment.md`](Development-Environment.md) — ajout de
  `journalctl` pour lire les logs du greeter, la redirection stdout seule
  étant trompeuse (§3.5).
- [`Theme-Development.md`](Theme-Development.md) — clarification sur
  `metadata.desktop` : absent de notre prototype, le chargement direct via
  `--theme <chemin>` a fonctionné sans lui (avec les noms de fichiers par
  défaut `Main.qml`/`theme.conf`), mais il reste nécessaire pour qu'un
  thème soit sélectionnable normalement par SDDM (`/usr/share/sddm/themes/`
  + `Current=` dans la configuration).

## 7. Statut de fin de Phase 1.0

- [x] Prototype créé et testé réellement (standalone + `--test-mode`)
- [x] API SDDM réelle vérifiée (inconnue critique levée)
- [x] Comportement multi-écran vérifié (inconnue critique levée)
- [x] Géométrie HiDPI vérifiée (rendu pixel réel non couvert, voir §3.4)
- [x] Limitations du mode test documentées
- [ ] Coût réel des effets GPU — toujours ouvert, explicitement hors
      périmètre de ce prototype (voir brief : "ne pas créer de shaders")
- [ ] Mécanisme de configuration définitif (DT-0003) — `config.*` en
      lecture confirmé fonctionnel ; le format d'écriture/export pour
      Nebula Designer reste ouvert

Le Core MVP (Phase 1) peut démarrer sur les composants qui ne dépendent
plus d'une inconnue non levée (voir `Core-MVP.md`).
