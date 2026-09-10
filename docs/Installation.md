# Installation — Nebula

> Comment installer, mettre à jour et désinstaller Nebula. Pour
> l'architecture de distribution retenue (pourquoi ces scripts existent
> sous cette forme), voir [`Packaging.md`](Packaging.md) et
> [`Deployment-Decision.md`](Deployment-Decision.md). Pour développer un
> thème sans installation système, voir
> [`Development-Environment.md`](Development-Environment.md) et
> [`Creating-A-Theme.md`](Creating-A-Theme.md) — ce document ne couvre
> que l'installation système réelle.

---

## 1. Installation depuis le dépôt (développement)

Aucune installation nécessaire — tester directement depuis un clone du
dépôt :

```bash
QML_XHR_ALLOW_FILE_READ=1 sddm-greeter-qt6 --test-mode --theme themes/nord
```

⚠️ **Sans `QML_XHR_ALLOW_FILE_READ=1`, le thème se charge quand même,
mais avec les couleurs neutres du Core, pas celles du thème — et aucun
message d'erreur visible nulle part** (ni console, ni UI) :
`NebulaThemeLoader` lit `theme.conf` via `XMLHttpRequest`, que Qt6
bloque par défaut pour les fichiers locaux (voir §"Pourquoi
`install-nebula.sh` touche aussi `/etc/sddm.conf.d/`" en §2, même
cause — seul le mécanisme diffère : `GreeterEnvironment=` à
l'installation système, la variable d'environnement directe ici en
mode développement). Si les couleurs semblent grises/neutres au lieu de
celles attendues, c'est la première chose à vérifier — ce n'est pas
Nebula qui ne fonctionne pas.

Voir [`Development-Environment.md`](Development-Environment.md) pour le
détail complet (autres variables d'environnement utiles, lecture des
logs).

## 2. Installation système

Nécessite les droits root (écrit dans le chemin QML de Qt et
`/usr/share/sddm/themes/`) :

```bash
sudo scripts/install-nebula.sh nord
```

Ceci installe :

- le Core Nebula comme module QML (`import Nebula`), au chemin retourné
  par `qmake6 -query QT_INSTALL_QML` (généralement
  `/usr/lib/qt6/qml/Nebula/`) ;
- les adapters `platform/sddm/` comme sous-module
  (`import Nebula.Platform.Sddm`) ;
