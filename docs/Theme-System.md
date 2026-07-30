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

## 4. Conséquence sur le contrat des composants

Le "Definition of Done" d'un composant Core (voir
`Specifications-Techniques.md`) inclut désormais : *le composant lit ses
valeurs visuelles exclusivement via `NebulaThemeProvider`*.

## 5. Lien avec Nebula Designer (vision long terme)

Le futur outil graphique **Nebula Designer** (voir `Roadmap.md`, Phase 4)
devra pouvoir modifier les valeurs d'un thème puis les exporter dans un
format que `NebulaThemeLoader` sait recharger. Cette contrainte pèse sur le
choix du mécanisme de stockage de `NebulaThemeConfig` (DT-0003) : le format
retenu doit rester lisible/écrivable simplement (proche d'un `.conf` ou
d'un JSON structuré), pas seulement optimisé pour la lecture QML. Ce n'est
pas une décision figée — juste une contrainte supplémentaire à peser lors
du prototype de la Phase 0.
