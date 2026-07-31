# Login Architecture — Nebula

> Comment les composants interactifs d'un écran de connexion s'assemblent
> et parlent aux Services — jamais à SDDM directement (voir
> [`Nebula-Principles.md`](Nebula-Principles.md) §2/§4). Introduit en
> Phase 2.3 (voir `Roadmap.md`). Complète
> [`Services-Architecture.md`](Services-Architecture.md) (le flux
> Service → Adapter → SDDM, inchangé ici) et
> [`Core-API.md`](Core-API.md) (contrat détaillé de chaque composant).

---

## 1. Composants couverts

`NebulaPasswordField`, `NebulaUserList`, `NebulaSessionSelector`,
`NebulaPowerButtons` (`core/components/`). Aucun ne dépend d'un thème ni
de SDDM — uniquement de `NebulaThemeProvider` et d'un Service (voir
`Services-Architecture.md`).

## 2. Modèle d'état commun (brief Phase 2.3 §6)

Pas de nouveau type/enum Core créé pour représenter
Idle/Authenticating/Succeeded/Failed — jugé prématuré avec un seul
consommateur (`NebulaPasswordField`) et cohérent avec le principe du
workspace (pas d'abstraction avant besoin observé). À la place, chaque
composant reflète directement l'état déjà exposé par son Service :

- **Idle** : `authService.authenticating === false`,
  `authService.errorMessage === ""`.
- **Authenticating** : `NebulaPasswordField.isBusy` (alias de
  `authService.authenticating`).
- **Succeeded** : signal `NebulaAuthService.succeeded()` — un thème
  réagit à ce signal (ex. transition d'écran), aucun composant de ce lot
  ne le fait lui-même.
- **Failed** : `NebulaPasswordField.hasError` (alias de
  `authService.errorMessage.length > 0`).

Les composants ne décident jamais de ces états — ils les affichent
(brief §6). Si un second composant a un jour besoin du même modèle
d'état, ce sera le signal pour l'extraire en un type Core partagé — pas
avant.

## 3. NebulaPasswordField

- Propriétés : `authService` (`NebulaAuthService`, requis), `username`
  (string — fourni par le thème, généralement
  `NebulaUserList.currentUser.name`), `placeholderText`, `hasError`,
  `isBusy`, `showToggleEnabled` (bool, affiche/masque le bouton
  Show/Hide).
- `submit()` : no-op si `isBusy` ou champ vide ; sinon émet
  `submitted(password)` puis appelle
  `authService.authenticate(username, password)` directement — c'est le
  seul composant de ce lot autorisé à appeler cette méthode.
- Jamais de stockage du mot de passe au-delà du texte affiché — rien
  n'est conservé après `submit()`/`clear()`.
- Focus automatique à la construction (`forceActiveFocus()`), animation
  de bordure de focus cohérente avec `NebulaButton` (mêmes tokens
  `interaction.borderWidthFocus`/`animation.durationFast`).

## 4. NebulaUserList

- Propriétés : `userService` (`NebulaUserService`, requis), `model`
  (alias de `userService.users`), `currentIndex`, `currentUser`
  (lecture seule).
- Navigation clavier (Gauche/Droite), sélection souris (clic sur un
  avatar) — les deux appellent `selectIndex(index)`, qui met à jour
  `currentIndex` et émet `userSelected(user)`.
- Chaque entrée compose `NebulaAvatar` (déjà existant) + le nom complet
  — aucune duplication du rendu d'avatar.

## 5. NebulaSessionSelector

- Propriétés : `sessionService` (`NebulaSessionService`, requis), `model`
  (alias de `sessionService.sessions`), `currentIndex`/`currentSession`
  (reflètent directement `sessionService`, pas de copie locale).
- `selectIndex(index)` appelle `sessionService.selectSession(index)`
  **avant** d'émettre `sessionSelected(session)` — le Service reste la
  source de vérité de la session active, jamais le composant.

## 6. NebulaPowerButtons

- Propriétés : `powerService` (`NebulaPowerService`, requis),
  `confirmBeforeAction` (bool).
- Un `NebulaButton` par action (Shut Down / Restart / Sleep / Hibernate),
  visible uniquement si `powerService.can*` correspondant est `true`.
- `confirmBeforeAction: true` arme l'action au premier clic (le libellé
  du bouton devient « Confirm? ») ; un second clic dans les 3 secondes
  l'exécute réellement ; sinon l'armement expire silencieusement. Pas de
  dialogue modal — `NebulaNotification` n'existe pas encore (voir
  `Roadmap.md`).
- `canHibernate`/`hibernate()` ajoutés à `NebulaPowerService` en Phase
  2.3 (voir `Decisions-Techniques.md`) pour ce composant — capacité déjà
  anticipée dans `Core-API.md` avant même d'être implémentée.

## 7. Flux complet d'une authentification

```text
1. NebulaUserList affiche userService.users, l'utilisateur navigue/clique
   → selectIndex(i) → userService inchangé (pas de "currentUser
     sélectionnable" côté Service, seulement côté composant) →
     userSelected(user) émis.
2. Le thème lie NebulaPasswordField.username à
   NebulaUserList.currentUser.name (binding réactif, pas un événement
   explicite à câbler).
3. L'utilisateur tape son mot de passe, appuie sur Entrée (ou clique sur
   un NebulaButton "Unlock" qui appelle passwordField.submit()) :
   → NebulaPasswordField.submit()
   → émet submitted(password)
   → appelle authService.authenticate(username, password)
4. NebulaAuthService : authenticating = true, délègue à son adapter.
   → NebulaPasswordField.isBusy devient true (binding réactif).
5. L'adapter (Mock en test, SDDMAuthAdapter — toujours un squelette
   Phase 1.4 — en production) répond de façon asynchrone.
6. NebulaAuthService émet succeeded() ou failed(reason) ; authenticating
   repasse à false, errorMessage mis à jour.
   → NebulaPasswordField.hasError reflète errorMessage (binding réactif).
7. Le thème écoute succeeded()/failed() pour la suite (transition
   d'écran, message d'erreur) — hors périmètre de ce lot de composants.
```

Aucune étape ne fait intervenir SDDM directement — uniquement les
Services, conformément à `Nebula-Principles.md` §2/§4.

## 8. Limite connue : adapters SDDM réels toujours des squelettes

`platform/sddm/SDDMUserAdapter`/`SDDMSessionAdapter`/`SDDMPowerAdapter`
restent des squelettes Phase 1.4 (listes vides, capacités à `false`,
actions en `console.warn`). Conséquence directe : sous
`sddm-greeter --test-mode` ou SDDM réel aujourd'hui,
`NebulaUserList`/`NebulaSessionSelector` s'affichent vides et
`NebulaPowerButtons` n'affiche aucun bouton — dégradation propre, jamais
un crash (vérifié réellement, voir `Development-Journal.md`, Phase 2.3).
La navigation clavier/souris et le flux d'authentification complet ne
sont donc réellement exercés aujourd'hui que via les Mock adapters
(`tests/LoginWorkflowHarness.qml`) — câbler les adapters réels reste un
besoin déjà connu, non traité par cette phase (hors périmètre, voir le
brief Phase 2.3 §12 : ces composants appartiennent au Core, pas à un
thème particulier).

## 9. Test

`tests/LoginWorkflowHarness.qml` assemble les quatre composants avec les
Services réels et des Mock adapters — voir le fichier pour le détail de
la mise en page (identique à `tests/LoginScreenHarness.qml`, étendue
avec sélection d'utilisateur, mot de passe, session, actions
d'alimentation).
