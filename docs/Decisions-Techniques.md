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
