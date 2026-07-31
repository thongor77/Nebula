# Nord Validation Report — Nebula

> Rapport de la Phase 2.1 (voir `Roadmap.md`) : Nord est le premier
> thème officiel, construit exclusivement avec les mécanismes existants
> du SDK (voir [`Theme-SDK.md`](Theme-SDK.md),
> [`ThemeLoader.md`](ThemeLoader.md)). Le succès de cette phase ne se
> mesure pas au rendu graphique, mais à la question posée par le brief :
> **le SDK actuel permet-il de créer un thème propre, cohérent et
> maintenable sans modifier le Core ?**
>
> Portée décidée avec l'utilisateur (2026-07-31) : Nord est construit
> avec uniquement les composants Core existants aujourd'hui
> (`NebulaThemeProvider`, `NebulaBackground`, `NebulaWallpaper`,
> `NebulaOverlay`, `NebulaLoginLayout`, `NebulaSurface`, `NebulaAvatar`,
> `NebulaClock`, `NebulaDate`, `NebulaButton`) — pas une reconstruction
> du Core pour se conformer à `Nord-Theme-Specification.md` §5 (écrite
> en phase d'architecture, avant que le Core existe réellement). Un écran
> de connexion visuellement cohérent mais volontairement incomplet
> fonctionnellement était le résultat attendu.

---

## Réponse à la question posée

**Oui pour la mécanique de theming elle-même** — `theme.conf` →
`NebulaThemeLoader` → `NebulaThemeConfig` → `NebulaThemeProvider` →
composants fonctionne de bout en bout, sans qu'aucun fichier sous
`core/` n'ait dû changer pour Nord. La palette officielle Nord (9
tokens couleur) s'applique proprement, testée réellement sous `qml6`,
`sddm-greeter --test-mode` (3 écrans réels + `QT_SCALE_FACTOR=2`), et
`tests/ThemeHarness.qml`/`tests/ThemeInspector.qml`.

**Non pour la distribution/l'installation d'un thème hors du dépôt** —
voir constat #1 ci-dessous, la découverte la plus importante de cette
phase, trouvée précisément en réalisant le test que le brief demandait
(« installation dans un environnement SDDM réel ») plutôt qu'en se
limitant à `sddm-greeter --test-mode` depuis le dépôt.

---

## Constat #1 — Un thème installé hors du dépôt Nebula ne peut pas charger le Core (critique)

