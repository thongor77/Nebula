# Real Adapter Validation — Nebula

> Critère de sortie de la Phase 3.2 (voir `Roadmap.md`) : les quatre
> adapters `platform/sddm/` (Power, Session, User, Auth) sont codés et
> vérifiés passivement (`qmllint`, chargement `--test-mode`) depuis le
> 2026-08-02. La seule chose que `--test-mode` ne peut jamais couvrir est
> le round-trip réel `sddm.login()` (aucun backend d'authentification en
> mode test, voir `Prototype-Results.md` §3.5) — ce document rapporte ce
> test réel, effectué le 2026-08-03 sous le vrai `sddm.service`, protocole
> sûr de la mémoire `nebula-vt-switch-freeze` respecté (pas de session
> bureau vivante en parallèle pendant le test).

---

## Réponse à la question posée

**Oui** — le round-trip d'authentification réel fonctionne de bout en
bout : `SDDMPasswordField` → `NebulaAuthService.authenticate()` →
`SDDMAuthAdapter.login()` → `sddm.login(username, password,
sessionIndex)` → PAM réel → `sddm.loginSucceeded` → vraie session Plasma
démarrée. Confirmé par `journalctl -u sddm` :

```
Message received from greeter: Login
[PAM] Authenticating...
pam_kwallet5(sddm:auth): pam_kwallet5: pam_sm_authenticate
Authentication for user "luust" successful
pam_unix(sddm:session): session opened for user luust(uid=1000) by luust(uid=0)
gkr-pam: unlocked login keyring
Session started true
```

Thème testé : `glass-dark` (choisi plutôt que `nord` car il possède un
sélecteur de session, exerçant aussi le wiring `NebulaAuthService.
sessionService` de DT-0024). Compte réel : `luust`. Session réellement
chargée après authentification, confirmée par l'utilisateur.

---

## Constat #1 — Le premier essai a échoué à cause d'un déploiement obsolète, pas d'un bug du nouveau code

Le premier essai est resté bloqué indéfiniment sur "Authenticating..."
sans jamais aboutir. `journalctl _PID=<greeter>` a montré la cause
exacte :

```
SDDMAuthAdapter.login: not implemented yet (Phase 1.4 skeleton) — see docs/Services-Architecture.md
```

Le greeter installé (`/usr/share/sddm/themes/glass-dark/` +
module Nebula sous `QT_INSTALL_QML`) chargeait encore l'ancien stub de
la Phase 1.4 — le vrai code de la Phase 3.2, écrit dans l'arbre de
travail, n'avait jamais été redéployé via `scripts/install-nebula.sh`
depuis son écriture le 2026-08-02. L'UI passait en état "authenticating"
de façon optimiste (avant même l'appel réel à `sddm.login()`), ce qui
masquait totalement le fait que rien ne se passait côté daemon —
confirmé par l'absence de tout message `Login` dans `journalctl -u sddm`
pendant que l'écran affichait "Authenticating...".

**Symptôme secondaire du même déploiement obsolète** : le premier essai
n'affichait aucun sélecteur de session (pourtant attendu pour
`glass-dark`) — cohérent avec un module Core déployé également en
retard sur DT-0024.

**Correction** : `sudo scripts/install-nebula.sh glass-dark` puis
`sudo systemctl restart sddm` (sûr ici — aucune session de bureau
vivante à casser, seul le greeter bloqué a été recyclé). Le second essai
a chargé le vrai adapter et abouti normalement.

**Leçon** : le "critère de sortie" d'une phase touchant `platform/` doit
désormais inclure explicitly un redéploiement (`install-nebula.sh`)
avant tout test réel — écrire le code dans le dépôt ne suffit pas à le
rendre actif sur une machine où Nebula est déjà installé.

## Constat #2 — Clavier virtuel superposé à l'écran actif (VK-001, nouvelle preuve)

Sur les 3 écrans réels de la machine (widescreen, HP, laptop), seul
l'écran ayant le focus clavier affiche le clavier virtuel Qt — celui-ci
s'ancre en bas de l'écran et recouvre une partie de la carte de login
(champ password, sélecteur de session, boutons power selon la position).
Les deux autres écrans affichent leur carte complète sans clavier.

Ceci est une nouvelle preuve photographique (capturée le 2026-08-03,
`photos/3-screens.jpg`) du problème déjà documenté dans la mémoire de
session `nebula-vk001-investigation`, cette fois en conditions
pleinement réelles (vrai `sddm.service`, pas `--test-mode`) et en
confirmant le comportement multi-écran : le clavier suit le focus, pas
un écran fixe. L'investigation VK-001 était explicitement suspendue en
attendant la fin de la Phase 3.2 — elle est maintenant débloquée, mais
reste volontairement non reprise (aucune décision explicite de la
relancer à ce jour).

## Constat #3 — Débordement des points du champ password (corrigé)

Constaté sur le même test réel (`photos/password-field.jpg`) : les
points représentant les caractères saisis débordaient du cadre arrondi
du champ vers la gauche au lieu d'être coupés à ses limites. Cause :
`core/components/NebulaPasswordField.qml`, le `TextInput` interne n'avait
pas `clip: true` — son défilement interne (pour garder le curseur
visible) repositionne le contenu mais, sans `clip`, ce qui dépasse la
largeur visible continue à être peint hors des limites de l'item.

**Corrigé** (2026-08-03) : ajout de `clip: true` sur le `TextInput`
(`NebulaPasswordField.qml`), un changement d'une ligne, sans impact sur
l'API publique du composant — justifié comme bug réel au sens de la
règle de gel de l'API du Core. Revérifié visuellement après redéploiement
: les points restent bien dans le cadre.

**Défaut résiduel mineur, non corrigé délibérément** : le point le plus à
gauche apparaît parfois à moitié coupé selon la position de défilement
interne — artefact inhérent au mécanisme d'auto-scroll de `TextInput`
(le point de coupe ne s'aligne pas toujours pixel-perfect sur une
limite de glyphe), visible aussi sur d'autres champs password natifs
(macOS, GTK). Un correctif complet demanderait un padding de clip
ajusté dynamiquement pour un gain visuel négligeable — non justifié.

---

## Statut

Phase 3.2 terminée. Les 4 adapters SDDM (`SDDMPowerAdapter`,
`SDDMSessionAdapter`, `SDDMUserAdapter`, `SDDMAuthAdapter`) sont réels et
validés — les 3 premiers passivement sous `--test-mode`, `SDDMAuthAdapter`
par un round-trip réel complet sous le vrai `sddm.service`. Commité le
2026-08-03 (52805e6).
