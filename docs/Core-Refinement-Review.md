# Core Refinement Review — Nebula

> Rapport de la Phase 3.1 (voir `Roadmap.md`) : consolidation du Core
> avant l'entrée dans une phase pilotée par les thèmes (AMOLED,
> Hyprland, Cyberpunk, Hacker). Principe du brief : améliorer le Core
> **uniquement** à partir de besoins observés dans Nord/Glass, jamais
> par anticipation. Chaque section ci-dessous répond à une section du
> brief.

---

## 1. Revue des besoins réels

Tous les points « Le Core doit-il évoluer ? » soulevés par
`Nord-Validation-Report.md` et `Glass-Theme-Report.md`, classés :

| Besoin | Source | Catégorie | Traitement |
|---|---|---|---|
| Thème installé hors dépôt ne charge pas le Core | Nord Constat #1 | Amélioration des scripts | Déjà résolu Phase 2.2 (DT-0022) |
| Composants de connexion manquants (UserList/PasswordField/...) | Nord Constat #2 | Amélioration du Core | Déjà résolu Phase 2.3 |
| `ThemeInspector` sans traçabilité native de l'origine d'un token | Nord Constat #3 | Amélioration d'un outil de diagnostic (mineur) | Toujours non résolu par choix — aucune nouvelle évidence ne justifie de le reconsidérer cette phase |
| `NebulaPowerButtons`/`NebulaPasswordField` sans icônes personnalisables | Glass Constat #1 | Amélioration du Core | **Traité cette phase, voir §2** |
| `theme.conf` illisible sous le vrai `sddm.service` sans `GreeterEnvironment=` | Glass Constat #2 | Amélioration des scripts | Déjà résolu Phase 3.0 (DT-0023) |

Deux besoins supplémentaires, non signalés explicitement par un rapport
de validation mais trouvés en auditant le code réel pendant cette phase
(voir §4 et §6) :

| Besoin | Catégorie | Traitement |
|---|---|---|
| `KeyNavigation.tab` vers `NebulaPasswordField` ne focus pas le champ réellement saisissable | Amélioration du Core (bug réel) | **Corrigé cette phase, voir §6** |
| Libellés « Show »/« Hide »/« Shut Down »/... codés en dur, non localisables | Amélioration du Core | **Corrigé cette phase, voir §6** |

Aucun besoin classé « spécifique à un thème » n'a été identifié cette
phase — chaque limitation réelle rencontrée touchait potentiellement
plusieurs thèmes, jamais un seul.

---

## 2. Support officiel des icônes

**Besoin démontré** : Glass a généré 5 icônes cohérentes
(`shutdown`/`restart`/`suspend`/`hibernate`/`reveal-password`) qui
n'avaient nulle part où être câblées (`Glass-Theme-Report.md`,
Constat #1).

**API ajoutée** (documentée dans `Core-API.md` avant implémentation,
DT-0009) :

- `NebulaButton` avait déjà `icon` (url) depuis la Phase 1.1 — ajout de
  `iconSize` (real, défaut = taille du texte du label). **Pas de
  renommage en `iconSource`** (suggéré en exemple par le brief) : le nom
  `icon` est déjà établi et documenté depuis 4 phases, le renommer
  serait une rupture d'API non justifiée (voir §4, principe « aucune
  rupture d'API sans justification »).
- `NebulaPasswordField` : `showIcon`/`hideIcon` (url) — si l'un des deux
  est défini, remplace le texte du bouton bascule par une icône ;
  `iconSize` (même sémantique).
- `NebulaPowerButtons` : `shutdownIcon`/`rebootIcon`/`suspendIcon`/
  `hibernateIcon` (url), transmis tel quel au `icon` du `NebulaButton`
  interne correspondant ; `iconSize`.
- **Aucun composant n'impose une icône** : toutes les nouvelles
  propriétés sont vides par défaut, comportement visuel inchangé sans
  configuration explicite d'un thème (vérifié, voir §8).

