# Architecture Review — Nebula (Phase 0.6)

> Revue finale de cohérence documentaire avant démarrage du Core MVP.
> Analyse `Architecture.md`, `Design-System.md`, `Theme-System.md`,
> `Specifications-Techniques.md`, `Core-API.md`, `SDDM-Compatibility.md`,
> `Development-Environment.md`, `Roadmap.md`, `Decisions-Techniques.md`.
> Aucun code QML produit par cette phase.

---

## 1. Méthode

Lecture croisée de tous les documents ci-dessus, recherche de
contradictions, doublons, concepts manquants et décisions non
documentées. Les corrections identifiées ont été appliquées directement
dans les documents concernés (pas de backlog séparé) ; cette page en garde
la trace.

## 2. Points validés

- La séparation Core/Thème (Architecture.md §5.2, §6) est cohérente sur
  l'ensemble des documents : aucun document ne contredit le principe
  "un thème ne modifie jamais `core/`".
- Le flux de theming (`ThemeLoader → ThemeConfig → ThemeProvider →
  Components`, `Theme-System.md`) est cohérent avec DT-0006 et avec le
  Definition of Done de `Specifications-Techniques.md`.
- Le choix de Nord comme thème de référence (Roadmap Phase 2) reste
  cohérent avec l'absence de dépendance aux effets GPU dans le Core MVP.
- La convention de nommage `Nebula*` (DT-0004) est appliquée de façon
  cohérente dans `Core-API.md` et `Specifications-Techniques.md`, une fois
  les exemples obsolètes corrigés (voir §3).
- La matrice `SDDM-Compatibility.md` reste honnête : aucune ligne
  critique n'y est présentée comme acquise sans l'être réellement.

## 3. Points corrigés

### 3.1 `NebulaButton` non formalisé

**Contradiction trouvée** : DT-0002 utilisait déjà l'exemple
`ThemeButton extends NebulaButton` dès la première décision technique du
projet, et cette demande de Phase 0.6 exige `NebulaButton` comme
composant du Core MVP — mais `NebulaButton` n'a jamais été documenté comme
composant réel dans `Architecture.md` §5.3, `Specifications-Techniques.md`
ou `Core-API.md`.

**Corrigé** : `NebulaButton` ajouté comme composant à part entière
(Architecture.md §5.3, Specifications-Techniques.md, Core-API.md), avec
`NebulaPowerButtons` mis à jour pour le lister comme dépendance (chaque
action est un `NebulaButton` configuré). Ordre de construction du
Core MVP (`Roadmap.md`) mis à jour en conséquence.

### 3.2 Références résiduelles à `ThemeConfig` au lieu de `ThemeProvider`

**Contradiction trouvée** : `Specifications-Techniques.md` établit dans sa
section 1 et son Definition of Done qu'un composant ne doit jamais lire
`ThemeConfig`/`ThemeLoader` directement (DT-0006), mais les entrées
`NebulaClock`/`NebulaDate` et `NebulaAnimationManager` mentionnaient
encore "via `ThemeConfig`".

**Corrigé** : les deux entrées référencent maintenant
`NebulaThemeProvider`. Même correction appliquée à `CONTRIBUTING.md`
("named constants or `ThemeConfig` values" → tokens via
`NebulaThemeProvider`) et à son résumé du Definition of Done.

### 3.3 Exemples de nommage obsolètes (`NebulaConfig`, `NebulaTheme`)

**Contradiction trouvée** : DT-0004, `CONTRIBUTING.md` et `CLAUDE.md`
utilisaient encore `NebulaConfig` et `NebulaTheme` comme exemples de la
convention de nommage — deux noms qui ne correspondent à aucun composant
réel (les composants réels sont `NebulaThemeConfig` et
`NebulaThemeProvider`).

**Corrigé** : les trois fichiers référencent maintenant des noms réels
(`NebulaButton`, `NebulaClock`, `NebulaThemeConfig`, `NebulaThemeProvider`).

### 3.4 Frontière `ThemeProvider` incomplète

