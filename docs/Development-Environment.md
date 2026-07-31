# Development Environment — Nebula

> Comment développer et tester un thème ou un composant Core sans toucher
> au greeter SDDM actif de la machine de développement.

---

## 1. Principe

Ne jamais remplacer le thème SDDM actif du système pour développer.
SDDM fournit un mode de test qui affiche le greeter dans une fenêtre de la
session courante, sans redémarrer ni modifier la configuration système.

## 2. Outils nécessaires

- SDDM installé avec son binaire de test (`sddm-greeter` ou
  `sddm-greeter-qt6` selon la distribution).
- Qt6 (paquets de développement QML : `qml6-module-qtquick`,
  `qml6-module-qtquick-controls`, etc. selon la distribution).
- `qmllint` (fourni par les outils de développement Qt6) pour le lint
  local avant de pousser (voir `.github/workflows/qml-lint.yml`).
- Un environnement graphique Wayland ou X11 actif (le mode test s'exécute
  dans une fenêtre de la session courante, pas besoin d'un second TTY).

## 3. Mode test du greeter

Commande de base (le nom exact du binaire varie selon la distribution —
`sddm-greeter` sur certaines, `sddm-greeter-qt6` sur d'autres) :

```bash
sddm-greeter --test-mode --theme /chemin/vers/nebula/themes/nord
```

Ceci affiche le thème ciblé dans une fenêtre, avec des données
utilisateur/session simulées, sans nécessiter les privilèges du service
SDDM système.

Points de vigilance confirmés par le premier test réel (Phase 1.0, voir
[`Prototype-Results.md`](Prototype-Results.md)) :

- le binaire exact fourni par le paquet SDDM de la distribution utilisée ;
- les variables d'environnement nécessaires (`QT_QPA_PLATFORM` pour forcer
  Wayland ou X11 selon le test voulu) ;
- **le mode test ouvre une vue par écran physique connecté**, pas une
  seule — sur une machine multi-écran, s'attendre à voir apparaître
  plusieurs fenêtres, une par sortie (confirmé avec 3 écrans réels, voir
  `Prototype-Results.md` §3.3) ;
- **`sddm.login()` ne fonctionne pas en mode test** : aucun backend
  d'authentification réel n'est connecté (`QLocalSocket::connectToServer:
  Invalid name` dans les logs) — voir `Prototype-Results.md` §3.5.

### 3.1 Lire les logs du greeter

`sddm-greeter` (et `sddm-greeter-qt6`) **n'écrit pas ses logs sur
stdout/stderr** dès qu'il détecte ne pas être attaché à un terminal
interactif (ce qui est systématiquement le cas si vous redirigez la
sortie vers un fichier) — il bascule sur le journal systemd. Une
redirection classique (`sddm-greeter --test-mode ... > out.log 2>&1`)
produira un fichier vide même si le greeter tourne normalement et logue
des avertissements QML. Utiliser plutôt :

```bash
journalctl --no-pager -n 100 | grep -iE "sddm-greeter|votre-theme"
```

Découverte empiriquement pendant le prototype de Phase 1.0 — voir
[`Prototype-Results.md`](Prototype-Results.md) §3.5.

Alternative plus directe si vous lancez la commande vous-même (pas besoin
de `journalctl`) : passer `QT_LOGGING_TO_CONSOLE=1` (ou
`QT_ASSUME_STDERR_HAS_CONSOLE=1`/`QT_FORCE_STDERR_LOGGING=1`) à
l'invocation — fonctionne aussi bien sur `sddm-greeter-qt6` que sur
`qml6`, voir [`Compatibility-Matrix.md`](Compatibility-Matrix.md) §1.

## 4. Commande future : `scripts/test-theme.sh`

**Non implémentée à ce jour** — décrite ici pour fixer le comportement
attendu avant de l'écrire (voir `Roadmap.md`, Phase 1).

```bash
./scripts/test-theme.sh ThemeName
```

Comportement prévu :

1. Résoudre le chemin de `themes/ThemeName/`.
2. Vérifier que le thème contient au minimum `theme.conf` et `Main.qml`
   (voir [`Theme-SDK.md`](Theme-SDK.md)).
3. Lancer `sddm-greeter --test-mode --theme <chemin résolu>` avec les
   variables d'environnement appropriées.
4. Afficher un message d'erreur clair si le thème est introuvable ou mal
   formé, plutôt que de laisser échouer `sddm-greeter` silencieusement.

Ce script est un simple wrapper de confort : il ne doit contenir aucune
logique métier (celle-ci reste dans `NebulaThemeLoader`, voir
`Core-API.md`).

## 5. Rechargement à chaud pendant le développement

Non garanti en v1 (voir `Architecture.md`, Inconnues critiques). En
attendant, le cycle de développement attendu est : modifier le QML,
relancer `sddm-greeter --test-mode`, observer. Un rechargement à chaud
plus rapide pourra être ajouté à `test-theme.sh` si le besoin devient réel
et récurrent (voir le principe de travail du workspace — pas d'outillage
avant besoin observé).

## 6. Lint avant de pousser

Avant toute Pull Request touchant du QML :

```bash
find . -name "*.qml" -not -path "./.git/*" | xargs qmllint
```

C'est exactement ce que fait `.github/workflows/qml-lint.yml` en CI —
le lancer localement évite un aller-retour CI inutile.

Le flag `--warnings-as-errors` initialement documenté ici n'existe pas
sur le `qmllint` réellement installé (Qt 6.11.1, vérifié pendant la
Phase 1.1 — voir `docs/Core-Implementation-Status.md`). `qmllint` sans
option échoue déjà (code de sortie non nul) sur une vraie erreur de
syntaxe, ce flag n'était donc pas nécessaire.
