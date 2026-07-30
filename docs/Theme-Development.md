# Theme Development — Nebula

> Comment créer un nouveau thème Nebula. Ce document est la référence pour
> tout contributeur qui veut ajouter un thème dans `themes/` — voir aussi
> le critère de réussite du Core dans
> [`Architecture.md`](Architecture.md#6-critère-de-réussite-du-core).

---

## 1. Structure cible d'un thème

```text
themes/
    ExampleTheme/
        theme.conf
        Main.qml
        assets/
        README.md
```

- `theme.conf` — valeurs des tokens du [Design System](Design-System.md)
  pour ce thème (couleurs, spacing, radius, typography, animation,
  effets). Format exact encore ouvert — voir DT-0003.
- `Main.qml` — assemble les composants du Core (voir
  [`Core-API.md`](Core-API.md)) selon le layout propre au thème.
- `assets/` — fonds d'écran, icônes spécifiques au thème (les assets
  partagés vivent dans `core/assets/`, pas ici).
- `README.md` — identité visuelle, options de personnalisation,
  compatibilité (voir `CONTRIBUTING.md`, section Documentation).

## 2. Ce qu'un thème doit fournir

Un thème fournit uniquement :

- son **identité visuelle** — valeurs des tokens dans `theme.conf` ;
- sa **configuration** — quels composants optionnels sont activés
  (effets GPU, fond animé, etc.) et avec quels paramètres ;
- ses **assets** propres ;
- son **layout** — assemblage des composants Core dans `Main.qml`.

Voir [`Specifications-Techniques.md`](Specifications-Techniques.md),
section 3, pour la liste exhaustive des éléments obligatoires et
optionnels qu'un thème complet doit couvrir.

## 3. Ce qu'un thème ne doit jamais faire

- **Modifier `core/`.** Si le thème a besoin d'un comportement que le Core
  n'expose pas, la réponse est d'étendre le Core (nouvelle propriété ou
  nouveau composant), jamais de le modifier depuis un thème (voir DT-0002).
- **Copier un composant Core** dans son propre dossier pour le
  personnaliser. C'est exactement la duplication que Nebula existe pour
  éliminer (voir `Architecture.md`, section 1, Problème).
- **Contourner `NebulaThemeProvider`** en lisant `NebulaThemeConfig` ou les
  fichiers du thème directement depuis un composant. Toute valeur visuelle
  passe par `NebulaThemeProvider` (voir DT-0006 et
  [`Theme-System.md`](Theme-System.md)).

Si l'un de ces trois points semble nécessaire pour livrer un thème, c'est
le signal que l'architecture du Core doit être revue, pas que le thème
doit contourner la règle (voir `Architecture.md`, section 6, Critère de
réussite du Core).

## 4. Tester un thème en développement

Voir [`Development-Environment.md`](Development-Environment.md) : mode
test `sddm-greeter --test-mode --theme themes/ExampleTheme`, et le futur
script `scripts/test-theme.sh`.

## 5. Checklist avant de proposer un thème

- [ ] Le thème ne modifie aucun fichier sous `core/`.
- [ ] `theme.conf` ne définit que des valeurs de tokens déjà catalogués
      dans `Design-System.md` — toute valeur manquante est d'abord ajoutée
      au Design System, pas inventée localement.
- [ ] `Main.qml` assemble uniquement des composants du
      [Core API](Core-API.md), sans copie de leur code.
- [ ] Tous les éléments obligatoires de
      `Specifications-Techniques.md` (section 3) sont présents.
- [ ] `README.md` du thème documente l'identité visuelle et les options de
      personnalisation.
- [ ] Testé en mode `sddm-greeter --test-mode` avant la Pull Request (voir
      `CONTRIBUTING.md`, section Pull requests).
