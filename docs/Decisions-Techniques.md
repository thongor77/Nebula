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
`Development-Environment.md` et `Theme-SDK.md` (voir `Roadmap.md`,
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

---

## DT-0012 — Séparation `NebulaBackground` (conteneur) / `NebulaWallpaper` (image)

Date : 2026-07-31
État : accepté

### Contexte

`NebulaBackground` était documenté depuis la Phase 0.6 avec un contrat
`source`/`fillMode`/`dimmed` (affichage d'image), mais jamais implémenté.
La Phase 1.5 introduit `NebulaWallpaper`, dont le rôle — charger une
image simple avec repli — recouvre exactement cet ancien contrat. Fallait
choisir : garder un seul composant élargi, ou séparer.

### Décision

Séparer. `NebulaBackground` devient un conteneur racine pur (aucune
propriété, `anchors.fill: parent`, aucune couleur) ; `NebulaWallpaper`
reprend le contrat `source`/`mode` (renommé de `fillMode` à `mode` pour
rester cohérent avec le style des autres énumérations du projet, ex.
`NebulaButton.variant`).

### Alternatives étudiées

- Garder un seul `NebulaBackground` avec toutes les responsabilités
  (conteneur + image) : rejeté — viole la règle "chaque composant doit
  avoir une responsabilité unique" (brief Phase 1.5), et empêcherait de
  composer librement `NebulaOverlay` entre le fond et le contenu sans
  dépendre de la présence d'une image.

### Raisons

Une fois `NebulaOverlay` et `NebulaSurface` introduits dans la même
phase, la composition en couches (Background → Wallpaper → Overlay →
Layout → Surface) exige que chaque couche soit un composant distinct et
librement empilable — un `NebulaBackground` qui gérerait aussi le
chargement d'image ne pourrait pas jouer ce rôle de simple conteneur.

### Conséquences

Rupture d'API par rapport au contrat Phase 0.6 (jamais implémenté, donc
sans impact réel sur du code existant). `Core-API.md` mis à jour pour
refléter les deux composants séparément.

---

## DT-0013 — Pas de tokens `surfaceRadius`/`surfacePadding` dédiés

Date : 2026-07-31
État : accepté

### Contexte

Le brief de la Phase 1.5 suggérait d'enrichir `ThemeConfig` avec
`surfaceRadius`, `surfacePadding`, en plus de `surfaceOpacity` et
`surfaceBorderWidth`.

### Décision

Ajouter uniquement `overlayOpacity`, `surfaceOpacity` et
`surfaceBorderWidth` comme nouveaux tokens (rien de comparable
n'existait). Pour le rayon et le padding, `NebulaSurface` réutilise par
défaut `radius.radiusLarge` et `spacing.spacingMd` — déjà des tokens
génériques exploitables tels quels, surchargeables par instance
(`NebulaSurface { radius: ... }`) si un thème a réellement besoin d'une
valeur différente pour ses surfaces.

### Alternatives étudiées

- Ajouter `surfaceRadius`/`surfacePadding` comme suggéré : rejeté —
  dupliquerait `radiusLarge`/`spacingMd` sans different d'usage réel tant
  qu'aucun thème ne demande explicitement une valeur différente pour ses
  surfaces spécifiquement.

### Raisons

Cohérent avec le principe de travail du workspace (pas d'abstraction
avant besoin observé) et avec le précédent déjà posé par `NebulaButton`,
qui réutilise déjà `radius.radiusMedium` sans token dédié
`buttonRadius`.

### Conséquences

Si un thème a un jour besoin d'un rayon/padding spécifiquement différent
pour ses surfaces (indépendamment des autres usages de `radiusLarge`/
`spacingMd`), cette décision devra être rouverte et des tokens dédiés
ajoutés à ce moment-là.

---

## DT-0014 — `Theme-Development.md` absorbé dans `Theme-SDK.md`, `Creating-A-Theme.md` séparé

Date : 2026-07-31
État : accepté

### Contexte

Le brief de la Phase 2.0 (voir `Roadmap.md`) demandait deux nouveaux
documents : `docs/Theme-SDK.md` (le contrat) et `docs/Creating-A-Theme.md`
(le tutoriel). Or `docs/Theme-Development.md` existait déjà et couvrait
les deux à la fois (structure, ce qu'un thème peut/ne doit jamais faire,
checklist) — le brief a été rédigé sans en tenir compte.

### Décision

`Theme-Development.md` est renommé `Theme-SDK.md` (historique git
préservé via `git mv`) et devient la référence normative unique.
`Creating-A-Theme.md` est un document séparé, strictement un tutoriel
pas-à-pas, qui renvoie vers `Theme-SDK.md` pour toute règle plutôt que de
la répéter.

### Alternatives étudiées

- Garder `Theme-Development.md` inchangé et ajouter les deux nouveaux
  documents à côté : rejeté — trois documents qui se chevauchent
  largement, à maintenir en triple à chaque évolution du contrat.
- Supprimer `Theme-Development.md` et migrer son contenu directement dans
  `Theme-SDK.md` sans renommage (recréer le fichier) : rejeté sans
  raison de perdre l'historique git pour un renommage de pur contenu.

### Raisons

Décision utilisateur explicite (2026-07-31), cohérente avec le principe
déjà appliqué au projet : une seule source de vérité par sujet (précédent
`Decisions-Techniques.md` lui-même, préféré à plusieurs fichiers d'ADR).

### Conséquences

Toute référence à `Theme-Development.md` dans le reste du dépôt a été mise
à jour vers `Theme-SDK.md` (voir `Core-Implementation-Status.md`, Phase
2.0, pour la liste). Toute future doc thème doit se demander : contrat
(→ `Theme-SDK.md`) ou tutoriel (→ `Creating-A-Theme.md`) — jamais un
troisième document.

---

## DT-0015 — Pas de dossier `overrides/` dans le Template de thème

Date : 2026-07-31
État : accepté

### Contexte

Le brief de la Phase 2.0 proposait un dossier `themes/template/overrides/`
sans en définir le contenu. Un mécanisme d'override de composant
contredirait directement l'interdiction déjà établie d'un thème copiant
ou modifiant un composant Core (`Theme-SDK.md` §4, `Nebula-Principles.md`).

### Décision

Ne pas inclure `overrides/` dans le Template. Un thème ne personnalise
que : assets, Design Tokens, animations, configuration.

### Alternatives étudiées

- Overrides d'assets uniquement (remplacer une icône/police de repli
  fournie par le Core) : resterait dans les limites déjà posées, mais
  aucun besoin réel ne le justifie encore.
- Overrides QML par composant : rejeté — contredit directement
  l'interdiction déjà documentée de copier/modifier un composant Core.

### Raisons

Décision utilisateur explicite (2026-07-31) : principe du workspace, pas
d'outillage avant besoin observé. Si un cas concret apparaît lors de
l'implémentation de Nord ou d'un thème suivant, il fera l'objet d'une
nouvelle décision documentée ici avant toute implémentation.

### Conséquences

`scripts/check-theme.sh` échoue explicitement si un thème contient un
dossier `overrides/`, pour empêcher qu'il réapparaisse silencieusement.

---

## DT-0016 — `metadata.desktop` dans le Template, pas `metadata.json`

Date : 2026-07-31
État : accepté

### Contexte

Le brief de la Phase 2.0 listait `metadata.json` dans la structure du
Template. Or `metadata.desktop` (format `[SddmGreeterTheme]`) est le
format réel exigé par SDDM pour qu'un thème soit sélectionnable
normalement, déjà établi et vérifié contre une installation SDDM réelle
en Phase 1.0 (voir `Prototype-Results.md` §6). SDDM ne lit aucun
`metadata.json`.

### Décision

Le Template fournit `metadata.desktop`, pas `metadata.json`. Contenu
vérifié contre plusieurs thèmes SDDM réellement installés sur la machine
de développement (`Ant-Dark-Plasma-6`, `Breeze`, ...).

### Alternatives étudiées

- Fournir les deux fichiers : rejeté — `metadata.json` n'aurait aucun
  consommateur réel tant qu'aucun outil (Nebula Designer, sélecteur de
  thème) n'existe pour le lire ; ajouter un fichier sans lecteur revient
  à de la donnée morte.

### Raisons

Fait technique, pas une préférence — vérifiable directement contre le
comportement réel de SDDM.

### Conséquences

Si un futur outil (Nebula Designer, Phase 4) a besoin de métadonnées
structurées que `metadata.desktop` (format ini) ne peut pas exprimer
proprement, cette décision devra être rouverte à ce moment-là, motivée
par ce besoin réel.

---

## DT-0017 — Pont `theme.conf` → `NebulaThemeConfig` : assignation impérative dupliquée, pas `NebulaThemeLoader` maintenant

Date : 2026-07-31
État : accepté

### Contexte

`themes/template/Main.qml` et `tests/ThemeHarness.qml` doivent tous deux
peupler un `NebulaThemeConfig` à partir de valeurs plates (`config.*` sous
SDDM réel, ou un `theme.conf` parsé manuellement en standalone). Aucun
`NebulaThemeLoader` n'existe encore pour faire ce pont (voir `Roadmap.md`,
Phase 1, item 3). Testé réellement : la syntaxe déclarative de
surcharge groupée (`NebulaThemeConfig { colors.primaryColor: "..." }`)
échoue à la compilation — voir `Development-Journal.md`, Phase 2.0.

