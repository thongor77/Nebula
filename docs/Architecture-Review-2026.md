# Technical Architecture Review 01 — Nebula (2026-08-03)

> Revue de qualité technique du code existant (Core / Services / Platform
> / Scripts), demandée une fois les briques principales en place
> (Components, Services, Adapters, SDK, ThemeLoader, Installation,
> Documentation, Thèmes officiels, validation réelle sous SDDM). Aucune
> nouvelle fonctionnalité, aucune modification architecturale — l'objectif
> est de déterminer ce qui est excellent, ce qui mérite d'être amélioré,
> et ce qu'il vaut mieux ne plus toucher. Aucune modification de code
> n'a été faite pendant cette revue (lecture seule).
>
> Méthode : lecture intégrale de `core/components/` (14 fichiers),
> `core/services/` (4), `platform/sddm/` (4 adapters + 4 mocks),
> `core/theme/`+`core/config/`+`core/layouts/` (4), `scripts/` (5),
> ainsi que `docs/Core-API.md` et `docs/API-Stability-Review.md` pour le
> croisement avec le contrat documenté.

---

## 1. Core Components

14 composants (`core/components/`). Tous suivent une convention stricte
et jamais violée : `required property NebulaThemeProvider theme` injecté
explicitement (aucun singleton global), aucune couleur/police/espacement
codé en dur, aucun appel à `sddm.*` (les composants interactifs passent
uniquement par un Service requis). Cohérence de nommage des signaux
(`xRequested`/`xSelected`/`submitted`/`cleared`) et des props
(`theme`, `<domain>Service`) sans exception.

Duplication de logique réelle identifiée :

- **Bloc de style de texte répété tel quel** dans au moins 6 composants
  (`NebulaButton`, `NebulaClock`, `NebulaDate`, `NebulaPasswordField`,
  `NebulaSessionSelector`, `NebulaUserList`) :
  ```qml
  color: theme.colors.textPrimary/textSecondary
  font.family: theme.typography.fontFamilyPrimary
  font.pixelSize: theme.typography.fontSizeBody
  font.weight: theme.typography.fontWeightNormal
  ```
  Candidat réel à factorisation (voir Recommandations).
- **Garde de bornes `index < 0 || index >= length`** dupliquée entre
  `NebulaUserList.selectIndex()` et `NebulaSessionSelector.selectIndex()`
  (2 lignes, 2 occurrences) — sous le seuil qui justifierait une
  abstraction dédiée ; classé "vu, non actionnable" plutôt que dette.
- **Navigation clavier `Keys.onLeftPressed`/`onRightPressed`** identique
  entre les deux mêmes composants — même remarque.
- `NebulaPasswordField` réimplémente manuellement un mini bouton
  icône-ou-texte pour son bascule afficher/masquer, au lieu de composer
  `NebulaButton` (qui fait déjà exactement ça, variant `ghost`).
  Fonctionne correctement ; duplication mineure de structure (Image +
  Text + MouseArea), pas de bug.
- `NebulaPowerButtons` répète le même bloc `NebulaButton { ... onClicked:
  root._trigger(...) }` quatre fois avec des liaisons différentes. Le
  cœur de la logique (confirmation en deux clics) est déjà factorisé
  dans `_trigger()` — la répétition restante est la déclaration de
  quatre actions à sémantique réellement différente (icône, variant,
  signal, capacité), pas un pur copier-coller. Une version pilotée par
  un tableau de données apporterait peu pour exactement 4 actions fixes.

Points de cohérence remarquables (voir §"Points excellents") :
`NebulaBackground` (11 lignes, une seule responsabilité : conteneur
racine pur), `NebulaSurface`/`NebulaOverlay` (aucune connaissance
d'identité de thème), séparation stricte entre composants "self-managed
state" (`NebulaUserList.currentIndex` local) et composants "state
delegated to a Service" (`NebulaSessionSelector.currentIndex` lu depuis
`sessionService.currentIndex`) — voir §2 pour pourquoi cette différence
est justifiée, pas une incohérence.

