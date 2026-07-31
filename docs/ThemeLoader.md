# ThemeLoader — Nebula

> Comment Nebula charge les valeurs d'un thème sans jamais laisser un
> composant, ou même un thème, parser `theme.conf` lui-même. Complète
> [`Theme-System.md`](Theme-System.md) (le flux général de theming) et
> [`Theme-SDK.md`](Theme-SDK.md) (le contrat d'un thème). Introduit en
> Phase 2.0.5 (voir `Roadmap.md`) pour résoudre DT-0017 sans modification
> de l'API publique du Core.

---

## 1. Pourquoi

La Phase 2.0 a construit `themes/template/Main.qml` et
`tests/ThemeHarness.qml` en dupliquant une même petite fonction
(`applyFlatValues()`) pour peupler un `NebulaThemeConfig` à partir de
valeurs plates. C'était un pis-aller volontaire (voir DT-0017 dans
`Decisions-Techniques.md`) : un seul consommateur ne justifiait pas
encore un composant Core dédié. Avec deux consommateurs réels (le
Template et le ThemeHarness) et Nord en approche (Phase 2.1), cette
logique mérite un unique propriétaire : `NebulaThemeLoader`
(`core/theme/NebulaThemeLoader.qml`).

## 2. Responsabilités

`NebulaThemeLoader` :

- lit `theme.conf` (format ini, section `[General]`) ;
- valide chaque valeur au mieux (voir §4) ;
- applique les valeurs à un `NebulaThemeConfig` qu'il possède ;
- ne décide jamais rien d'autre.

Il ne connaît :

- aucun composant Core (`NebulaButton`, ...) ;
- aucun thème particulier (`nord`, `cyberpunk`, ...) ;
- aucune logique métier (authentification, sessions, ...).

C'est un adaptateur entre les fichiers d'un thème et `NebulaThemeConfig`
— rien de plus (voir [`Nebula-Principles.md`](Nebula-Principles.md) §1).

## 3. Pourquoi la lecture de fichier, pas `config` (SDDM)

SDDM expose déjà `theme.conf` comme une propriété de contexte plate
(`config.<clé>`, confirmé réel en Phase 1.0 — voir
`Prototype-Results.md` §3.2). `NebulaThemeLoader` ne l'utilise
volontairement **pas** : lire une propriété de contexte SDDM
directement depuis `core/` romprait
[`Nebula-Principles.md`](Nebula-Principles.md) §2 (« le Core ne connaît
jamais SDDM directement »). `NebulaThemeLoader` lit `theme.conf` lui-même
via `XMLHttpRequest` (nécessite `QML_XHR_ALLOW_FILE_READ=1`, désactivé
par défaut sur ce build Qt6 — voir `Development-Journal.md`, Phase
2.0.5). Conséquence positive : le même code fonctionne à l'identique
sous SDDM réel, sous `sddm-greeter --test-mode`, et en standalone
(`qml6`) — voir [`Compatibility-Matrix.md`](Compatibility-Matrix.md).

## 4. Cycle de chargement

```text
Main.qml (ou ThemeHarness.qml) du thème
 │  configPath: Qt.resolvedUrl("theme.conf")  — relatif à sa propre position
 ▼
NebulaThemeLoader
 │  1. lit configPath (XMLHttpRequest, échec → loadError, config inchangé)
 │  2. parse le [General] en paires clé/valeur
 │  3. pour chaque token connu de NebulaThemeConfig :
 │       - absent du fichier → laisse la valeur par défaut du Core
 │       - présent → assigne, puis vérifie le résultat (voir §5)
 │  4. pour chaque clé du fichier qui ne correspond à aucun token connu :
 │       - journalise "Unknown token: X — ignored." et l'ignore
 ▼
NebulaThemeConfig peuplé (loader.config)
 ▼
NebulaThemeProvider { config: loader.config }
 ▼
Composants Core (via NebulaThemeProvider uniquement, jamais le Loader)
```

Un thème n'a besoin d'aucune indirection par « nom de thème » : son
`Main.qml` connaît déjà sa propre position sur disque
(`Qt.resolvedUrl("theme.conf")`), donc `configPath` pointe directement
dessus — pas de résolution par nom à charge du Loader.

## 5. Stratégie de validation

`NebulaThemeLoader` reste **tolérant** : aucune anomalie ne provoque de
crash, et il ne corrige jamais une valeur invalide en devinant une
alternative — il journalise clairement et garde la valeur par défaut du
Core.

- **Token inconnu** (clé de `theme.conf` sans correspondance dans
  `NebulaThemeConfig`) : journalisé, ignoré.
- **Token absent** (déclaré dans `NebulaThemeConfig` mais pas dans
  `theme.conf`) : rien à faire, la valeur par défaut du Core s'applique
  déjà.
- **Valeur invalide** : détectée *après* assignation plutôt que par une
  validation de format a priori — un nombre invalide devient `NaN`
  (`isNaN()` le détecte), une couleur invalide expose `valid: false`
  (propriété native Qt, voir `Development-Journal.md`, Phase 2.0.5). Dans
  les deux cas, la valeur précédente est restaurée et l'anomalie
  journalisée.
- **Fichier vide ou introuvable** : aucune exception ne remonte à
  l'appelant — `loadError` est renseigné, `loaded` reste `false`, et
  `NebulaThemeConfig` garde entièrement ses valeurs par défaut.

## 6. API

- **Properties** : `configPath` (url), `config` (`NebulaThemeConfig`,
  lecture seule — peuplé par le Loader), `themeName` (string, lecture
  seule, dérivé du dossier parent de `configPath`, purement informatif),
  `loaded` (bool, lecture seule), `loadError` (string, lecture seule).
- **Methods** : `reload()` — force une relecture (utile en
  développement ; pas de rechargement à chaud automatique, voir
  `Architecture.md`, Inconnues critiques).
- **Signals** : `themeLoaded()`, `themeLoadFailed(reason: string)`.

### Piège trouvé : ne pas dépendre des signaux pour le tout premier chargement

Quand `configPath` est fourni comme valeur littérale au moment même où le
`NebulaThemeLoader` est instancié (le cas courant), ce premier chargement
se produit **de façon synchrone pendant la construction** — avant qu'un
handler `onThemeLoaded`/`onThemeLoadFailed` déclaré dans le même bloc
d'objet ne soit connecté. Ce premier signal est donc silencieusement
manqué par un tel handler (vérifié réellement, voir
`Development-Journal.md`, Phase 2.0.5). **Toujours lire `loaded`/
`loadError`/`config` directement** (correctement peuplés et synchrones
dès que le code appelant s'exécute) plutôt que de compter sur ces
signaux pour le chargement initial — ils ne sont utiles que pour un
changement de `configPath` survenant *après* la construction (ex. un
`reload()` manuel déclenché plus tard).

## 7. Consommateurs

- `themes/template/Main.qml` — voir `Creating-A-Theme.md`.
- `tests/ThemeHarness.qml` — visualisation standalone des tokens actifs.
- `tests/ThemeLoaderHarness.qml` — exercice des cas de validation (§5).

Aucun autre fichier du projet ne doit lire `theme.conf` ni appliquer des
valeurs à `NebulaThemeConfig` — voir le critère de fin de la Phase 2.0.5
dans `Roadmap.md`.
