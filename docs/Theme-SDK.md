# Theme SDK — Nebula

> Référence **normative** du système de thèmes Nebula : ce qu'un thème est
> autorisé ou non à faire, sa structure, ses conventions de nommage, ses
> dossiers réservés, les tokens qu'il peut personnaliser. Toute règle
> vient d'ici. Pour un tutoriel pas-à-pas destiné à un nouveau
> contributeur, voir [`Creating-A-Theme.md`](Creating-A-Theme.md) — ce
> document n'y répète jamais les règles, il y renvoie.
>
> Anciennement `Theme-Development.md` — renommé et étendu en Phase 2.0
> (voir `Roadmap.md`) pour rester l'unique source de vérité du sujet
> plutôt que de laisser une seconde documentation se créer à côté (voir
> `Core-Implementation-Status.md`, Phase 2.0). Voir aussi le critère de
> réussite du Core dans
> [`Architecture.md`](Architecture.md#6-critère-de-réussite-du-core).
>
> **Distribution (résolu en Phase 2.2)** : un thème conforme à ce SDK
> utilise des imports relatifs vers `core/`/`platform/` dans le dépôt
> (`sddm-greeter --test-mode` sur `themes/<nom>/`, voir
> `Creating-A-Theme.md`). Une installation système réelle
> (`scripts/install-nebula.sh`) réécrit ces imports vers le module QML
> `Nebula` installé séparément — voir
> [`Deployment-Decision.md`](Deployment-Decision.md) et
> [`Packaging.md`](Packaging.md). Le dépôt lui-même ne change jamais ses
> propres imports relatifs ; seule la copie installée est transformée.

---

## 1. Structure d'un thème

Référence officielle : [`themes/template/`](../themes/template/), à copier
pour démarrer un nouveau thème (voir `Creating-A-Theme.md`).

```text
themes/
    ExampleTheme/
        README.md
        metadata.desktop
        theme.conf
        Main.qml
        preview.png
        assets/
            wallpapers/
            icons/
            fonts/
```

- `README.md` — identité visuelle, options de personnalisation,
  compatibilité (voir `CONTRIBUTING.md`, section Documentation).
- `metadata.desktop` — **ajouté suite au prototype de Phase 1.0**
  (voir [`Prototype-Results.md`](Prototype-Results.md) §6) : format réel
  exigé par SDDM, `[SddmGreeterTheme]` (`Name=`, `Description=`,
  `MainScript=`, `ConfigFile=`, `Theme-API=`, `QtVersion=`, ...). Non
  strictement requis pour un test direct via `sddm-greeter --test-mode
  --theme <chemin>` avec les noms de fichiers par défaut (vérifié : ça
  fonctionne sans), mais nécessaire pour qu'un thème soit sélectionnable
  normalement par SDDM (`/usr/share/sddm/themes/<nom>/` +
  `Current=<nom>` dans la configuration SDDM).
- `theme.conf` — valeurs des tokens du [Design System](Design-System.md)
  pour ce thème (voir [`Design-Tokens-Reference.md`](Design-Tokens-Reference.md)
  pour la liste exhaustive). Format ini `[General] clé=valeur`, confirmé
  fonctionnel : SDDM expose lui-même ces clés en lecture directe via la
  propriété de contexte réelle `config` (`config.cléIni` — passthrough
  direct, confirmé par le thème `Breeze` et par nos propres logs, voir
  `Prototype-Results.md` §3.2). Mécanisme d'écriture/export pour un futur
  outil externe encore ouvert — voir DT-0003.
- `Main.qml` — assemble les composants du Core (voir
  [`Core-API.md`](Core-API.md)) selon le layout propre au thème. C'est le
  point d'entrée réel chargé par SDDM (ou par `qml6`/`sddm-greeter
  --test-mode` en développement).
- `preview.png` — aperçu statique du thème (utile à un futur
  sélecteur de thème/Nebula Designer — voir `Roadmap.md`, Phase 4). Un
  simple placeholder suffit tant qu'aucun outil ne le consomme.
- `assets/` — fonds d'écran, icônes, polices spécifiques au thème (les
  assets partagés vivent dans `core/assets/`, pas ici). Sous-dossiers
  réservés : `wallpapers/`, `icons/`, `fonts/` — voir §3.

**Pas de dossier `overrides/`** : envisagé lors de la rédaction du brief
de cette phase, retiré avant implémentation (décision utilisateur,
2026-07-31) — un mécanisme d'override de composant contredirait
directement §4 ci-dessous, et aucun besoin réel ne le justifie encore
(principe du workspace : pas d'outillage avant besoin observé). Si un cas
concret apparaît lors de l'implémentation de Nord ou d'un thème suivant,
il fera l'objet d'une décision documentée dans
[`Decisions-Techniques.md`](Decisions-Techniques.md) avant toute
implémentation — pas d'ajout silencieux.

## 2. Ce qu'un thème doit fournir

Un thème fournit uniquement :

- son **identité visuelle** — valeurs des tokens dans `theme.conf` ;
- sa **configuration** — quels composants optionnels sont activés
  (effets GPU, fond animé, etc.) et avec quels paramètres ;
- ses **assets** propres ;
- son **layout** — assemblage des composants Core dans `Main.qml` ;
- ses **animations** — paramètres (durées, easing autorisés une fois
  stabilisés — voir `Design-System.md` §5), jamais de nouveau moteur
  d'animation.

Voir [`Specifications-Techniques.md`](Specifications-Techniques.md),
section 3, pour la liste exhaustive des éléments obligatoires et
optionnels qu'un thème complet doit couvrir.

## 3. Conventions de nommage et dossiers réservés

- Nom de dossier de thème en minuscules, sans espace (`nord`, `cyberpunk`,
  pas `Nord Theme`) — cohérent avec `themes/README.md`.
- `theme.conf` ne définit que des clés déjà cataloguées dans
  [`Design-Tokens-Reference.md`](Design-Tokens-Reference.md) — toute
  valeur manquante est d'abord ajoutée au Design System (voir
  `Design-System.md`), jamais inventée localement dans un thème.
- Dossiers réservés sous `assets/` : `wallpapers/`, `icons/`, `fonts/`.
  Un thème peut les laisser vides mais ne doit pas en créer d'autres au
  même niveau sans raison documentée (vérifié par `check-theme.sh`, §6,
  pour rester cohérent d'un thème à l'autre).

## 4. Ce qu'un thème ne doit jamais faire

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

Si l'un de ces points semble nécessaire pour livrer un thème, c'est le
signal que l'architecture du Core doit être revue, pas que le thème doit
contourner la règle (voir `Architecture.md`, section 6, Critère de
réussite du Core) — documenter le besoin et proposer une décision
(`Decisions-Techniques.md`) avant d'agir, jamais l'inverse.

## 5. Tokens attendus

Liste exhaustive, valeurs par défaut et composants consommateurs : voir
[`Design-Tokens-Reference.md`](Design-Tokens-Reference.md). Un thème ne
définit dans `theme.conf` que des clés qui y figurent déjà.

## 6. Outils de validation

Trois outils, trois rôles distincts — ne pas les confondre :

- **`scripts/check-theme.sh <ThemeName>`** (Phase 2.0) — validation
  **statique** de la structure d'un thème contre ce document (fichiers
  obligatoires présents, `theme.conf` valide et ne référençant que des
  tokens connus, dossiers réservés respectés). Ne lance rien, ne rend
  rien à l'écran.
- **`tests/ThemeHarness.qml`** (Phase 2.0) — charge réellement un thème
  et **visualise** ses tokens actifs / détecte une erreur de chargement,
  hors SDDM (voir `Core-Implementation-Status.md`, Phase 2.0, pour la
  limite connue tant que `NebulaThemeLoader` n'existe pas).
- **`scripts/test-theme.sh <ThemeName>`** (toujours non implémenté, voir
  [`Development-Environment.md`](Development-Environment.md) §4) — lance
  le thème pour de vrai via `sddm-greeter --test-mode`, le test ultime
  avant une Pull Request.

## 7. Checklist avant de proposer un thème

- [ ] Le thème ne modifie aucun fichier sous `core/`.
- [ ] `metadata.desktop` présent (requis pour une installation normale,
      voir §1).
- [ ] `theme.conf` ne définit que des valeurs de tokens déjà catalogués
      dans `Design-Tokens-Reference.md` — toute valeur manquante est
      d'abord ajoutée au Design System, pas inventée localement.
- [ ] `Main.qml` assemble uniquement des composants du
      [Core API](Core-API.md), sans copie de leur code.
- [ ] Tous les éléments obligatoires de
      `Specifications-Techniques.md` (section 3) sont présents.
- [ ] `README.md` du thème documente l'identité visuelle et les options de
      personnalisation.
- [ ] `scripts/check-theme.sh <ThemeName>` passe.
- [ ] Testé en mode `sddm-greeter --test-mode` avant la Pull Request (voir
      `CONTRIBUTING.md`, section Pull requests).
