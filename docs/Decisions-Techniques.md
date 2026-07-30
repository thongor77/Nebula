# Décisions techniques — Nebula

> Une décision par section, format inspiré de `META/ADR/Template.md`.
> Les décisions transversales à plusieurs projets du workspace vont dans
> `META/ADR/`, pas ici.

---

## DT-0001 — Wayland en priorité, X11 en compatibilité

Date : 2026-07-30
État : accepté

### Contexte

SDDM doit fonctionner aussi bien sous Wayland (cible principale de
KDE Plasma 6) que sous X11 (encore largement utilisé).

### Décision

Le développement et les tests visent Wayland en premier. Le support X11
est maintenu mais ne doit jamais bloquer une fonctionnalité Wayland.

### Alternatives étudiées

- X11 en priorité, Wayland en support : rejeté, contraire à la direction de
  KDE Plasma 6.
- Deux implémentations parallèles : rejeté, duplication de maintenance.

### Raisons

Plasma 6 pousse Wayland par défaut ; concevoir Wayland-first évite de devoir
réécrire le Core plus tard.

### Conséquences

Toute fonctionnalité dépendant d'une API X11-only doit être isolée et
optionnelle. Les inconnues liées au multi-écran Wayland restent ouvertes
(voir `Architecture.md`, section Inconnues critiques).

---

## DT-0002 — Composition plutôt qu'héritage entre Core et Thèmes

Date : 2026-07-30
État : accepté

### Contexte

Il faut choisir comment un thème réutilise les composants du Core : par
héritage QML (`ThemeButton extends NebulaButton`) ou par composition
(import + configuration).

### Décision

Composition uniquement. Un thème importe et configure les composants du
Core via leurs propriétés exposées (`ThemeConfig`) ; il ne les sous-classe
pas pour en changer le comportement interne.

### Alternatives étudiées

- Héritage QML par thème : rejeté, ouvre la porte à des divergences de
  comportement difficiles à maintenir entre thèmes.

### Raisons

La composition garde le Core comme unique source de vérité du comportement.
Un thème ne peut influencer que ce que le Core expose explicitement.

### Conséquences

Si un thème a besoin d'un comportement que le Core n'expose pas, la bonne
réponse est d'étendre le Core (nouvelle propriété/composant), jamais de
contourner via héritage dans le thème.

---

## DT-0003 — Configuration centralisée via ThemeConfig

Date : 2026-07-30
État : proposé

### Contexte

Le mécanisme concret de configuration (fichier `.conf` SDDM classique,
`Qt.labs.settings`, JSON dédié) n'est pas encore tranché — c'est une
inconnue critique de l'architecture.

### Décision

Quel que soit le mécanisme retenu, toute valeur configurable (couleurs,
polices, espacements, chemins d'assets) passe par un point d'entrée unique,
`ThemeConfig`, jamais codée en dur dans un composant.

### Alternatives étudiées

- Configuration éclatée par composant : rejeté, rend la personnalisation
  d'un thème illisible.

### Raisons

Un point d'entrée unique simplifie la création de nouveaux thèmes et
l'écriture d'un futur éditeur de thème (roadmap long terme).

### Conséquences

Le mécanisme de stockage sous-jacent de `ThemeConfig` reste à valider par
prototype avant la phase Core MVP (voir `Roadmap.md`).

### Complément (2026-07-30)

L'analyse de la proposition externe *Nebula Architecture Enhancement
Proposal* ajoute une contrainte à peser lors du prototype : le futur outil
**Nebula Designer** (Roadmap Phase 4) devra pouvoir exporter un thème
modifié dans un format que `ThemeLoader` sait recharger. Cela pousse vers
un format simple à lire/écrire (proche `.conf` ou JSON structuré) plutôt
qu'un format optimisé uniquement pour la lecture QML. Ceci ne referme pas
la décision — juste un critère supplémentaire pour le prototype.

---

## DT-0004 — Convention de nommage `Nebula*`

Date : 2026-07-30
État : accepté

### Contexte

Les composants exportés par le Core doivent être identifiables sans
ambiguïté dans les fichiers QML des thèmes.

### Décision

Tout composant public du Core est préfixé `Nebula` :
`NebulaButton`, `NebulaClock`, `NebulaConfig`, `NebulaTheme`, etc.

### Alternatives étudiées

- Pas de préfixe, organisation uniquement par dossier d'import : rejeté,
  ambiguïté possible avec des composants Qt/QtQuick natifs.

### Raisons

Un préfixe explicite lève toute ambiguïté à la lecture et facilite la
recherche dans l'éditeur.

### Conséquences

Tout nouveau composant Core doit suivre la convention dès sa création.

---

## DT-0005 — Documentation interne en français, documentation publique en anglais

Date : 2026-07-30
État : accepté

### Contexte

Le workspace `claude-projects` impose la règle générale : public → anglais,
interne → français (`META/Standards.md`). Nebula est destiné à être publié.

### Décision

`README.md`, `CONTRIBUTING.md`, les templates GitHub et tout le code
(identifiants, commentaires, commits) sont en anglais. `CLAUDE.md` et
`docs/` restent en français.

### Alternatives étudiées

- Tout en anglais y compris `docs/` : rejeté, contraire à la convention du
  workspace et moins confortable pour la prise de notes techniques
  quotidienne.

### Raisons

Cohérence avec les standards du workspace ; le public visé par le code et
le README est international, la documentation de travail ne l'est pas.

### Conséquences

Un contributeur externe francophone ou non doit pouvoir contribuer au code
sans lire le français ; seule la compréhension approfondie du raisonnement
architectural nécessite `docs/`.

---

## DT-0006 — NebulaThemeProvider comme unique point d'accès au theming

Date : 2026-07-30
État : accepté

### Contexte

Analyse de la proposition externe *Nebula Architecture Enhancement
Proposal* (section 5). Sans règle explicite, rien n'empêchait un composant
Core de lire directement `ThemeConfig` ou les fichiers du thème chargés par
`ThemeLoader`, recréant à terme une dépendance dispersée et difficile à
faire évoluer.

### Décision

Un composant Core ne consomme jamais `ThemeConfig` ni `ThemeLoader`
directement. Il passe exclusivement par `NebulaThemeProvider`, qui expose
les tokens du [Design System](Design-System.md) sous une API stable. Détail
du flux : [`Theme-System.md`](Theme-System.md).

### Alternatives étudiées

- Accès direct des composants à `ThemeConfig` : rejeté, recrée une
  dépendance dispersée à chaque composant.
- Fusionner `ThemeProvider` dans `ThemeConfig` : rejeté, mélange le
  stockage des valeurs (qui peut changer de mécanisme, voir DT-0003) avec
  l'API stable consommée par des dizaines de composants.

### Raisons

Séparer "où sont stockées les valeurs" (`ThemeConfig`) de "comment un
composant les consomme" (`ThemeProvider`) permet de faire évoluer le
mécanisme de stockage sans jamais toucher aux composants.

### Conséquences

Le "Definition of Done" d'un composant Core (voir
`Specifications-Techniques.md`) inclut désormais l'usage exclusif de
`NebulaThemeProvider`.