## 2. Core Services

4 Services (`core/services/`), tous `QtObject`, tous suivent le même
patron : `property var adapter: null` + propriétés `readonly` en garde
`adapter ? adapter.X : <défaut>`. Chaque Service ne fait qu'une seule
chose — confirmé : Auth authentifie, Power agit sur l'alimentation,
Session lit/sélectionne une session, User lit/rafraîchit des
utilisateurs. Aucun Service ne dépasse son périmètre.

Constat structurel, pas une incohérence : `NebulaSessionService` porte
l'état "sélection courante" (`currentIndex` + `selectSession()`) côté
Service/Adapter, alors que `NebulaUserService` n'a pas d'équivalent — la
sélection dans `NebulaUserList` reste purement locale au composant
visuel, jamais remontée au Service. Vérifié dans les quatre thèmes
(`grep` sur `Main.qml`) : c'est un choix cohérent, pas un oubli — le nom
d'utilisateur sélectionné dans l'UI est câblé directement de
`userList.currentUser.name` vers `passwordField.username` par chaque
thème multi-utilisateur, tandis que `userService.currentUser` sert un
autre besoin (le thème `nord`, mono-utilisateur, sans `NebulaUserList`,
lit `userService.currentUser` directement). Les deux mécanismes
coexistent proprement. À documenter explicitement quelque part (voir
Recommandations) pour qu'un futur contributeur ne le prenne pas pour un
oubli.

Petite asymétrie mineure : `NebulaAuthService.cancel()` vérifie
`adapter.cancel` avant d'appeler (duck-typing défensif), `authenticate()`
ne fait pas la même vérification sur `adapter.login`. Cohérent avec le
fait qu'aucun adapter réel n'omet `login` (c'est la méthode centrale du
contrat), mais l'asymétrie existe. Sévérité négligeable.

`NebulaAuthService` est le seul des quatre à avoir besoin de la
connexion impérative (`onAdapterChanged: adapter.loginResult.connect(...)`)
au lieu d'une lecture directe de propriété — justifié : c'est le seul
Service avec un round-trip asynchrone (PAM réel), les trois autres sont
synchrones. Pas une incohérence.

## 3. Platform Adapters (`platform/sddm/`)

Duplication structurelle réelle et significative : `SDDMSessionAdapter`
et `SDDMUserAdapter` implémentent chacun, presque à l'identique
(~20 lignes), le même patron « matérialiser un `QAbstractItemModel` SDDM
(`sessionModel`/`userModel`) en tableau JS via un `Instantiator`
interne » :

```qml
Instantiator {
    model: xModel
    delegate: QtObject { readonly property ... : model.<role> }
    onObjectAdded: (index, object) => { var list = root.x.slice(); list[index] = {...}; root.x = list }
    onObjectRemoved: (index, object) => { var list = root.x.slice(); list.splice(index, 1); root.x = list }
}
```
Seuls les noms de rôles extraits et le tableau cible diffèrent. C'est une
vraie candidate à factorisation (voir Recommandations) — mais avec
seulement deux occurrences aujourd'hui, l'abstraire maintenant serait au
prix d'une indirection (par ex. un type interne générique paramétré par
une fonction de mapping) pour un gain modeste. Signalé comme opportunité
réelle, pas comme urgence.