**Concept manquant** : `Theme-System.md` décrivait les responsabilités de
`ThemeLoader`/`ThemeConfig`/`ThemeProvider` mais ne définissait ni l'ordre
d'initialisation garanti, ni les valeurs par défaut en cas de token
manquant ou de thème mal formé — une question explicitement posée par
cette revue (voir §4 ci-dessous).

**Corrigé** : `Theme-System.md` enrichi avec deux nouvelles sections
(Ordre d'initialisation, Valeurs par défaut) plus un renvoi explicite pour
la gestion des erreurs.

### 3.5 Risque "permissions utilisateur sddm" non tracé

**Concept manquant** : le risque que le compte système `sddm` soit
restreint (accès fichiers, groupes GPU/audio, confinement
AppArmor/SELinux) n'apparaissait dans aucun document, alors qu'il touche
transversalement plusieurs lignes déjà "à vérifier" (Blur, vidéo, audio).

**Corrigé** : nouvelle ligne dans la matrice de `SDDM-Compatibility.md`.

### 3.6 Couleur du niveau de sévérité `info`

**Ambiguïté mineure** : `NebulaNotification` (Core-API.md) définit un
niveau de sévérité `info`, mais `Design-System.md` ne catalogue que
`errorColor`/`successColor`, pas d'équivalent pour `info`.

**Corrigé** : note ajoutée dans `Design-System.md` — `info` réutilise
`accentColor` par convention, plutôt que d'ajouter un token pour un seul
usage. À revoir si un second cas d'usage apparaît.

### 3.7 Double périmètre du "Core MVP"

**Incohérence potentielle** : la demande de Phase 0.6 propose un
`Core-MVP.md` listant seulement `NebulaClock`, `NebulaDate`,
`NebulaButton`, `NebulaAvatar` comme composants, alors que `Roadmap.md`
Phase 1 planifie déjà un périmètre plus large (`UserList`,
`PasswordField`, `SessionSelector`, `KeyboardSelector`, `PowerButtons`,
`Notification`, `Background`, `AnimationManager`). Créer `Core-MVP.md`
avec le périmètre restreint tel quel aurait introduit deux définitions
concurrentes du "MVP".

**Résolu** : `Core-MVP.md` reprend le périmètre complet déjà planifié dans
`Roadmap.md` (avec `NebulaButton` maintenant inclus), en distinguant
explicitement primitives simples (Clock, Date, Button, Avatar) et
composants d'intégration SDDM (UserList, PasswordField, SessionSelector,
KeyboardSelector, PowerButtons). Les deux documents restent alignés :
`Roadmap.md` reste la liste ordonnée de construction, `Core-MVP.md` en est
la vue par périmètre (quoi/pourquoi plutôt que dans quel ordre).

## 4. Frontière Core / Theme / ThemeProvider (confirmation explicite)

### Le Core peut connaître

- ses propres composants et leurs dépendances entre eux ;
- des animations génériques (paramétrées par tokens, jamais par identité
  de thème) ;
- le système de configuration (`ThemeConfig`/`ThemeLoader`/`ThemeProvider`) ;
- les tokens du [Design System](Design-System.md) ;
- des services internes (ex. résolution d'assets, gestion d'erreurs de
  chargement).

### Le Core ne doit jamais connaître

