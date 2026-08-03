# Services Architecture — Nebula

> Comment Nebula prépare l'intégration SDDM sans jamais l'exposer
> directement aux composants Core. Complète
> [`Core-API.md`](Core-API.md) (contrat des composants) et
> [`Theme-System.md`](Theme-System.md) (le même principe appliqué au
> theming plutôt qu'à SDDM).

---

## 1. Pourquoi

Depuis la Phase 1.0, on sait que l'API réelle de SDDM existe sous forme
de propriétés de contexte (`sddm`, `userModel`, `sessionModel`,
`keyboard` — voir [`Prototype-Results.md`](Prototype-Results.md) §3.2).
Sans règle explicite, les futurs composants `NebulaUserList`,
`NebulaPasswordField`, `NebulaSessionSelector`, `NebulaPowerButtons`
auraient fini par lire ces propriétés directement — exactement le genre
de couplage que `NebulaThemeProvider` existe déjà pour éviter côté
theming (voir DT-0006). La Phase 1.4 applique le même principe à
l'intégration SDDM : un composant ne connaît qu'un **Service** ; jamais
SDDM, jamais un objet de contexte SDDM.

## 2. Flux

```text
Core Components
 │  (NebulaUserList, NebulaPasswordField, NebulaSessionSelector,
 │   NebulaPowerButtons — pas encore implémentés)
 ▼
Core Services                    core/services/
 │  NebulaAuthService, NebulaUserService,
 │  NebulaSessionService, NebulaPowerService
 ▼
Platform Adapter                 platform/sddm/ (ou tests/mocks/ en test)
 │  SDDMAuthAdapter, SDDMUserAdapter,
 │  SDDMSessionAdapter, SDDMPowerAdapter
 ▼
SDDM API                         propriétés de contexte réelles
    (sddm, userModel, sessionModel, keyboard — Prototype-Results.md §3.2)
```

Interdit dans un composant Core : appeler `sddm.login()`, `sddm.powerOff()`,
`sddm.reboot()`, ou lire `userModel`/`sessionModel`/`keyboard` directement
— voir [`Nebula-Principles.md`](Nebula-Principles.md), principes 2 et 6.

## 3. Responsabilités

### NebulaAuthService (`core/services/NebulaAuthService.qml`)

- État : `authenticating` (bool, lecture seule), `errorMessage` (string,
  lecture seule).
- Actions : `authenticate(username, password)`, `cancel()`.
- Signaux : `succeeded()`, `failed(reason)`.
- Délègue à `adapter` (duck-typé : `login(username, password,
  sessionIndex)`, `cancel()`, signal `loginResult(success, reason)`).
- **`sessionService`** (property, référence optionnelle vers une
  instance de `NebulaSessionService`, défaut `null` — ajoutée en Phase
  3.2, voir DT-0024 dans `Decisions-Techniques.md`) : si définie,
  `authenticate()` lit `sessionService.currentIndex` au moment de
  l'appel et le transmet en 3e argument à `adapter.login()` ; sinon
  `sessionIndex` vaut `-1` et l'adapter retombe sur son propre repli
  (`sessionModel.lastIndex` pour `SDDMAuthAdapter`). La signature
  publique d'`authenticate(username, password)` ne change pas — ce lien
  reste interne au Service, `NebulaPasswordField` n'a aucune notion de
  session.
- Pas de connexion réelle implémentée avant la Phase 3.2 (squelette
  Phase 1.4) — uniquement le contrat public et le câblage vers
  l'adapter.
- Réel `sddm.login()` confirmé à 3 arguments positionnels
  (`username, password, sessionIndex`) et signaux réels
  `sddm.loginSucceeded()`/`loginFailed()` confirmés **sans argument** —
  aucune chaîne de raison n'est jamais fournie par SDDM ; `reason` dans
  `failed(reason)`/`errorMessage` est donc toujours un texte générique
  choisi par Nebula (voir `Development-Journal.md`, 2026-08-02 — Phase
  3.2).

### NebulaUserService (`core/services/NebulaUserService.qml`)

- État : `users` (liste), `currentUser` (objet).
- Actions : `refresh()`.
- Délègue à `adapter` (duck-typé : `users`, `currentUser`, `refresh()`).
- Prévoit plusieurs utilisateurs (`users` est une liste) même si seul
  l'utilisateur courant importe pour l'écran de login du Core MVP.
- Réel `userModel` (rôles confirmés en Phase 3.2 par lecture du thème
  `breeze`, voir `Development-Journal.md`, 2026-08-02 — Phase 3.2) :
  `name`, `realName`, `homeDir`, `icon`, `iconName?`, `needsPassword?`,
  `displayNumber?`, `vtNumber?`, `session?`, `isTty?` — à matérialiser
  via un `Repeater`/`ListView` interne invisible dans
  `SDDMUserAdapter.qml` (même patron que le correctif
  `screenModel.count` de la Phase 1.0), jamais lu directement par un
  composant Core.

### NebulaSessionService (`core/services/NebulaSessionService.qml`)

- État : `sessions` (liste), `currentIndex` (int).
- Actions : `selectSession(index)`.
- Signal : `sessionChanged(index)`.
- Délègue à `adapter` (duck-typé : `sessions`, `currentIndex`,
  `selectSession(index)`).
- Réel `sessionModel` (rôle confirmé en Phase 3.2, voir
  `Development-Journal.md`, 2026-08-02 — Phase 3.2) : rôle `name`
  uniquement, sélectionné par index de ligne — même patron de
  matérialisation via `Repeater`/`ListView` que `NebulaUserService`
  ci-dessus.
- `currentIndex` est aussi la valeur lue par `NebulaAuthService` (via sa
  property `sessionService`, voir DT-0024) pour construire l'appel réel
  `sddm.login(username, password, sessionIndex)`.

### NebulaPowerService (`core/services/NebulaPowerService.qml`)

- État : `canShutdown`, `canReboot`, `canSuspend` (bool, lecture seule).
- Actions : `shutdown()`, `reboot()`, `suspend()` — no-op si la capacité
  correspondante est `false`, y compris si un adapter mal configuré
  laisse passer l'appel.
- Délègue à `adapter` (duck-typé : `canShutdown`/`canReboot`/`canSuspend`,
  `shutdown()`/`reboot()`/`suspend()`).

### Platform Adapters (`platform/sddm/`)

`SDDMPowerAdapter` est réel depuis la Phase 3.2.1 : mapping direct sur
`sddm.canPowerOff`/`canReboot`/`canSuspend`/`canHibernate` et
`sddm.powerOff()`/`reboot()`/`suspend()`/`hibernate()` — attention au
décalage de nommage, SDDM n'a pas de `canShutdown`/`shutdown()`, notre
`canShutdown` correspond à son `canPowerOff` (voir
`Development-Journal.md`, 2026-08-02 — Phase 3.2 (3.2.1)).

`SDDMSessionAdapter` est réel depuis la Phase 3.2.2 : matérialise
`sessionModel` via un `Instantiator` interne (`Item`, pas `QtObject` —
même contrainte que `MockAuthAdapter`, il faut un enfant non-visuel).
Piège réel trouvé en testant : un rôle de modèle exposé par un
identifiant nu dans un délégué `QtObject` reste vide — seul l'accès
explicite `model.name` fonctionne (voir `Development-Journal.md`,
2026-08-02 — Phase 3.2 (3.2.2)). `currentIndex` initialisé une fois
depuis `sessionModel.lastIndex`, puis géré localement par
`selectSession()` sans jamais rappeler `sddm` — le lancement réel de la
session passe uniquement par `SDDMAuthAdapter` (3.2.4, voir DT-0024).

`SDDMUserAdapter` est réel depuis la Phase 3.2.3 : même patron
`Instantiator` + `model.<rôle>` explicite que `SDDMSessionAdapter`.
Seuls `name`/`realName`/`icon` sont mappés (repli `realName || name`
pour `displayName`, même logique que le vrai `breeze`) — les autres
rôles confirmés de `userModel` (`homeDir`, `needsPassword`, `vtNumber`,
...) n'ont aucun consommateur dans le contrat actuel de
`NebulaUserList`/`NebulaAvatar`, donc non repris (voir
`Development-Journal.md`, 2026-08-02 — Phase 3.2 (3.2.3)).

`SDDMAuthAdapter` est réel depuis la Phase 3.2.4 : `sddm.login(username,
password, sessionIndex)` + écoute de `sddm.loginSucceeded`/`loginFailed`
implémentés, vérifiés passivement (`qmllint`, chargement sous
`--test-mode`) puis **validés par un round-trip réel** (identifiants →
session Plasma lancée) le 2026-08-03 sous le vrai `sddm.service`, thème
`glass-dark`, protocole sûr de l'incident VT/DRM respecté — voir
`Real-Adapter-Validation.md`. Toutes les étapes de la Phase 3.2 sont
désormais entièrement validées.

### Mock Adapters (`tests/mocks/`)

Utilisés uniquement par les harnais de test (`ServicesHarness.qml`,
`LoginScreenHarness.qml`). Fournissent des données fictives et, pour
`MockAuthAdapter`, simulent un aller-retour asynchrone court (`Timer`
300 ms) pour exercer réellement les états `authenticating` →
`succeeded`/`failed`, pas seulement l'instanciation. `MockPowerAdapter`
ne fait jamais d'action système réelle — seulement `console.log`.

## 4. Ordre des appels (exemple : authentification)

1. Un composant (futur `NebulaPasswordField`) appelle
   `authService.authenticate(username, password)`.
2. `NebulaAuthService` passe `authenticating` à `true`, appelle
   `adapter.login(username, password)`.
3. L'adapter (mock ou, plus tard, `SDDMAuthAdapter`) traite la demande de
   façon asynchrone et émet `loginResult(success, reason)`.
4. `NebulaAuthService` écoute ce signal (connexion JS impérative dans
   `onAdapterChanged`, pas de `Connections{}` déclaratif — voir
   `Development-Journal.md`, Phase 1.4), met à jour `authenticating`/
   `errorMessage`, puis émet `succeeded()` ou `failed(reason)`.
5. Le composant réagit à ces signaux (ex. afficher l'erreur, débloquer le
   champ).

## 5. Ce qui reste hors périmètre de la Phase 1.4

- Câblage réel des `platform/sddm/*Adapter.qml` vers `sddm`/`userModel`/
  `sessionModel`/`keyboard` — squelettes seulement. **Pris en charge par
  la Phase 3.2 (Real SDDM Platform Integration, voir `Roadmap.md`)** :
  inconnues de rôles/signaux levées (3.2.0, voir
  `Development-Journal.md`, 2026-08-02), câblage adapter par adapter
  terminé et validé (3.2.1 à 3.2.4, voir `Real-Adapter-Validation.md`),
  par risque croissant.
- `NebulaUserList`, `NebulaPasswordField`, `NebulaSessionSelector`,
  `NebulaPowerButtons` eux-mêmes — pas encore implémentés, mais leur
  contrat `Core-API.md` a été mis à jour pour dépendre des Services
  plutôt que des propriétés SDDM directement (voir
  `Core-Implementation-Status.md`).
- Support d'un second display manager — `platform/` existe pour séparer
  `core/` de SDDM, pas pour préparer un usage multi-plateforme
  hypothétique (voir DT-0010 dans `Decisions-Techniques.md`).