- le thème demandé (`nord` dans l'exemple) dans
  `/usr/share/sddm/themes/nord/`, avec ses imports réécrits pour
  consommer les modules installés plutôt que des chemins relatifs vers
  le dépôt.

⚠️ **Rien ne change visuellement sur la machine à ce stade.**
`install-nebula.sh` installe le thème mais ne modifie jamais la
configuration active de SDDM — activer le thème installé est une étape
manuelle distincte, volontairement laissée hors de ce script (changer
l'écran de connexion actif est une action à part, jamais silencieuse).
Éditez la configuration SDDM de votre distribution (ex.
`/etc/sddm.conf.d/*.conf`, section `[Theme]`, `Current=nord`) pour
l'utiliser réellement.

Le script est idempotent — le relancer (même thème ou un autre) ne
casse rien d'existant, il régénère simplement le module Core et le
thème demandé.

Pour installer un second thème sans toucher au premier :

```bash
sudo scripts/install-nebula.sh template
```

### Pourquoi `install-nebula.sh` touche aussi `/etc/sddm.conf.d/`

`install-nebula.sh` écrit également `/etc/sddm.conf.d/nebula.conf` :

```ini
[General]
GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1
```

`NebulaThemeLoader` lit chaque `theme.conf` lui-même via
`XMLHttpRequest`, délibérément plutôt que via la propriété de contexte
`config.<clé>` que SDDM expose déjà — pour garder le Core totalement
découplé de SDDM (voir [`Nebula-Principles.md`](Nebula-Principles.md)
§2 et [`ThemeLoader.md`](ThemeLoader.md) §3). Qt6 bloque par défaut la
lecture de fichiers locaux via XHR ; sans cette variable, **chaque**
thème installé échoue silencieusement à charger son `theme.conf` et
`NebulaThemeConfig` retombe sur ses valeurs par défaut codées en dur —
sans crash, sans erreur visible, juste les mauvaises couleurs
(découvert pendant la Phase 3.0, voir DT-0023 dans
`Decisions-Techniques.md`). `GreeterEnvironment=` est le mécanisme
propre que SDDM fournit lui-même pour ça — confirmé réellement présent
dans le binaire `sddm` installé sur cette machine (voir
`Compatibility-Matrix.md`). Ce fichier est supprimé par
`uninstall-nebula.sh --core`/`--all` (voir §4).

## 3. Vérifier une installation

```bash
scripts/check-installation.sh nord
```

Ne modifie jamais le système — vérifie uniquement : présence du module
Core, présence du sous-module `Nebula.Platform.Sddm`, chargement réel
via `qml6` (`import Nebula` fonctionne vraiment, pas seulement présence
de fichiers), présence de `GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1`
(voir ci-dessus et DT-0023), thèmes installés et leur intégrité, version
installée (commit Git au moment de l'installation, quand disponible —
voir §5).

## 4. Désinstallation

```bash
sudo scripts/uninstall-nebula.sh nord     # un seul thème
sudo scripts/uninstall-nebula.sh --core   # uniquement le module Core
sudo scripts/uninstall-nebula.sh --all    # tout ce que Nebula a installé
```

Ne supprime jamais un dossier sous `/usr/share/sddm/themes/` sans le
marqueur `.nebula-managed` qu'`install-nebula.sh` y écrit — un thème
portant le même nom mais installé autrement n'est jamais touché.

## 5. Mise à jour

Récupérer la nouvelle version du dépôt (`git pull`), puis relancer
l'installation :

```bash
sudo scripts/install-nebula.sh nord
```

Comme une seule copie du Core est partagée par tous les thèmes installés
(voir `Deployment-Decision.md`), une mise à jour du Core profite à tous
les thèmes déjà installés sans avoir à les réinstaller individuellement
— seul un thème réellement modifié a besoin d'être réinstallé lui-même.

## 6. Résolution des problèmes courants

- **`module "Nebula" is not installed`** (visible dans les logs
  `journalctl`, voir `Development-Environment.md` §3.1) : le module n'est
  pas installé au chemin QML par défaut de Qt, ou l'installation a
  échoué. Lancer `scripts/check-installation.sh` pour diagnostiquer.
- **`installed_from=unknown` dans `check-installation.sh`** : normal si
  `install-nebula.sh` a été lancé via `sudo`/`su` depuis un dépôt Git
  appartenant à un autre utilisateur — Git refuse de lire les métadonnées
  d'un dépôt qu'il ne possède pas (protection `safe.directory`). Sans
  conséquence sur l'installation elle-même, uniquement sur cette ligne
  d'information.
- **Écran de connexion normal réapparu après un thème cassé** : SDDM
  bascule automatiquement sur son thème de secours intégré si le thème
  configuré échoue à charger — comportement de SDDM lui-même, pas de
  Nebula (vérifié réellement, voir `Nord-Validation-Report.md` et
  `Development-Journal.md`).
- **Le thème se charge mais garde les couleurs par défaut du Core
  (grises/sombres) au lieu de celles du thème** : `theme.conf` n'a pas
  pu être lu — `GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1` absent de
  `/etc/sddm.conf.d/` (installation faite avec une version d'
  `install-nebula.sh` antérieure à Phase 3.0/DT-0023) ou écrasé par un
  autre fichier `sddm.conf.d/*.conf` traité après `nebula.conf` dans
  l'ordre alphabétique. Vérifier avec `scripts/check-installation.sh`.