### Décision

Dupliquer une petite fonction `applyFlatValues()` (assignation impérative,
générique via `Object.keys()`) dans `Main.qml` et `ThemeHarness.qml`,
documentée explicitement comme un pis-aller temporaire en attendant
`NebulaThemeLoader`.

### Alternatives étudiées

- Construire `NebulaThemeLoader` dès maintenant dans `core/` : rejeté
  pour cette phase — le brief demande explicitement de ne pas modifier le
  Core sans besoin réel documenté, et un seul thème (le Template) ne
  suffit pas à valider la bonne API d'un composant aussi central.
- Rendre les groupes de `NebulaThemeConfig` non `readonly` ou ajouter une
  méthode publique `applyValues()` sur `NebulaThemeConfig` : rejeté pour
  la même raison — modification du Core sans un second cas d'usage réel
  pour valider la forme de l'API.

### Raisons

Cohérent avec le principe du workspace (pas d'abstraction avant besoin
observé) : avec un seul consommateur (le Template), la duplication reste
petite (~15 lignes) et honnêtement documentée ; la promotion vers
`core/theme/NebulaThemeLoader.qml` devient justifiée dès qu'un deuxième
thème réel (Nord, Phase 2.1) en a besoin.

### Conséquences

Quand Nord (Phase 2.1) sera implémenté, si son `Main.qml` a besoin de la
même logique, c'est le signal explicite de promouvoir `applyFlatValues()`
en composant Core réel — voir `Roadmap.md`, Phase 1, item 3. Ne pas
dupliquer une troisième fois sans rouvrir cette décision.

