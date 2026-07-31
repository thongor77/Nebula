# Theme System — Nebula

> Décrit le flux complet de chargement et de distribution d'un thème, du
> démarrage du greeter jusqu'à l'affichage d'un composant. Complète
> [`Architecture.md`](Architecture.md) (structure générale) et
> [`Design-System.md`](Design-System.md) (vocabulaire des tokens).
>
> Origine : formalise le concept de `ThemeProvider` introduit par la
> proposition externe *Nebula Architecture Enhancement Proposal*
> (section 5) — voir DT-0006 dans
> [`Decisions-Techniques.md`](Decisions-Techniques.md).

---

## 1. Pourquoi ce document

`ThemeConfig` (DT-0003) définit *où vivent* les valeurs configurables.
`ThemeLoader` définit *comment un thème est chargé* au démarrage. Ce qui
manquait : une règle claire sur *comment un composant accède* à ces
valeurs. Sans cette règle, chaque composant risquerait de lire
`ThemeConfig` ou les fichiers du thème directement, recréant la
duplication que Nebula cherche justement à éliminer (voir
`Architecture.md`, section 1, Problème).

## 2. Flux de theming

```text
Theme (fichiers du thème actif : couleurs, wallpaper, layout, assets)
   │
   ▼
NebulaThemeLoader   (charge le thème au démarrage, gère les erreurs/fallback)
   │
   ▼
NebulaThemeConfig   (valeurs résolues : tokens du Design System + assets)
   │
   ▼
NebulaThemeProvider (point d'accès unique exposé aux composants)
   │
   ▼
Components          (NebulaClock, NebulaUserList, NebulaPasswordField, ...)
```

Règle stricte : **un composant Core ne connaît que `NebulaThemeProvider`.**
Il n'accède jamais directement à `NebulaThemeLoader` ni aux fichiers du
thème, et ne lit `NebulaThemeConfig` qu'au travers de `NebulaThemeProvider`.

## 3. Responsabilités

### NebulaThemeLoader

- Détecte et charge le thème actif au démarrage du greeter.
- Résout les chemins d'assets du thème.
- Gère l'échec de chargement (thème mal formé → fallback vers un thème
  minimal plutôt qu'un écran noir — voir `Specifications-Techniques.md`).
- Ne s'exécute qu'une fois par session de greeter (pas de rechargement à
  chaud en v1 — voir Inconnues critiques dans `Architecture.md`).

### NebulaThemeConfig

- Stocke les valeurs résolues du thème actif : tokens du Design System
  (couleurs, spacing, radius, typography, animation, effets) et chemins
  d'assets.
- N'a aucune logique de chargement ni de distribution — un simple
  conteneur de valeurs.
- Mécanisme de stockage sous-jacent encore ouvert (DT-0003).

### NebulaThemeProvider

- Seul point d'entrée que les composants Core sont autorisés à consommer.
- Expose les tokens de `Design-System.md` sous une API stable, quelle que
  soit l'évolution interne de `NebulaThemeConfig`/`NebulaThemeLoader`.
- Permet de faire évoluer le mécanisme de stockage (DT-0003) sans jamais
  toucher aux composants qui le consomment.
- Doit rester en permanence synchronisé avec `NebulaThemeConfig` : tout
  groupe de tokens ajouté à l'un doit être exposé par l'autre. Régression
  réelle trouvée en Phase 1.5 (`overlay`/`surface` définis mais non
  exposés) — voir `docs/Development-Journal.md`. Vérifié automatiquement
  depuis la Phase 1.6 par `tests/ThemeSyncCheck.qml` (voir
  [`Design-Tokens-Reference.md`](Design-Tokens-Reference.md)).

## 4. Ordre d'initialisation

Garanti par le Core, quel que soit le mécanisme de stockage retenu
(DT-0003) :

1. `NebulaThemeLoader` s'exécute en premier et se termine — avec succès ou
   par un repli sur le thème minimal — **avant** que `NebulaThemeProvider`
   ne soit instancié.
2. `NebulaThemeProvider` n'est exposé aux composants qu'une fois rempli de
   valeurs valides (jamais de valeur `undefined`).
3. Aucun composant Core ne doit lire `NebulaThemeProvider` avant cet
   instant. En pratique, un composant qui a besoin d'une valeur de theming
   dans son `Component.onCompleted` peut supposer que `NebulaThemeProvider`
   est déjà pleinement résolu — pas de risque de course entre chargement
   du thème et affichage du premier composant.

Cette garantie fait partie du contrat de `NebulaThemeProvider` (voir
[`Core-API.md`](Core-API.md)) et doit être vérifiée par un test dès la
première implémentation (voir `Specifications-Techniques.md`, Definition
of Done : suite de tests minimale).

## 5. Valeurs par défaut

`NebulaThemeConfig` doit toujours résoudre **chaque** token du
[Design System](Design-System.md) vers une valeur concrète, y compris
quand :

- le thème actif ne définit pas explicitement un token donné (un thème
  n'est pas obligé de tout redéfinir) ;
- `NebulaThemeLoader` est tombé en repli sur le thème minimal après un
  échec de chargement.

Pour cela, le Core embarque un jeu de valeurs par défaut pour l'ensemble
des tokens du Design System (le "thème minimal" de repli mentionné dans
`Specifications-Techniques.md`, section NebulaThemeLoader). Un composant
Core ne doit jamais avoir à gérer lui-même l'absence d'une valeur — c'est
la responsabilité de `NebulaThemeConfig`/`NebulaThemeProvider`, jamais celle
du composant qui consomme le token.

## 6. Gestion des erreurs

Voir `NebulaThemeLoader` dans [`Core-API.md`](Core-API.md) :
`themeLoadFailed(reason)` est émis, puis le thème minimal (section 5
ci-dessus) est chargé à la place — jamais d'écran noir ou de composant
affichant une valeur indéfinie.

## 7. Conséquence sur le contrat des composants

Le "Definition of Done" d'un composant Core (voir
`Specifications-Techniques.md`) inclut désormais : *le composant lit ses
valeurs visuelles exclusivement via `NebulaThemeProvider`*.

## 8. Lien avec Nebula Designer (vision long terme)

Le futur outil graphique **Nebula Designer** (voir `Roadmap.md`, Phase 4)
devra pouvoir modifier les valeurs d'un thème puis les exporter dans un
format que `NebulaThemeLoader` sait recharger. Cette contrainte pèse sur le
choix du mécanisme de stockage de `NebulaThemeConfig` (DT-0003) : le format
retenu doit rester lisible/écrivable simplement (proche d'un `.conf` ou
d'un JSON structuré), pas seulement optimisé pour la lecture QML. Ce n'est
pas une décision figée — juste une contrainte supplémentaire à peser lors
du prototype de la Phase 0.