**`iconColor` du brief délibérément non implémenté** : teinter une
image arbitraire sans shader n'est pas possible en QtQuick pur, et
`ShaderEffect`/`MultiEffect`/`Qt5Compat.GraphicalEffects` sont
explicitement interdits dans le Core (`Rendering-Guidelines.md` §2). Une
icône doit être fournie pré-colorée par le thème — déjà le choix fait
par le jeu d'icônes Glass (`#8E8E93`, lisible sur fond clair et sombre).
Documenté dans `Core-API.md` plutôt que contourné avec un effet
graphique interdit.

**Vérifié réellement** : icônes rendues correctement sur
`NebulaButton`/`NebulaPowerButtons` (capture d'écran, icônes Glass
existantes), taille personnalisée (`iconSize: 24`) appliquée
correctement, et le comportement par défaut (aucune icône fournie) reste
pixel-identique à avant (capture d'écran comparative). Le bouton bascule
de `NebulaPasswordField` n'a pas pu être vérifié visuellement avec une
icône affichée (le bouton bascule n'apparaît que si le champ contient du
texte, et cette session n'a aucun moyen de simuler une frappe clavier
réelle sur Wayland — voir §6/`Development-Journal.md`) ; sa logique est
structurellement identique au motif déjà vérifié de `NebulaButton`
(`Image` visible seulement si la source n'est pas vide), donc jugée
fiable par construction plutôt que par capture d'écran.

---

## 3. Harmonisation des états

Audit de toutes les propriétés de type état (`bool`/enum) à travers les
composants Core :

- `isCurrent` : utilisé de façon identique dans les délégués de
  `NebulaUserList` et `NebulaSessionSelector` — déjà cohérent.
- `authService.authenticating` (Service) vs
  `NebulaPasswordField.isBusy` (composant) : deux noms différents pour
  un concept lié, mais **délibérément pas le même concept** — `isBusy`
  est un vocabulaire générique au niveau du composant, découplé du nom
  spécifique au Service qu'il reflète par défaut (le composant pourrait
  en théorie refléter un état « occupé » sans lien avec l'authentification
  — voir DT-0020, qui avait déjà tranché contre un type d'état partagé).
  **Pas un problème à corriger** : créer une abstraction commune
  « Busy » ne répond à aucun besoin réel observé (le brief : « ne pas
  créer d'abstraction supplémentaire sans besoin réel »).
- `NebulaPowerButtons._pendingAction` (privé) n'a pas d'équivalent
  public « busy » — pas de collision, vocabulaire différent pour un
  concept différent (une confirmation en attente, pas un chargement).
- `hasError` (`NebulaPasswordField`) reflète `authService.errorMessage`
  — cohérent avec le principe déjà établi (les composants reflètent
  l'état du Service, jamais de duplication, voir DT-0020).

**Conclusion** : aucune incohérence de terminologie réelle trouvée qui
justifierait une nouvelle abstraction partagée. Le seul chevauchement
apparent (`authenticating`/`isBusy`) est un découplage intentionnel déjà
documenté (DT-0020), pas un oubli.

---

## 4. Revue des API publiques

Analyse de tous les composants Core (`docs/Core-API.md` §3) :

- **Noms de propriétés** : cohérents dans l'ensemble — `theme`
  (`NebulaThemeProvider`, requis, même nom partout),
  `model`/`currentIndex`/`currentUser`/`currentSession` (listes et
  sélection, même vocabulaire entre `NebulaUserList` et
  `NebulaSessionSelector`), `enabled` (propriété native `Item`, jamais
  redéfinie sous un autre nom).
- **Signaux** : tous au passé (`clicked`, `submitted`, `cleared`,
  `userSelected`, `sessionSelected`, `shutdownRequested`, `succeeded`,
  `failed`, `themeLoaded`, `sessionChanged`) — un événement signalé
  après qu'il s'est produit, jamais un verbe à l'impératif. Cohérent
  dans l'ensemble du Core, aucun changement nécessaire.
- **Valeurs par défaut** : chaque propriété texte/couleur/URL a une
  valeur par défaut sûre (chaîne vide, `false`, thème neutre) — aucun
  composant ne plante si un thème omet une propriété optionnelle,
  vérifié pour les nouvelles propriétés icône/libellé de cette phase
  (voir §8).
- **`icon` vs l'exemple `iconSource` du brief** (voir §2) : conservé tel
  quel — c'est le seul cas où le brief suggérait implicitement un nom
  différent d'une convention déjà établie ; renommer aurait été une
  rupture d'API non justifiée par un besoin réel.
- **Compatibilité future** : toutes les propriétés ajoutées cette phase
  sont optionnelles avec des valeurs par défaut reproduisant exactement
  le comportement précédent — aucune rupture d'API introduite (voir
  `API-Stability-Review.md`).

Aucune autre incohérence de nommage trouvée qui justifierait une
correction cette phase.

---

## 5. Réutilisation des animations

Comparaison réelle des `Main.qml` de chaque thème existant :

- **Nord** (`themes/nord/Main.qml`) : aucune animation — zéro
  `Behavior`/`Animation`, laissé aux défauts du Core (Phase 2.1,
  décision de portée explicite).
- **Template** (`themes/template/Main.qml`) : aucune animation non plus.
- **Glass** (`themes/glass-dark/Main.qml`, `glass-light/Main.qml`) :
  seul thème avec des animations propres (fondu+zoom à l'apparition,
  pulsation au changement d'utilisateur, tremblement à l'erreur de mot
  de passe) — mais les deux variantes partagent le **même fichier
  `Main.qml`** (copie volontaire, voir `Glass-Theme-Report.md`), donc
  ceci ne démontre pas une réutilisation entre thèmes *indépendants*,
  seulement entre deux variantes de couleur d'un seul thème.

**Conclusion, conforme au principe explicite du brief** (« ne rien
déplacer dans le Core tant que cette réutilisation n'est pas
démontrée ») : **aucune animation déplacée vers le Core cette phase**.
Un seul thème réel les utilise ; les déplacer maintenant serait une
généralisation anticipée, pas une réponse à un besoin observé. Les
animations déjà partagées par construction (bordure de focus, retour
visuel au clic — `NebulaButton`/`NebulaPasswordField`) le sont déjà
depuis leur création, pas un candidat de cette revue.

Motifs identifiés comme candidats pour une future
`NebulaAnimationManager` (déjà anticipée, voir le `TODO` dans
`NebulaButton.qml` et `Roadmap.md` Phase 3) — **non implémentés**, pour
référence si un second thème réel les réutilise un jour : fondu+zoom à
l'apparition/disparition d'une `NebulaSurface`, pulsation ponctuelle sur
sélection, tremblement ponctuel sur erreur (technique du « nudge »,
déjà documentée dans `Development-Journal.md`, Phase 2.0.5).

---

## 6. Accessibilité

Revue réelle, pas seulement documentaire :

### Navigation clavier / ordre de tabulation

- **Bug réel trouvé et corrigé** : `KeyNavigation.tab` ciblant
  `NebulaPasswordField` (un `Rectangle` simple, pas un `FocusScope`)
  laissait `activeFocus` sur le `Rectangle` racine plutôt que sur le
  `TextInput` interne réellement saisissable — vérifié avec un harnais
  jetable (`Window.activeFocusItem === passwordField`, `echoMode`
  `undefined` avant correctif). Corrigé par
  `activeFocusOnTab: true` + `onActiveFocusChanged: if (activeFocus)
  input.forceActiveFocus()`. Revérifié après correctif :
  `activeFocusItem` est désormais le `TextInput` interne (`echoMode`
  vaut `2`, une vraie valeur numérique de l'enum `TextInput.Password`).
  Ce bug touchait tout thème utilisant `NebulaPasswordField` (Glass,
  Template) — corrigé une seule fois au niveau Core, aucun changement
  requis côté thème.
- `NebulaButton`, `NebulaUserList`, `NebulaSessionSelector` n'ont pas ce
  problème : chacun gère directement ses propres `Keys.on*` sur sa
  racine, sans délégué interne à qui transférer le focus.
- **Chaîne de tabulation incomplète, pas un bug Core** : ni Glass ni
  Template ne définissent de `KeyNavigation.tab` entre le bouton Unlock
  et le contenu du pied de page (`NebulaSessionSelector`/
  `NebulaPowerButtons`) — Tab après Unlock retombe sur l'ordre par
  défaut de Qt Quick (ordre de création), pas un ordre explicite. Une
  limitation de câblage thème, pas un défaut du Core — chaque `NebulaButton`
  interne à `NebulaPowerButtons` reste individuellement focusable
  (`activeFocusOnTab: true`), donc aucun élément n'est totalement
  inaccessible au clavier, juste un ordre non garanti au-delà du bouton
  Unlock. Documenté ici plutôt que corrigé : câbler une chaîne complète
  est un choix de thème, pas une responsabilité du Core.

### Visibilité du focus

- Cohérente entre `NebulaButton` et `NebulaPasswordField` : bordure
  `theme.colors.accentColor` avec `theme.interaction.borderWidthFocus`
  sur `activeFocus`, déjà en place avant cette phase — vérifié visible
  réellement (captures d'écran Phase 3.0, harnais dédié).

### Contraste

Ratios de contraste réels calculés (formule WCAG 2.x, luminance relative
sRGB) sur les paires texte/fond effectivement utilisées :

| Thème | Paire | Ratio | Verdict WCAG AA |
|---|---|---|---|
| Nord | `textPrimary`/`surfaceColor` | 8.73:1 | Conforme (texte normal) |
| Nord | `textSecondary`/`surfaceColor` | 7.45:1 | Conforme (texte normal) |
| Nord | libellé bouton (`textPrimary`) / `primaryColor` | **1.74:1** | **Non conforme** |
| Glass Dark | `textPrimary`/`surfaceColor` | 13.94:1 | Conforme (texte normal) |
| Glass Dark | `textSecondary`/`surfaceColor` | 5.35:1 | Conforme (texte normal) |
| Glass Dark | libellé bouton (`textPrimary`) / `primaryColor` | 3.65:1 | Conforme texte large uniquement |
| Glass Light | `textPrimary`/`surfaceColor` | 16.83:1 | Conforme (texte normal) |
| Glass Light | `textSecondary`/`surfaceColor` | 5.07:1 | Conforme (texte normal) |
| Glass Light | libellé bouton (`textPrimary`) / `primaryColor` | 3.58:1 | Conforme texte large uniquement |

**Cause structurelle réelle** : `NebulaButton` utilise
`theme.colors.textPrimary` pour le libellé, quel que soit le `variant`
— aucun token dédié « texte sur couleur primaire » n'existe. Un thème
dont `primaryColor` est clair (Nord : `#88C0D0`) obtient un contraste
très faible avec un `textPrimary` clair, puisque le Core n'a aucun
moyen de savoir que la combinaison choisie par le thème est
insuffisante. Nord échoue franchement (1.74:1) ; Glass est à la limite
(3.6:1, tout juste conforme pour du texte large, pas pour le texte
normal habituel des libellés de bouton).

**Non corrigé cette phase** — un vrai correctif demanderait un nouveau
token (ex. `colors.textOnPrimary`), une extension de
`NebulaThemeConfig` documentée avant implémentation (DT-0009), et une
mise à jour coordonnée des 4 `theme.conf` existants (Nord, Glass Dark,
Glass Light, Template) avec des valeurs réellement vérifiées — portée
plus large qu'un correctif de cette revue. Documenté ici comme besoin
réel et mesuré, candidat pour une future phase dédiée aux Design
Tokens.

### HiDPI / multi-écran

Déjà validés réellement pour Glass en Phase 3.0 (100/125/150/200 %, 3
écrans réels) — non re-testés spécifiquement pour l'accessibilité cette
phase au-delà de la vérification de compatibilité générale (§8), aucune
régression attendue ni observée (aucune propriété liée au layout n'a
changé cette phase, uniquement des propriétés icône/libellé
optionnelles).

### Localisation

**Besoin réel trouvé** : 6 chaînes utilisateur codées en dur dans le
Core, sans mécanisme de traduction (`qsTr` absent de tout `core/`) —
`"Show"`/`"Hide"` (`NebulaPasswordField`), `"Shut Down"`/`"Restart"`/
`"Sleep"`/`"Hibernate"`/`"Confirm?"` (`NebulaPowerButtons`). Corrigé
cette phase, portée volontairement limitée : ces chaînes sont désormais
des propriétés (`showLabel`/`hideLabel`, `shutdownLabel`/.../
`confirmLabel`) qu'un thème peut surcharger, avec les mêmes valeurs par
défaut qu'avant — **pas** une infrastructure `qsTr`/fichiers de
traduction complète, qui exigerait une stratégie de détection de locale
non demandée par ce brief et non justifiée par un besoin observé au-delà
de « ces six chaînes sont actuellement impossibles à changer sans forker
le Core ».

---

## 7. Performances (Nord vs Glass)

Voir `Glass-Theme-Report.md` pour la méthodologie complète et les
chiffres de référence (Phase 3.0, non refaits en intégralité cette
phase — pas de changement structurel de layout cette phase, seulement
des propriétés optionnelles).

Impact des changements de cette phase sur le nombre d'objets QML :

- `NebulaButton` : aucun nouvel objet visuel (l'`Image` existait déjà
  depuis la Phase 1.1) — seulement une nouvelle propriété (`iconSize`).
- `NebulaPasswordField` : **+1 objet** par instance (`Image` du bouton
  bascule, désormais toujours instanciée à côté du `Text` existant,
  visible seulement si `showIcon`/`hideIcon` est défini) — négligeable
  (Glass passe d'environ 131 à 132 objets QML, voir
  `Glass-Theme-Report.md`).
- `NebulaPowerButtons` : aucun nouvel objet (chaque `NebulaButton`
  interne avait déjà son `Image`) — seulement de nouvelles propriétés.

Aucune optimisation du Core identifiée comme nécessaire cette phase —
les chiffres Phase 3.0 (Nord ~51 objets/2 timers continus, Glass ~131
objets/2 timers continus, mémoire résidente +~10 Mo) restent la
référence valide, l'écart étant entièrement dû à l'ensemble
fonctionnel plus large de Glass, pas à un coût par composant.

---

## 8. Compatibilité

Voir `Development-Journal.md` pour le détail des tests réels. Résumé :
Nord, Glass Dark, Glass Light et Template testés après les changements
de cette phase (`qmllint`, chargement `qml6`, `sddm-greeter
--test-mode`) — tous fonctionnent sans aucune modification de leur
`Main.qml`/`theme.conf`, confirmant que les nouvelles propriétés
(icônes, libellés) sont réellement optionnelles et rétrocompatibles.

---

## Conclusion

Le Core est stabilisé pour la portée révisée cette phase : les deux
besoins réels démontrés par Glass (icônes, focus clavier de
`NebulaPasswordField`) sont traités ; un besoin de localisation trouvé
en auditant le code (pas signalé par un rapport de validation
antérieur) est traité avec une portée délibérément minimale ; un besoin
de contraste réel et mesuré est documenté mais pas corrigé (portée trop
large pour cette revue, nécessite un nouveau Design Token) ; aucune
animation n'a été déplacée vers le Core faute de réutilisation
démontrée entre thèmes indépendants ; aucune incohérence de
terminologie d'état ne justifiait de nouvelle abstraction. Voir
`API-Stability-Review.md` pour le statut de stabilité de chaque API
publique du Core à l'issue de cette phase.