### Résolution (Phase 2.0.5)

Résolu par anticipation, avant Nord plutôt qu'au moment où Nord en
aurait eu besoin : avec deux consommateurs réels déjà présents (le
Template et `tests/ThemeHarness.qml`) et Nord en approche immédiate, le
critère de duplication de cette décision était sur le point d'être
atteint de toute façon. `core/theme/NebulaThemeLoader.qml` créé,
absorbant `applyFlatValues()` — voir
[`ThemeLoader.md`](ThemeLoader.md). Aucune modification de l'API
publique du Core existante (`NebulaThemeConfig`/`NebulaThemeProvider`
inchangés) : seul un nouveau composant a été ajouté — l'alternative
rejetée ci-dessus (« rendre les groupes non `readonly` ») n'a pas été
nécessaire.

---

## DT-0018 — `NebulaThemeLoader` : fichier manquant/vide/lectures désactivées traité comme un échec

Date : 2026-07-31
État : accepté

### Contexte

`XMLHttpRequest` sur un `theme.conf` local ne permet pas de distinguer
un fichier introuvable, un fichier réellement vide, et
`QML_XHR_ALLOW_FILE_READ` non défini — les trois renvoient `status: 0`,
`responseText` vide (vérifié réellement, voir
[`Compatibility-Matrix.md`](Compatibility-Matrix.md) §5). Un choix devait
être fait sur le comportement de `NebulaThemeLoader` dans ce cas.

### Décision

Traiter les trois cas comme un échec de chargement (`loadError`
renseigné, `loaded: false`, `NebulaThemeConfig` garde entièrement ses
valeurs par défaut) plutôt que comme un thème valide à zéro token
personnalisé.

### Alternatives étudiées

- Traiter un résultat vide comme un succès silencieux (« thème sans
  aucune personnalisation ») : rejeté — masquerait un chemin mal
  orthographié ou un oubli de `QML_XHR_ALLOW_FILE_READ`, deux erreurs de
  configuration bien plus probables en pratique qu'un `theme.conf`
  intentionnellement vide.
- Ajouter une dépendance hors QML pur pour vérifier l'existence réelle du
  fichier avant la lecture : rejeté — disproportionné pour ce que ça
  résoudrait, et introduirait une dépendance système non justifiée par
  un besoin observé.

### Raisons

