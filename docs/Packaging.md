# Packaging — Nebula

> Architecture de distribution retenue pour empaqueter Nebula (ex.
> PKGBUILD, `.deb`, `.rpm`). Détail de la comparaison et des tests
> réels : [`Deployment-Decision.md`](Deployment-Decision.md) et
> DT-0022 dans [`Decisions-Techniques.md`](Decisions-Techniques.md).
> Pour l'usage utilisateur final des scripts, voir
> [`Installation.md`](Installation.md).

---

## 1. Principe

Le Core Nebula (`core/`, `platform/sddm/`) s'installe **une seule fois**
par machine, comme un module QML nommé `Nebula` (+ sous-module
`Nebula.Platform.Sddm`), au chemin QML par défaut de Qt — pas un chemin
personnalisé nécessitant `QML2_IMPORT_PATH`. Chaque thème installé
(`/usr/share/sddm/themes/<nom>/`) consomme ce module via
`import Nebula` / `import Nebula.Platform.Sddm`, sans copie locale du
Core.

Conséquence pour un packager : **deux paquets possibles**, comme pour
n'importe quelle bibliothèque partagée système :

- `nebula-core` — installe le module QML (dépendance de tout thème
  Nebula).
- `nebula-theme-<nom>` — installe un thème, dépend de `nebula-core`.

## 2. Chemins d'installation

| Contenu | Chemin | Origine |
| --- | --- | --- |
| Module `Nebula` (Core) | `$(qmake6 -query QT_INSTALL_QML)/Nebula/` | `core/**/*.qml`, aplati, un fichier par type |
| Sous-module `Nebula.Platform.Sddm` | `.../Nebula/Platform/Sddm/` | `platform/sddm/*.qml` |
| Marqueur de version du Core | `.../Nebula/.nebula-install-info` | généré à l'installation (commit Git si disponible) |
| Thème installé | `/usr/share/sddm/themes/<nom>/` | `themes/<nom>/` (imports réécrits, voir §3) |
| Marqueur de thème géré | `/usr/share/sddm/themes/<nom>/.nebula-managed` | généré à l'installation |

`$(qmake6 -query QT_INSTALL_QML)` n'est **jamais** codé en dur — résolu
dynamiquement à chaque exécution des scripts, pour rester correct
malgré des différences de chemin entre distributions (non observées à
ce jour sur la seule distribution testée réellement, voir
`Development-Journal.md`).

## 3. Ce que fait `scripts/install-nebula.sh` aux fichiers source

- **Module Core** : chaque fichier `core/**/*.qml` est copié à plat (un
  seul niveau de dossier) ; les imports internes relatifs
  (`import "../theme"`, etc.) sont retirés — les types d'un même module
  QML se résolvent entre eux sans import explicite. Un `qmldir` est
  généré en scannant les fichiers présents, jamais maintenu à la main —
  ne peut donc pas dériver de la réalité du Core.
- **Thème** : copié tel quel, puis son `Main.qml` voit ses imports
  relatifs vers `core/`/`platform/sddm/` réécrits en `import Nebula`/
  `import Nebula.Platform.Sddm`. Le fichier source du thème dans le
  dépôt n'est **jamais** modifié — seule la copie installée l'est (voir
  `Deployment-Decision.md` pour pourquoi ce choix plutôt que de renommer
  `core/` en `Nebula/` dans le dépôt lui-même).

## 4. Compatibilité entre distributions Linux

Non testé à ce jour sur une distribution autre que celle de
développement (voir `SDDM-Compatibility.md` et
`Development-Journal.md`) — `qmake6 -query QT_INSTALL_QML` devrait
rester correct partout où Qt6 est correctement installé (c'est la
méthode officielle Qt pour découvrir ce chemin, pas une convention
propre à une distribution), mais seule une installation réelle sur une
seconde distribution confirmerait l'absence de surprise.

## 5. Empaqueter un nouveau thème

Un thème packagé n'a besoin d'installer que son propre contenu
(`themes/<nom>/`) et de dépendre du paquet `nebula-core` — voir
`scripts/install-nebula.sh` pour la logique exacte de réécriture des
imports à reproduire dans un paquet natif (`.deb`/`.rpm`/PKGBUILD) si on
ne veut pas dépendre du script shell directement.