- **Description** : `themes/nord/Main.qml` importe le Core par chemin
  relatif (`import "../../core/theme"`, etc.), en supposant que
  `core/`/`platform/` existent deux niveaux au-dessus du thème — vrai
  uniquement à l'intérieur du dépôt Git. En copiant `themes/nord/` seul
  vers `/usr/share/sddm/themes/nord/` (l'emplacement réel d'installation
  d'un thème SDDM) puis en le chargeant avec `sddm-greeter-qt6
  --test-mode --theme /usr/share/sddm/themes/nord`, les imports
  échouent : `"../../core/theme": no such directory`.
- **Impact** : SDDM ne plante pas — il bascule proprement sur son thème
  de secours intégré avec un message d'erreur visible (« The current
  theme cannot be loaded due to the errors below »), confirmé réellement
  par capture d'écran sur les 3 écrans de la machine. Aucun risque pour
  la session graphique réelle. Mais **aucun thème Nebula ne peut
  fonctionner une fois réellement installé séparément du dépôt** — un
  problème qui touchera exactement de la même façon Nord, le Template,
  et tout futur thème (Cyberpunk, Glass, AMOLED, Hyprland). Ce n'est pas
  un défaut de Nord : n'importe quel thème respectant parfaitement le
  SDK aurait le même problème, puisque le SDK ne dit rien sur comment le
  Core doit être rendu disponible à un thème installé séparément.
- **Solution retenue pour cette phase** : documenter uniquement, ne pas
  résoudre maintenant — hors du périmètre de la Phase 2.1 (qui valide le
  mécanisme de theming, pas la distribution). L'installation de test
  réelle est restée en place sous
  `/usr/share/sddm/themes/nord/` (copiée par l'utilisateur via un accès
  root direct — cette session n'a pas les privilèges `sudo`), sans
  jamais activer `Current=nord` dans la configuration SDDM — le vrai
  écran de connexion de la machine n'a jamais été affecté.
- **Le Core doit-il évoluer ?** Oui, mais via une phase dédiée
  (« Distribution »/« Packaging »), pas en réaction ponctuelle pendant
  une phase thème. Options identifiées, à trancher plus tard :
  1. **Module QML partagé** : installer `core/`/`platform/` à un chemin
     système connu (ex. `/usr/share/nebula/core/`) et les exposer comme
     un module QML nommé (`qmldir` + `import Nebula.Core`) via
     `QML2_IMPORT_PATH`, plutôt que des chemins relatifs. Nécessite un
     vrai mécanisme d'installation/empaquetage (PKGBUILD ou équivalent)
     et de faire pointer ce chemin d'import pour le processus
     `sddm-greeter` — mécanisme SDDM exact encore à vérifier.
  2. **Core embarqué par thème** : copier `core/`/`platform/` à
     l'intérieur du dossier de chaque thème installé. Fonctionne sans
     changement d'architecture, mais recrée exactement la duplication
     que Nebula existe pour éliminer (voir `Architecture.md`, section
     Problème) — rejeté comme solution finale, envisageable seulement
     comme pis-aller temporaire.
  3. **Lien symbolique** au moment de l'installation d'un thème
     (`/usr/share/sddm/themes/nord/core` → chemin d'installation du
     Core) : plus simple que l'option 1, mais fragile (dépend de l'ordre
     d'installation Core/thème, invisible pour un packager qui ne
     connaît pas cette convention).
  Aucune de ces options n'a été implémentée cette phase — décision
  différée à une phase de packaging dédiée, une fois plusieurs thèmes
  réels (Nord + au moins un second) confirment le besoin exact.

## Constat #2 — Composants d'écran de connexion manquants (connu, non bloquant)

- **Description** : `docs/Nord-Theme-Specification.md` §5 (rédigée en
  phase d'architecture) prévoit `NebulaUserList`, `NebulaPasswordField`,
  `NebulaSessionSelector`, `NebulaKeyboardSelector`,
  `NebulaPowerButtons`, `NebulaNotification`, `NebulaAnimationManager` —
  aucun n'existe encore dans `core/` (voir `Roadmap.md`, Phase 1, items
  9/11/12, toujours non cochés).
- **Impact** : Nord n'a ni saisie de nom d'utilisateur réelle, ni champ
  de mot de passe, ni sélecteur de session/clavier, ni actions
  d'alimentation, ni notification d'erreur. Le bouton « Unlock » appelle
  `NebulaAuthService.authenticate()` avec un mot de passe vide — non
  fonctionnel comme véritable écran de connexion.
- **Solution retenue** : décision utilisateur explicite (2026-07-31) —
  ce n'est pas un échec de cette phase. Nord reste un consommateur du
  Core tel qu'il existe aujourd'hui ; les composants manquants seront
  développés comme des évolutions du framework (Phase 1, déjà planifiées)
  puis intégrés naturellement dans Nord lors d'une phase ultérieure.
- **Le Core doit-il évoluer ?** Oui — mais c'était déjà su et planifié
  avant cette phase (Roadmap Phase 1), pas une découverte de Nord.

## Constat #3 — `ThemeInspector` : pas de traçabilité native de l'origine d'un token (mineur)

- **Description** : `tests/ThemeInspector.qml` (voir §7 du brief)
  détermine si un token vient du thème ou du défaut du Core en comparant
  la valeur chargée à un `NebulaThemeConfig` neuf — pas en interrogeant
  `NebulaThemeLoader` sur les clés réellement trouvées dans `theme.conf`
  (il ne les expose pas).
- **Impact** : limitation mineure et assumée — une valeur de
  `theme.conf` qui coïncide avec le défaut du Core (improbable mais
  possible) serait affichée comme « default » alors qu'elle a été
  explicitement définie. N'affecte que cet outil de diagnostic, jamais
  le comportement réel d'un thème.
- **Solution retenue** : documentée comme limitation connue dans
  `tests/ThemeInspector.qml` lui-même plutôt que corrigée — corriger
  exigerait d'exposer une nouvelle propriété sur `NebulaThemeLoader`
  (ex. `appliedTokenNames`), une modification du Core non justifiée par
  un besoin réel observé au-delà de cet outil de diagnostic.
- **Le Core doit-il évoluer ?** Pas maintenant — à reconsidérer si ce
  cas limite se présente réellement avec un futur thème.

---

## Idées pour de futurs thèmes (non implémentées, par principe — voir brief §10)

- Effets GPU (blur/glow/particules) : explicitement hors périmètre de
  Nord (voir `Nord-Theme-Specification.md` §1/§6), réservés à Cyberpunk/
  Glass (voir `Roadmap.md`, Phase 3). Rien trouvé pendant Nord qui change
  ce plan déjà établi.
- Un vrai fond animé/diaporama (`NebulaWallpaperEngine`) — utile pour
  Hyprland/AMOLED potentiellement, pas nécessaire à Nord. Déjà planifié
  hors MVP (voir `Core-MVP.md`).

## Critère de fin

- [x] Le thème Nord est fonctionnel dans le périmètre décidé (écran
      cohérent visuellement, incomplet fonctionnellement par choix
      explicite).
- [x] Utilise exclusivement les mécanismes officiels du SDK (`theme.conf`
      + `NebulaThemeLoader` + composants Core existants) — aucune copie
      ni modification de `core/`.
- [x] Aucune duplication du Core dans `themes/nord/`.
- [x] Toutes les limitations rencontrées sont documentées ci-dessus.
- [x] Ce rapport indique clairement que le Core nécessite un ajustement
      — pas dans son API de theming (validée), mais dans sa stratégie de
      **distribution/installation**, une dimension entièrement différente
      non couverte avant cette phase.

Nebula est un framework de theming mature pour la partie qu'il a
réellement essayé de valider (SDK, ThemeLoader, Design Tokens,
composition). Il n'est pas encore un framework de thèmes *installable*
en dehors de son propre dépôt — c'est le prochain problème réel à
résoudre, révélé précisément parce que cette phase a testé au-delà de
`sddm-greeter --test-mode` depuis le dépôt.