Aucun nom de thème concret : `cyberpunk`, `nord`, `amoled`, `glass`,
`hacker`, `hypr`. Une recherche du nom d'un thème dans `core/` (une fois
le code écrit) doit renvoyer zéro résultat — voir le principe déjà posé
dans `Core-API.md` §1 ("`if (themeName === "cyberpunk")` ou équivalent est
interdit").

### Un thème peut fournir

Couleurs, assets, wallpapers, paramètres visuels, variantes d'animation
(valeurs de tokens, jamais de nouveau moteur d'animation) — inchangé par
rapport à `Architecture.md` §5.2.

### Qui possède quoi (frontière ThemeProvider)

```text
Theme
 │
 ▼
NebulaThemeLoader     (chargement, résolution d'assets, repli sur erreur)
 │
 ▼
NebulaThemeConfig     (valeurs résolues, avec défauts garantis)
 │
 ▼
NebulaThemeProvider   (API stable exposée aux composants)
 │
 ▼
Core Components       (Clock, Button, Avatar, UserList, ...)
 │
 ▼
SDDM API              (utilisateurs, sessions, authentification, actions)
```

Détail de l'ordre d'initialisation, de la gestion des erreurs et des
valeurs par défaut : [`Theme-System.md`](Theme-System.md), sections 4 à 6
(ajoutées lors de cette revue).

## 5. Technical Risks

### SDDM

- Différences entre l'environnement de développement Plasma et
  l'environnement réel du greeter (bibliothèques disponibles, variables
  d'environnement) — voir `SDDM-Compatibility.md`.
- Permissions du compte système `sddm` (accès fichiers, groupes GPU/audio,
  confinement selon la distribution) — nouvelle ligne ajoutée à la
  matrice (§3.5 ci-dessus).
- Limitations QML propres au contexte greeter (modules disponibles,
  voir DT-0007) — non uniformes selon les distributions.

### GPU

- Disponibilité réelle de `ShaderEffect` dans le greeter — inconnue
  critique (`Architecture.md` §4, `SDDM-Compatibility.md`).
- Coût réel des animations et effets (Blur/Glow/Particles) sur matériel
  bas de gamme — mitigé par le token global `effects.enableEffects`
  (`Design-System.md`) qui doit permettre de tout désactiver d'un coup.
- Compatibilité matérielle hétérogène (GPU intégré vs dédié, pilotes
  libres vs propriétaires) — non testée à ce jour.

### Wayland

- Comportement multi-écran du greeter (une fenêtre par écran ou fenêtre
  partagée ?) — inconnue critique.
- HiDPI : géré par Qt6 en général, comportement spécifique au greeter non
  confirmé.
- Scaling : à tester conjointement avec le multi-écran, un cas peut
  cacher l'autre (ex. deux écrans à des échelles différentes).

**Mitigation commune à ces trois catégories** : aucun composant du
Core MVP (voir `Core-MVP.md`) ne doit dépendre d'une fonction encore "à
vérifier" dans `SDDM-Compatibility.md` sans plan de repli. C'est
exactement pourquoi les effets GPU (Blur/Glow/Particles) et le thème
Cyberpunk sont repoussés à la Phase 3 plutôt qu'inclus dans le Core MVP
ou le thème Nord.

## 6. Décisions non documentées identifiées

Aucune décision structurante non tracée n'a été trouvée en dehors des
points déjà couverts en §3. Deux clarifications mineures ont été traitées
comme de simples précisions de documentation plutôt que comme de
nouvelles décisions techniques (pas de nouveau DT créé) :

- l'ordre d'initialisation et les valeurs par défaut du theming
  (§3.4) sont une élaboration du contrat déjà accepté sous DT-0006, pas
  une nouvelle décision ;
- la couleur du niveau `info` (§3.6) est une convention locale à un seul
  composant, pas un choix structurant.

## 7. Statut de fin de Phase 0.6

À l'issue de cette revue :

- [x] Cohérence documentaire vérifiée, contradictions et doublons
      corrigés (§3)
- [x] Découpage Core/Theme et frontière ThemeProvider confirmés
      explicitement (§4)
- [x] Risques techniques consolidés (§5)
- [x] `docs/Core-MVP.md` créé
- [x] `docs/Nord-Theme-Specification.md` créé
- [x] Règle Core-vs-Theme ajoutée dans `CLAUDE.md`

Nebula dispose désormais d'une documentation suffisante pour qu'un
développeur externe puisse créer un nouveau composant Core, un nouveau
thème, ou une nouvelle configuration, sans ambiguïté et sans modifier
l'existant — condition de sortie de la Phase 0.6 (voir `Roadmap.md`).

Ce qui reste **hors du périmètre documentaire** et nécessite un test réel
avant la Phase 1 : les lignes "à vérifier" de `SDDM-Compatibility.md`
(voir `Architecture.md` §4, Inconnues critiques). Aucune quantité de
documentation supplémentaire ne peut lever ces inconnues — seul un
prototype sur une installation SDDM réelle le peut.