---

## DT-0007 — Modules Qt6 privilégiés / évités

Date : 2026-07-30
État : accepté

### Contexte

Analyse de la proposition externe *Nebula Architecture Enhancement
Proposal* (section 7). Aucune règle explicite n'existait sur les modules
QML autorisés, avec un risque de dépendre de modules Qt5 dépréciés ou de
compatibilité temporaire.

### Décision

Modules privilégiés : `QtQuick`, `QtQuick.Controls`, `QtQuick.Shapes`,
`ShaderEffect` (effets natifs Qt6). Éviter les modules hérités de Qt5 sans
équivalent natif Qt6 direct (ex. `QtGraphicalEffects` — utiliser
`Qt5Compat.GraphicalEffects` uniquement comme filet temporaire, jamais
comme choix définitif) ainsi que `QtQuick.Controls` en version 1.x.

### Alternatives étudiées

- Ne poser aucune règle et trancher au cas par cas pendant l'implémentation :
  rejeté, risque de dépendances legacy difficiles à retirer une fois le
  Core stabilisé.

### Raisons

Éviter dès la Phase 1 d'introduire une dépendance qu'il faudra retirer plus
tard va dans le sens de la priorité "Maintenabilité" (voir
`Architecture.md`, priorités de conception).

### Conséquences

Toute Pull Request introduisant un module hors de cette liste doit
justifier son choix et, si besoin, mettre à jour cette décision.

---

## DT-0008 — Restructuration `src/{core,themes,tools,shared}/` différée

Date : 2026-07-30
État : rejeté (à réévaluer si besoin réel)

### Contexte

Analyse de la proposition externe *Nebula Architecture Enhancement
Proposal* (section 1), qui propose de déplacer `core/` et `themes/` sous
un dossier `src/`, avec ajout de `tools/` et `shared/`, en anticipation
d'une future application compagnon (Nebula Designer, voir Roadmap Phase 4)
et d'outils de build futurs.

### Décision

Ne pas restructurer maintenant. `core/` et `themes/` restent à la racine.
Seul `tests/` est ajouté à la racine dès maintenant (besoin réel et
immédiat : absence totale de stratégie de test).

### Alternatives étudiées

- Adopter `src/` immédiatement : rejeté pour l'instant.
- Adopter `shared/` en plus de `core/` : rejeté, la proposition ne clarifie
  pas la différence avec `core/` — un `shared/` distinct introduirait une
  ambiguïté (que va-t-il contenir que `core/` ne contient pas ?) sans
  besoin observé.

### Raisons

Le principe de travail du workspace (`~/claude-projects/CLAUDE.md`) est
clair : un nouvel outil ou une nouvelle structure doit résoudre un besoin
réel et observé, pas anticiper un besoin hypothétique. Nebula Designer
(Phase 4) n'est pas encore une phase active — restructurer aujourd'hui pour
lui préparer une place reviendrait à concevoir pour un besoin qui n'existe
pas encore (voir aussi `Architecture.md`, section Hors périmètre).

### Conséquences

À réévaluer précisément au moment où Nebula Designer (ou tout autre
outil/application compagnon) devient une phase active planifiée dans
`Roadmap.md`. Si ce moment arrive, cette décision doit être rouverte plutôt
que contournée silencieusement.