Un message d'erreur visible aide activement un auteur de thème à
diagnostiquer une faute de configuration ; un échec silencieux ne le
ferait pas (voir le principe « les messages doivent être utiles au
développeur d'un thème », `ThemeLoader.md` §4/brief Phase 2.0.5).

### Conséquences

Un thème avec un `theme.conf` volontairement vide (aucune
personnalisation) sera signalé comme en échec de chargement plutôt que
comme valide — limitation assumée et documentée
(`Nebula-Principles.md` §9), à revisiter seulement si ce cas d'usage
réel se présente.

---

## DT-0019 — `NebulaPowerService` étendu avec `canHibernate`/`hibernate()`

Date : 2026-07-31
État : accepté

### Contexte

Le brief de la Phase 2.3 demande à `NebulaPowerButtons` d'exposer une
action « veille prolongée » (hibernate). `NebulaPowerService` et
`SDDMPowerAdapter` (Phase 1.4) n'exposaient que
`canShutdown`/`canReboot`/`canSuspend` — aucune capacité hibernate.

### Décision

Ajouter `canHibernate` (bool, lecture seule) et `hibernate()` à
`NebulaPowerService`, `platform/sddm/SDDMPowerAdapter.qml` et
`tests/mocks/MockPowerAdapter.qml`, suivant exactement le même schéma
que les trois capacités existantes.

### Alternatives étudiées

- Ne pas exposer l'hibernation dans `NebulaPowerButtons` cette phase :
  rejeté — c'est une exigence explicite du brief, et
  `docs/Core-API.md` anticipait déjà `sddm.canHibernate`/
  `sddm.hibernate()` comme API SDDM réelle (confirmée par
  `Prototype-Results.md` §3.2) avant même que `NebulaPowerButtons`
  n'existe.

### Raisons

Extension additive, symétrique aux trois capacités déjà présentes —
ne remet en cause ni l'API publique existante ni l'architecture
Service/Adapter (cohérent avec le principe fondamental du brief Phase
2.3 : compléter le Core sans remettre en cause son architecture).

### Conséquences

`SDDMPowerAdapter.hibernate()` reste un squelette (`console.warn`), comme
les trois autres actions — le câblage réel vers `sddm.hibernate()` reste
un besoin futur déjà tracé (Phase 1.4 originale).

---

## DT-0020 — Pas de type Core dédié pour l'état d'authentification

Date : 2026-07-31
État : accepté

### Contexte

Le brief de la Phase 2.3 §6 demande un « modèle commun » d'états
Idle/Authenticating/Succeeded/Failed pour les composants d'authentification.

### Décision

Ne pas créer de nouveau type/enum Core. `NebulaPasswordField` reflète
directement l'état déjà exposé par `NebulaAuthService`
(`authenticating`, `errorMessage`) via ses propriétés `isBusy`/`hasError`
— pas de représentation d'état dupliquée.

### Alternatives étudiées

- Créer un type `NebulaAuthState` (enum ou objet) partagé : rejeté pour
  cette phase — un seul composant consomme cet état
  (`NebulaPasswordField`), aucun besoin réel d'abstraction partagée
  observé.

### Raisons

Cohérent avec le principe du workspace (pas d'abstraction avant besoin
observé). `NebulaAuthService` expose déjà tout l'état nécessaire ; le
« modèle commun » demandé par le brief est satisfait par convention
(chaque composant futur reflète l'état de son Service de la même façon),
pas par un nouveau type.

### Conséquences

Si un second composant a un jour besoin de représenter le même état
(ex. un futur indicateur de statut global), ce sera le signal
d'extraire un type partagé — cette décision devra alors être rouverte.

---

## DT-0021 — Phase 2.3 démarrée malgré la Phase 2.2 (Distribution) non terminée

Date : 2026-07-31
État : accepté

### Contexte

Le brief de la Phase 2.3 affirmait dans son contexte que « la
distribution de Nebula est désormais résolue (Phase 2.2) » — inexact :
Phase 2.2 (voir `Roadmap.md`) restait une sous-étape planifiée, jamais
commencée, après le Constat #1 de `Nord-Validation-Report.md` (un thème
installé séparément du dépôt ne peut pas charger le Core).

### Décision

Décision utilisateur explicite (2026-07-31) : démarrer la Phase 2.3
quand même. Le travail réel de cette phase (nouveaux composants Core,
testés via `qml6`/`LoginWorkflowHarness`/`sddm-greeter --test-mode`
depuis le dépôt) ne dépend pas techniquement de la distribution étant
résolue.

### Alternatives étudiées

- Traiter la Phase 2.2 d'abord : rejeté — aurait retardé sans raison
  technique un travail (nouveaux composants interactifs) totalement
  indépendant du problème de distribution.

### Raisons

Le problème de distribution affecte uniquement l'installation d'un
thème hors du dépôt — sans rapport avec l'ajout de composants au Core
lui-même, testables entièrement depuis le dépôt comme toutes les phases
précédentes.

### Conséquences

La Phase 2.2 reste ouverte et non affectée par ce choix — voir
`Roadmap.md`. La limitation déjà connue (adapters SDDM réels toujours
des squelettes) s'applique de la même façon qu'avant à ces nouveaux
composants — voir `Login-Architecture.md` §8.
