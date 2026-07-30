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
`NebulaButton`, `NebulaClock`, `NebulaThemeConfig`, `NebulaThemeProvider`,
etc.

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

---

## DT-0009 — Core API définie avant l'implémentation

Date : 2026-07-30
État : accepté

### Contexte

Fin de la Phase 0.5 (voir `Roadmap.md`) : avant d'écrire le moindre
composant QML, il fallait décider si le contrat public du Core
(propriétés, signaux, dépendances de chaque composant) devait être figé en
documentation d'abord, ou découvert au fil de l'implémentation.

> Note sur la forme : la demande d'origine proposait de créer ce contenu
> comme un fichier ADR séparé (`DT-0009-Core-API-First.md`). Pour rester
> cohérent avec DT-0001 à DT-0008, qui vivent tous comme sections d'un seul
> fichier `Decisions-Techniques.md` (voir `META/Standards.md` : les
> décisions propres à un seul projet vont dans ce fichier, le dossier
> `META/ADR/` étant réservé aux décisions transversales au workspace), cette
> décision est ajoutée ici plutôt que dans un fichier séparé.

### Décision

Les contrats d'API du Core (`docs/Core-API.md`) sont définis et documentés
avant que l'implémentation QML ne commence. Toute Pull Request Core
respecte le contrat déjà documenté ; toute divergence nécessaire est
d'abord discutée et mise à jour dans `Core-API.md`, pas introduite
silencieusement dans le code.

### Alternatives étudiées

- Définir l'API au fil de l'implémentation, sans contrat préalable :
  rejeté, risque de changements structurels tardifs une fois plusieurs
  thèmes déjà dépendants d'une première version de l'API.
- Documenter l'API a posteriori, une fois le Core MVP livré : rejeté, un
  contrat écrit après coup décrit ce qui existe, pas ce qui est garanti,
  et perd son utilité pour des contributeurs externes qui commenceraient
  avant la Phase 1.

### Raisons

- Éviter des changements structurels tardifs une fois plusieurs thèmes
  dépendants du Core.
- Permettre à plusieurs thèmes d'être développés en parallèle sur un
  contrat stable.
- Faciliter les contributions externes : un contributeur doit pouvoir
  commencer une implémentation sans ambiguïté, uniquement à partir de
  `docs/`.

### Conséquences

Toute Pull Request Core qui modifie une propriété, un signal ou une
dépendance déjà documentée dans `Core-API.md` doit mettre à jour ce fichier
dans la même PR (voir `CONTRIBUTING.md`). Le Core MVP (Phase 1) ne démarre
qu'après la revue de `Core-API.md`, `SDDM-Compatibility.md`,
`Development-Environment.md` et `Theme-Development.md` (voir `Roadmap.md`,
Phase 0.5).

---

## DT-0010 — `platform/` hors de `core/`, adapters non préfixés `Nebula`

Date : 2026-07-30
État : accepté

### Contexte

La Phase 1.4 introduit des Platform Adapters (`SDDMAuthAdapter`,
`SDDMUserAdapter`, `SDDMSessionAdapter`, `SDDMPowerAdapter`) qui
dialoguent réellement (à terme) avec SDDM. Deux questions : où les
placer, et comment les nommer — le brief d'origine ne suit pas la
convention `Nebula*` (DT-0004) pour eux.

### Décision

Les adapters vivent dans un nouveau dossier de premier niveau,
`platform/sddm/`, pas sous `core/`. Ils ne portent pas le préfixe
`Nebula` — DT-0004 s'applique aux "composants exportés par le Core" ;
les adapters ne sont ni exportés, ni du Core (ils vivent hors de
`core/`), ni réutilisables entre thèmes. Leur nom porte celui de la
plateforme concrète (`SDDM*Adapter`), à l'image de `themes/nord/` qui ne
s'appelle pas `NebulaNord`.

Les Services eux-mêmes (`NebulaAuthService`, etc.), qui vivent dans
`core/services/`, restent préfixés `Nebula` — DT-0004 s'applique
pleinement à eux.

### Alternatives étudiées

- `core/platform/sddm/` : rejeté — brouillerait la garantie "le Core ne
  connaît jamais SDDM" (`Core-API.md` §1, `Nebula-Principles.md` §2) en
  laissant du code spécifique à SDDM techniquement *sous* `core/`.
- Préfixer aussi les adapters `NebulaSDDMAuthAdapter` : rejeté, redondant
  — tout le projet s'appelle déjà Nebula, préfixer un dossier
  intrinsèquement spécifique à une plateforme n'ajoute pas d'information.

### Raisons

`core/` = réutilisable et théoriquement indépendant de tout backend ;
`platform/` = liaison concrète à un backend précis. Les confondre dans un
même espace de noms romprait la distinction que ce dossier existe
justement pour rendre visible.

### Conséquences

Si un jour un second backend est nécessaire (hypothétique, pas un
objectif actuel), il prendrait place en `platform/<nom>/`, suivant la
même convention de nommage.

---

## DT-0011 — Services : `adapter` injecté en duck-typing, jamais de `Connections{}` sur un `QtObject`

Date : 2026-07-30
État : accepté

### Contexte

QML n'offre pas d'interfaces formelles sans passer par du C++. Il fallait
un mécanisme pour que `NebulaAuthService`/`NebulaUserService`/
`NebulaSessionService`/`NebulaPowerService` déclarent un contrat vis-à-vis
d'un `adapter` sans connaître son type concret (mock en test, réel plus
tard).

### Décision

Chaque Service expose une propriété `adapter` (type `var`, duck-typée —
le contrat exact des propriétés/méthodes attendues est documenté dans
`Services-Architecture.md`, pas imposé par le système de types). Pour
réagir à un signal de l'adapter (ex. `loginResult`), la connexion se fait
en JavaScript impératif (`adapter.loginResult.connect(...)` dans
`onAdapterChanged`), **jamais** via un bloc déclaratif `Connections {}`
en enfant direct d'un `QtObject`.

### Alternatives étudiées

- `Connections { target: root.adapter }` déclaré comme enfant du
  `QtObject` racine : **testé, a réellement échoué** —
  `QtObject` n'a pas de "default property" pour accueillir un enfant
  anonyme (contrairement à `Item`, qui déclare `default property list
  data`). Erreur trouvée uniquement à l'exécution
  (`qmllint` ne l'a pas détectée) : "Cannot assign to non-existent
  default property" — voir `Development-Journal.md`, Phase 1.4.
- Faire hériter les Services d'`Item` plutôt que `QtObject` pour
  bénéficier du default property : rejeté pour les Services eux-mêmes
  (pas de `Connections{}` requis une fois la connexion faite en JS
  impératif) — mais accepté ponctuellement pour `MockAuthAdapter`, qui a
  réellement besoin d'un `Timer` enfant (voir `Development-Journal.md`).

### Raisons

Garder les Services en `QtObject` pur (cohérent avec
`NebulaThemeConfig`/`NebulaThemeProvider`, DT existantes) tout en évitant
une erreur d'exécution non détectée par le lint.

### Conséquences

Règle générale pour tout futur composant non-visuel du Core : s'il n'a
besoin d'aucun enfant QML déclaratif (`Timer`, `Connections`, ...), rester
`QtObject`. S'il en a réellement besoin, utiliser `Item` plutôt que de
chercher un contournement — et le documenter, comme pour
`MockAuthAdapter`.