Robustesse : aucun des quatre adapters ne fait de garde défensive sur
`sddm`/`sessionModel`/`userModel` avant utilisation — assumé toujours
présent, avec justification explicite en commentaire ("ces adapters ne
sont instanciés que par le `Main.qml` d'un thème, lui-même seulement
exécuté via `sddm-greeter`"). C'est cohérent avec le principe du projet
de ne valider qu'aux frontières réelles, pas un défaut de robustesse.

`SDDMAuthAdapter.cancel()` est un no-op documenté (aucune API SDDM réelle
pour annuler un `sddm.login()` en vol) — limitation réelle, correctement
documentée, pas un bug.

**Trouvaille indépendante de "ne rien modifier" mais à signaler** :
l'en-tête de `platform/sddm/SDDMAuthAdapter.qml` affirme encore
*"NOT YET VERIFIED under the real sddm.service"* (lignes 30-35). C'est
devenu faux — le round-trip réel a été validé le 2026-08-03
(`docs/Real-Adapter-Validation.md`, déjà répercuté dans
`platform/sddm/README.md` lors de la précédente passe de synchronisation
documentaire). Le fichier `.qml` lui-même n'avait pas été couvert par
cette passe (le mot-clé cherché était "validated", le commentaire utilise
"verified"). Aucune correction faite ici — cette revue est en lecture
seule — mais c'est une correction évidente et à faible risque pour une
prochaine passe (une seule chaîne de commentaire, aucune logique).

Ordre d'initialisation vérifié sur `SDDMSessionAdapter`/`SDDMUserAdapter` :
`currentIndex`/`_currentIndex` est fixé dans `Component.onCompleted`
indépendamment du moment où l'`Instantiator` peuple `sessions`/`users` —
pas de risque de course, les bindings QML re-déclenchent proprement les
consommateurs quand le tableau se peuple ensuite.

**Mocks vs adapters réels** (`tests/mocks/`) : `MockAuthAdapter.login()`
n'a que deux paramètres (`username`, `password`), alors que le contrat
réel attend un troisième (`sessionIndex`, voir
`NebulaAuthService.authenticate()` et `SDDMAuthAdapter.login()`). JS
ignore silencieusement l'argument surnuméraire, donc aucun bug visible —
mais le mock n'exerce jamais le chemin `sessionIndex`, ce qui pourrait
laisser passer une régression sur ce paramètre sans qu'aucun harnais ne
la détecte. Classé dette mineure (§ Dette technique).

## 4. Virtual Keyboard (`NebulaVirtualKeyboard` / `NebulaInputPanel`)

Séparation des responsabilités jugée exemplaire : `NebulaVirtualKeyboard`
(composant public, état/animation/dimensionnement, API minimale —
`available`, `keyboardActive`, `reservedHeight`, `show()`/`hide()`/
`toggle()`) charge en interne, via un `Loader`, `NebulaInputPanel`
(composant non public, seul point de contact avec
`QtQuick.VirtualKeyboard.InputPanel`) — explicitement documenté comme tel
dans `Core-API.md` §4. Aucune fuite de l'API Qt Virtual Keyboard vers le
contrat public.

Le découplage `keyboardActive` (piloté par `root.state`, synchrone) vs
`loader.item.active` (qui dépend aussi de `InputMethod.visible`,
asynchrone) est un cas réel de correction de bug documentée en
commentaire — la course trouvée pendant la validation VK-001 est
expliquée avec précision (pas seulement "corrigé", mais pourquoi le
binding naïf aurait été faux). C'est le niveau de commentaire que ce
projet maintient systématiquement bien.

Dépendances : uniquement `NebulaThemeProvider` (tokens d'animation) —
aucune dépendance inutile. Comportement réellement générique : le
composant se dégrade proprement (`available: false`) sans
`qt6-virtualkeyboard` installé, sans jamais planter le chargement du
thème. Rien à améliorer identifié ici.

## 5. Theme Loader / Provider / Config

Les trois fichiers (`NebulaThemeLoader`, `NebulaThemeProvider`,
`NebulaThemeConfig`) respectent une séparation propre et non dupliquée :
Config porte les valeurs, Provider expose un contrat stable aux
composants, Loader est le seul point d'écriture dans Config. Aucune
logique dupliquée entre les trois.

`NebulaThemeLoader._applyFlatValues()` fait deux passes sur les mêmes
groupes de tokens (une pour appliquer/valider, une seconde pour
constituer `allTokenNames` et détecter les clés inconnues de
`theme.conf`). C'est une petite duplication d'itération, pas un problème
de performance réel — `theme.conf` est minuscule et n'est lu qu'une
fois au chargement (ou lors d'un `reload()` manuel explicite), jamais
sur un chemin chaud. Fusionnable en une seule passe pour la lisibilité ;
sans urgence.

**Commentaire devenu obsolète (logique historique)**, trouvé en Part 5 —
même remarque que pour `SDDMAuthAdapter` (lecture seule, non corrigé
ici) : `NebulaThemeProvider.qml` ligne 12 dit encore *"Until
NebulaThemeLoader exists (see docs/Roadmap.md, Phase 1), this *is* the
fallback"*, comme si `NebulaThemeLoader` n'existait pas encore. Il existe
depuis la Phase 2.0.5 et c'est précisément la même propriété `config`
que chaque thème réel réassigne (`config: root.themeLoader.config`,
vérifié dans les quatre `Main.qml`) — le commentaire décrit une réalité
antérieure à l'implémentation du Loader et n'a jamais été mis à jour
après coup. Il induit en erreur un lecteur qui ne connaîtrait pas
l'historique. Même remarque, à un degré moindre, pour le commentaire
"deferred until NebulaThemeLoader exists" sur `assets` juste en dessous
— le fait (groupe `assets` vide) reste vrai, mais la raison invoquée ne
l'est plus (le Loader existe, il ne peuple simplement aucun groupe
`assets`, faute d'un tel groupe dans `NebulaThemeConfig`).

`NebulaThemeConfig.valid` reste une vérification minimale par
conception (pas un validateur de schéma complet) — cohérent avec le
principe du projet de ne pas construire d'abstraction sans besoin
observé. Bon exemple de retenue.

`NebulaLoginLayout` : la géométrie (quatre zones, `_contentWidth`
partagé, `_clampedBottomInset`) est dense mais chaque décision non
triviale porte un commentaire expliquant un bug réel trouvé en la
testant (boucle de binding Phase 1.3, asymétrie de centrage trouvée
pendant la validation VK-001 sur écran à faible hauteur). Aucune
duplication trouvée dans ce fichier.

Les `Behavior on <property>` liés à l'animation (`NebulaButton.scale`,
`NebulaButton.color`, `NebulaPasswordField.border.color`,
`NebulaLoginLayout.mainArea.y`, `NebulaLoginLayout.footerArea.
anchors.bottomMargin`, `NebulaVirtualKeyboard`'s `NumberAnimation`) sont
tous écrits à la main, chacun référençant individuellement
`theme.animation.durationFast/durationNormal`. C'est la duplication
explicitement anticipée par le `TODO(Phase 3+)` déjà présent dans
`NebulaButton.qml` (`NebulaAnimationManager`, jamais commencé). Rien à
faire maintenant — construire cette abstraction avant qu'un second cas
d'usage la justifie irait à l'encontre du principe du projet.

## 6. Scripts (`scripts/`)

5 scripts Bash, tous avec `set -euo pipefail` sauf `check-installation.sh`
(`set -uo pipefail`, sans `-e`) — **différence délibérée et correcte**,
pas une incohérence : c'est le seul script "vérificateur" qui doit
accumuler toutes les erreurs trouvées plutôt que s'arrêter à la première
(modèle `fail()`/`errors=$((errors + 1))`), alors que les scripts
"acteurs" (`install-`, `uninstall-`, `check-theme.sh`) doivent
s'arrêter immédiatement sur la première anomalie avant de modifier quoi
que ce soit sur le système. Bon exemple de choix de robustesse
différencié à bon escient.

Duplication réelle, avec un vrai seuil de récurrence :

- **Localisation de `qmake6`/`qmake`** : le même idiome
  (`command -v qmake6 || command -v qmake || true`, puis vérification
  d'échec, puis `qmake6 -query QT_INSTALL_QML`) apparaît **à l'identique
  dans trois scripts** (`install-nebula.sh`, `uninstall-nebula.sh`,
  `check-installation.sh`). C'est la duplication la mieux justifiée de
  toute la revue (seuil de 3 occurrences franchi, logique strictement
  identique à chaque fois) — bon candidat pour une fonction partagée
  (`scripts/lib/common.sh`, source par les trois).
- **`fail()`** (compteur d'erreurs + message `stderr`) redéfini
  séparément dans `check-installation.sh` et `check-theme.sh` — 2
  occurrences, logique identique à 1 ligne près. Sous le seuil de 3,
  mais irait naturellement dans le même fichier partagé si celui-ci
  était créé pour la raison ci-dessus.
- Garde `EUID -ne 0` dupliquée entre `install-nebula.sh` et
  `uninstall-nebula.sh` — 2 occurrences, identiques.

Messages utilisateur : systématiquement clairs, expliquent la cause
probable et redirigent vers la documentation pertinente
(`docs/Development-Environment.md`, `DT-0023`, etc.) plutôt que de se
limiter à un code d'erreur brut — qualité au-dessus de la moyenne pour
des scripts d'installation.

`check-theme.sh` extrait dynamiquement la liste des tokens connus
directement depuis `core/config/NebulaThemeConfig.qml` (`grep -oP`)
plutôt que de maintenir une liste séparée à la main — source de vérité
unique, ne peut pas dériver silencieusement. Bonne pratique à souligner.

## 7. Performance

Aucune allocation ni binding coûteux identifié sur un chemin exécuté
fréquemment. Deux Timers permanents recensés (`NebulaClock`, 1/s ;
`NebulaDate`, 1/min) — déjà comptabilisés et jugés acceptables dans
`docs/Rendering-Guidelines.md` §6 ; rien de nouveau trouvé ici. Le seul
autre Timer (`NebulaPowerButtons.confirmResetTimer`) est à un coup, actif
uniquement pendant une confirmation en attente — pas permanent.

`NebulaThemeLoader._applyFlatValues()` (double passe, voir §5) n'a aucun
impact mesurable : exécuté une fois par thème chargé, sur un fichier de
quelques dizaines de lignes.

Connexions de signal : chaque `adapter` (`NebulaAuthService.adapter`,
etc.) est assigné une seule fois de façon déclarative dans chaque
`Main.qml` réel (vérifié par `grep` sur les quatre thèmes) et jamais
réaffecté à l'exécution — le risque théorique de connexions empilées si
`adapter` changeait plusieurs fois (aucun `.disconnect()` avant un
nouveau `.connect()` dans `NebulaAuthService.onAdapterChanged`) ne se
matérialise donc jamais en pratique aujourd'hui. Noté comme filet de
sécurité manquant, sévérité négligeable tant qu'aucun thème ne
réaffecte `adapter` dynamiquement (voir Dette technique, Mineure).

Aucune optimisation n'est proposée ici faute d'un cas mesurable — cohérent
avec la consigne de ne proposer que des optimisations réellement
mesurables.

## 8. API Stability

`docs/Core-API.md` et `docs/API-Stability-Review.md` sont déjà rigoureux
et à jour sur l'essentiel. Un point concret mérite une reconfirmation :
`API-Stability-Review.md` §2 classe encore `NebulaVirtualKeyboard` et
`NebulaLoginLayout.bottomInset` comme "non encore stables" au motif
qu'ils n'auraient été exercés que par "une seule validation réelle". Or
`docs/Roadmap.md` documente depuis une validation réelle ultérieure
(2026-08-03, `docs/Investigations/VK-001-VirtualKeyboard.md` §Validation
réelle) sur les **trois** thèmes concernés (`template`, `glass-dark`,
`glass-light`) sous le vrai `sddm.service`, avec le clampage
(`_clampedBottomInset`) explicitement confirmé sans chevauchement sur
les trois écrans réels de la machine. Cela satisfait le même critère
("≥ 2 thèmes réels indépendants, aucun ajustement nécessaire") déjà
utilisé pour promouvoir les autres entrées du §1. Recommandation :
reconfirmer et déplacer ces deux entrées du §2 au §1 lors d'une
prochaine passe documentaire (pas faite ici, cette revue étant en
lecture seule) — voir aussi Recommandations.

Le reste du contrat public est cohérent : noms de propriétés stables
(`theme`, `<domain>Service`), valeurs par défaut toujours non cassantes
sur les ajouts de la Phase 3.1 (icônes, libellés), aucune dépréciation
en attente. Rien d'autre à signaler au-delà de ce qui est déjà consigné
dans ces deux documents.

## 9. Dette technique — synthèse

### Critique

*(aucune)* — aucun élément trouvé pendant cette revue ne bloque, ne
casse une garantie du Core, ni ne représente un risque de sécurité ou de
perte de données.

### Importante

- **Duplication `Instantiator` + matérialisation de modèle** entre
  `SDDMSessionAdapter` et `SDDMUserAdapter` (§3) — code réellement
  dupliqué (~20 lignes quasi identiques ×2), impacte la maintenabilité
  si un troisième adapter de ce type apparaît un jour (ex. un futur
  adapter de disposition clavier). Impact : maintenabilité seulement,
  aucun bug fonctionnel actuel.
- **Duplication de localisation `qmake6`** dans 3 scripts Bash (§6) —
  seuil de 3 occurrences franchi, la même logique devrait vivre à un
  seul endroit. Impact : maintenabilité — un changement de stratégie de
  détection (ex. nouvelle distribution) demande aujourd'hui 3 correctifs
  identiques.

### Mineure

- Commentaire obsolète dans `platform/sddm/SDDMAuthAdapter.qml`
  ("NOT YET VERIFIED", §3) — cosmétique, mais trompeur pour un futur
  lecteur.
- Commentaires obsolètes dans `core/theme/NebulaThemeProvider.qml`
  référençant un `NebulaThemeLoader` "pas encore existant" (§5) —
  même nature.
- `MockAuthAdapter.login()` n'exerce pas le paramètre `sessionIndex`
  (§3) — angle mort de test, pas un bug en production.
- Bloc de style de texte répété dans ≥ 6 composants (§1) — lisibilité,
  aucun risque fonctionnel.
- Duplication `fail()` (2 scripts) et garde `EUID` (2 scripts) sous le
  seuil de 3, à regrouper seulement si `scripts/lib/common.sh` est créé
  pour la raison ci-dessus (Importante).
- Absence de `.disconnect()` avant reconnection dans
  `NebulaAuthService.onAdapterChanged` (§7) — filet de sécurité manquant,
  jamais déclenché par l'usage actuel.
- `API-Stability-Review.md` §2 en retard d'une validation réelle pour
  `NebulaVirtualKeyboard`/`NebulaLoginLayout.bottomInset` (§8).

## 10. Opportunités (qualité, pas des bugs)

- Un composant `NebulaLabel` (ou un attaché "themed text" minimal)
  absorbant le bloc `color`/`font.family`/`font.pixelSize`/`font.weight`
  répété dans ≥ 6 composants (§1) réduirait la duplication la plus
  visible du Core sans changer la moindre API publique existante
  (purement interne à chaque composant).
- Un `scripts/lib/common.sh` sourcé par `install-nebula.sh`,
  `uninstall-nebula.sh` et `check-installation.sh` pour la détection
  `qmake6`/`QT_INSTALL_QML`, et par extension `fail()`/`pass()` pour les
  deux scripts vérificateurs.
- Documenter explicitement (par ex. dans `docs/Login-Architecture.md`)
  la distinction entre `NebulaUserService.currentUser` (utilisateur par
  défaut fourni par SDDM, consommé tel quel par les thèmes mono-
  utilisateur comme Nord) et la sélection locale de
  `NebulaUserList.currentIndex` (jamais remontée au Service, consommée
  directement par les thèmes multi-utilisateurs) — actuellement correct
  dans le code mais nulle part écrit noir sur blanc, ce qui l'expose à
  être "corrigé" par erreur plus tard.
- Renommage : aucun candidat identifié — les conventions actuelles
  (`Nebula*` pour le Core, adapters non préfixés, signaux `xRequested`/
  `xSelected`) sont déjà cohérentes sur l'ensemble du code lu.

---

## Points excellents

- **Injection de dépendance explicite et sans exception** : les 14
  composants du Core reçoivent leur `NebulaThemeProvider` (et, pour les
  composants interactifs, leur Service) via une `required property`,
  jamais un singleton global. Zéro exception trouvée en lisant
  l'intégralité de `core/components/`.
- **Séparation Service ↔ Adapter ↔ Composant** appliquée sans
  compromis : aucun composant Core ne touche `sddm.*`, confirmé fichier
  par fichier — le seul point de contact réel avec SDDM est
  `platform/sddm/`, exactement comme documenté.
- **Qualité et honnêteté des commentaires** : chaque décision non
  évidente (pourquoi `Item` plutôt que `QtObject`, pourquoi une valeur
  reste volontairement non tokenisée, pourquoi tel binding a provoqué
  une boucle) est expliquée avec le bug réel qui l'a motivée, pas
  seulement affirmée. `NebulaLoginLayout` et `NebulaVirtualKeyboard`
  sont les meilleurs exemples de cette pratique.
- **`NebulaThemeLoader`** : gestion soigneuse d'un cas ambigu réel
  (fichier vide/absent/lecture désactivée indistinguables sous
  `XMLHttpRequest` local), jamais de crash, toujours un repli sur la
  valeur par défaut du Core avec un message explicite.
- **Scripts Bash** : différenciation correcte entre `set -euo pipefail`
  (scripts qui modifient le système, doivent s'arrêter net) et
  `set -uo pipefail` (script vérificateur, doit tout vérifier avant de
  conclure) — un choix de robustesse réfléchi, pas un `set` copié-collé
  partout par habitude.
- **`check-theme.sh`** dérive sa liste de tokens connus directement du
  code source (`NebulaThemeConfig.qml`) plutôt que de la dupliquer à la
  main — ne peut pas dériver silencieusement.
- **Restraint architectural constant** : `NebulaThemeConfig.valid` reste
  une vérification minimale, `NebulaBackground` reste 11 lignes,
  `core/effects`/`core/animations` restent vides plutôt que peuplés par
  anticipation — le principe "pas d'abstraction avant besoin réel" est
  appliqué de façon mesurable dans le code, pas seulement énoncé dans
  `CLAUDE.md`.

## Points perfectibles

- Duplication du bloc de style de texte (§1, §10).
- Duplication `Instantiator`/matérialisation de modèle entre les deux
  adapters SDDM à base de liste (§3, §9).
- Duplication de détection `qmake6` dans 3 scripts (§6, §9).
- Quatre commentaires devenus obsolètes après coup, jamais mis à jour
  (`SDDMAuthAdapter.qml`, `NebulaThemeProvider.qml` ×2,
  `API-Stability-Review.md` §2) — aucun n'est une erreur de conception,
  tous sont des traces d'une évolution réelle du projet non répercutée
  dans un commentaire ou un document écrit avant cette évolution.
- Asymétrie non documentée entre le modèle de sélection de
  `NebulaSessionService` (état côté Service) et `NebulaUserList` (état
  local au composant) — correcte dans les faits, pas expliquée nulle
  part (§2, §10).

## Dette technique

Voir §9 ci-dessus (Critique / Importante / Mineure) pour le détail
classé et argumenté.

## Recommandations

Par ordre de valeur/effort décroissant :

1. Créer `scripts/lib/common.sh` (détection `qmake6`/`QT_INSTALL_QML`,
   `fail()`/`pass()`) et le faire sourcer par les 3-4 scripts concernés
   — la duplication la mieux justifiée de toute la revue (seuil de 3
   franchi, logique strictement identique).
2. Corriger les quatre commentaires/documents devenus obsolètes
   identifiés en §9 (Mineure) — corrections ponctuelles, à faible
   risque, aucune n'implique de changement de comportement. Bon candidat
   pour une prochaine petite passe de synchronisation documentaire,
   dans le même esprit que celle déjà faite le 2026-08-03.
3. Reconfirmer et promouvoir `NebulaVirtualKeyboard` /
   `NebulaLoginLayout.bottomInset` au §1 de `API-Stability-Review.md`
   (§8) — la validation réelle sur 3 thèmes qui justifierait cette
   promotion existe déjà, il ne manque que la mise à jour du document.
4. Documenter la distinction `NebulaUserService.currentUser` vs
   `NebulaUserList.currentIndex` (§10) — évite qu'un futur contributeur
   ne "corrige" une asymétrie qui est en réalité voulue.
5. Envisager un composant interne minimal type `NebulaLabel` pour
   absorber le bloc de style de texte répété (§1, §10) — seulement si
   un nouveau composant textuel apparaît et rendrait la duplication
   encore plus visible ; pas urgent avec les 6 occurrences actuelles.
6. Compléter `MockAuthAdapter.login()` avec le paramètre `sessionIndex`
   manquant (§3, §9) pour que les harnais de test exercent réellement ce
   chemin.

Aucune de ces recommandations ne modifie une API publique déjà gelée
(§0 de `API-Stability-Review.md`) ni ne retire quoi que ce soit —
toutes sont des corrections/factorisations internes ou documentaires.

## Ne pas modifier

Parties jugées suffisamment matures pour rester stables telles quelles,
sans qu'aucune évolution ne soit recherchée à ce stade :

- **`NebulaThemeProvider`/`NebulaThemeConfig`/`NebulaThemeLoader`** —
  contrat stable depuis DT-0003/Phase 2.0.5, exercé sans écart par les
  quatre thèmes réels. Seuls les deux commentaires obsolètes signalés
  en §5/§9 méritent une retouche ponctuelle ; l'architecture elle-même
  ne doit pas bouger.
- **`NebulaLoginLayout`** — la géométrie des quatre zones a déjà absorbé
  deux bugs réels trouvés en conditions réelles (Phase 1.3, validation
  VK-001) et n'a plus bougé depuis. Toute nouvelle contrainte de layout
  doit passer par une propriété additive (comme `bottomInset` l'a fait),
  jamais par une réécriture de la logique de centrage existante.
- **`NebulaBackground`/`NebulaWallpaper`/`NebulaOverlay`/`NebulaSurface`**
  — API inchangée depuis la Phase 1.5, listés stables dans
  `API-Stability-Review.md` §1, confirmés cohérents à la lecture. Ne pas
  ajouter de nouvelle propriété sans un besoin démontré par un thème
  réel (critère du gel d'API, §0 du même document).
- **`NebulaAuthService`/`NebulaUserService`/`NebulaSessionService`/
  `NebulaPowerService`** — le patron `adapter` injecté + propriétés
  gardées est stable, éprouvé par quatre thèmes et par les mocks. Le
  déséquilibre noté en §2 (sélection côté Service pour Session, côté
  composant pour User) est correct fonctionnellement — à documenter
  (Recommandation 4), pas à uniformiser de force.
- **`NebulaVirtualKeyboard`/`NebulaInputPanel`** — la séparation
  publique/interne et le contrat minimal (`available`/`keyboardActive`/
  `reservedHeight`/`show()`/`hide()`/`toggle()`) sont déjà corrects ;
  seule leur classification de stabilité documentaire doit être mise à
  jour (Recommandation 3), pas le code.
- **Scripts d'installation/désinstallation** (`install-nebula.sh`,
  `uninstall-nebula.sh`) — logique d'idempotence et marqueurs
  `.nebula-managed`/`.nebula-install-info` déjà robustes et testés en
  conditions réelles à plusieurs reprises ; seule l'extraction de
  `scripts/lib/common.sh` (Recommandation 1) les concerne, sans
  changement de comportement.
