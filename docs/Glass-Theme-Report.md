# Glass Theme Report — Nebula

> Rapport de la Phase 3.0 (voir `Roadmap.md`) : Glass est le deuxième
> thème officiel de Nebula, en deux variantes indépendantes
> (`themes/glass-light/`, `themes/glass-dark/`), toutes deux conformes
> au contrat SDK actuel (un thème = `Main.qml` + `theme.conf` +
> `metadata.desktop` + `README.md` + `preview.png` + `assets/`). Question
> posée par le brief : **le Core est-il capable de produire une
> interface moderne et élégante sans nécessiter aucune modification de
> son architecture ?** Portée décidée avec l'utilisateur (2026-07-31) :
> deux thèmes indépendants respectant strictement le contrat SDK ;
> mutualisation autorisée uniquement au niveau du dépôt/implémentation
> (contenu de `Main.qml`, assets), jamais comme nouveau mécanisme imposé
> aux auteurs de thèmes.

---

## Réponse à la question posée

**Oui.** Glass utilise l'ensemble complet des composants Core
disponibles aujourd'hui (`NebulaBackground`/`NebulaWallpaper`/
`NebulaOverlay`/`NebulaLoginLayout`/`NebulaSurface`/`NebulaClock`/
`NebulaDate`/`NebulaUserList`/`NebulaPasswordField`/`NebulaButton`/
`NebulaSessionSelector`/`NebulaPowerButtons`) et produit un écran de
connexion visuellement moderne (verre dépoli sobre, palette claire et
sombre partageant les mêmes tokens, animations discrètes) sans qu'aucun
fichier sous `core/` n'ait dû changer. C'est aussi le premier thème à
utiliser l'ensemble fonctionnel complet issu de la Phase 2.3 — Nord
(Phase 2.1) avait délibérément été limité à un sous-ensemble plus
restreint.

Une limitation réelle et significative a cependant été découverte
pendant cette phase — pas dans le Core lui-même, mais dans
l'**architecture de déploiement** (Phase 2.2) : voir Constat #1
ci-dessous. Elle a été corrigée immédiatement, par décision explicite de
l'utilisateur, puisqu'elle affecte tout thème installé (Nord, Template,
Glass), pas seulement Glass.

---

## Points forts

- **Deux variantes, un seul jeu de tokens** : `glass-light/theme.conf`
  et `glass-dark/theme.conf` définissent exactement les mêmes 17 clés
  (couleurs, rayons, opacités, durée d'animation, police) — seules les
  valeurs diffèrent, conformément au brief. Vérifié réellement via
  `tests/ThemeHarness.qml -- glass-light`/`-- glass-dark` (36 tokens
  chargés dans les deux cas, voir §Validation).
- **Ensemble fonctionnel complet** : premier thème officiel à utiliser
  `NebulaUserList`, `NebulaPasswordField`, `NebulaSessionSelector` et
  `NebulaPowerButtons` ensemble — un écran de connexion réellement
  utilisable (sélection d'utilisateur, saisie de mot de passe avec
  bascule affichage/masquage, sélection de session, actions
  d'alimentation avec confirmation), pas seulement cohérent visuellement
  comme Nord.
- **Aucune duplication de mécanisme** : `Main.qml` des deux variantes ne
  diffère que par le nom du fond d'écran chargé et un mot de commentaire
  — la mutualisation demandée par l'utilisateur reste un détail de
  dépôt, jamais un nouveau mécanisme SDK (chaque variante garde son
  propre `Main.qml`/`theme.conf`/`metadata.desktop` complets et
  indépendants).
- **Wallpapers et icônes originaux** : générés spécifiquement pour ce
  thème (dégradés discrets sans blobs saturés — la première génération,
  trop vive, a été auto-corrigée avant validation, voir
  `Development-Journal.md`), 4K (3840×2160) + version compressée pour
  chaque variante, jeu de 5 icônes (shutdown/restart/suspend/hibernate/
  reveal-password) au style cohérent (gris `#8E8E93`, 64×64,
  transparent).

## Typographie

Testé : Noto Sans, Inter, Cantarell (les trois exigées par le brief).

- **Inter** : non installée sur cette machine (`fc-match Inter` retombe
  sur Noto Sans) — l'exiger comme police par défaut d'un thème officiel
  casserait le rendu sur toute machine qui ne l'a pas explicitement
  installée, un thème SDDM ne pouvant pas embarquer/installer ses
  propres polices système via le SDK actuel.
- **Cantarell** : installée et rendue correctement (`fc-match Cantarell`
  la résout directement), mais c'est la police système par défaut de
  GNOME/GTK — un choix cohérent pour un environnement GNOME, moins pour
  un framework dont la cible principale est KDE Plasma (voir `CLAUDE.md`
  du projet).
- **Noto Sans** : installée, se résout directement
  (`fc-match "Noto Sans"` → `NotoSans-Regular.ttf`), lisible, neutre,
  disponible largement sans dépendre d'une distribution ou d'un
  environnement de bureau particulier.

**Choix retenu : Noto Sans**, pour les deux variantes — seule option
réellement présente sur le système sans dépendre d'un environnement de
bureau spécifique, cohérente avec le choix déjà fait par Nord (aucune
raison de diverger sans bénéfice réel observé).

## Surfaces

Quatre combinaisons opacité/rayon/ombre comparées côte à côte sur le
fond `glass-dark` réel (test standalone jetable, voir
`Development-Journal.md`) :

| # | Opacité | Rayon | Ombre |
|---|---------|-------|-------|
| 1 | 0.45 | 12 | aucune |
| 2 | 0.65 | 20 | 0.2 / décalage 3 |
| 3 | 0.75 | 20 | 0.3 / décalage 4 |
| 4 | 0.90 | 28 | 0.35 / décalage 6 |

- La combinaison 1 laisse trop transparaître le fond d'écran et, sans
  ombre, ne se détache pas visuellement — perd l'effet « verre », se
  confond avec l'arrière-plan.
- La combinaison 4 est presque totalement opaque — perd également
  l'effet de transparence recherché (« verre dépoli »), se rapproche
  d'une carte pleine.
- **Combinaison 3 retenue** (`surfaceOpacity=0.75`, `radiusLarge=20`,
  `shadowOpacity=0.3`, `shadowOffset=4`) : équilibre entre lisibilité du
  texte, transparence perceptible et séparation visuelle nette avec une
  ombre douce mais présente. Valeurs reportées dans les deux
  `theme.conf` (`surfaceOpacity`/`radiusLarge`) et explicitement dans
  `Main.qml` (`shadowOpacity`/`shadowOffset` sur la `NebulaSurface`
  principale, plutôt que de dépendre des défauts du Core
  `shadowOpacity=0.25`/`shadowOffset=2`, qui ne correspondaient à aucune
  des quatre combinaisons testées).

## Animations

Les cinq animations demandées par le brief, toutes ponctuelles (jamais
en boucle), dans la fourchette conseillée de 150–250 ms
(`durationFast=150`, `durationNormal=250` — seul `durationFast` a été
relevé du défaut Core de 120 ms) :

- **Apparition** : fondu + léger zoom (`opacity`/`scale` de 0/0.96 vers
  1/1) au chargement de la carte principale.
- **Disparition** : la même `Behavior on opacity` ramène la carte à 0
  sur `NebulaAuthService.onSucceeded` — pas une animation séparée,
  réutilise le même mécanisme dans l'autre sens.
- **Focus** : bordure d'accent (`theme.interaction.borderWidthFocus`/
  `theme.colors.accentColor`) sur `NebulaPasswordField`/`NebulaButton` —
  mécanisme déjà existant du Core, pas réimplémenté par Glass. Vérifié
  visuellement via `forceActiveFocus()` sur un harnais isolé (capture
  d'écran confirmant la bordure d'accent bleu/violet appliquée avec les
  tokens Glass) ; une vérification par simulation de touche Tab réelle
  n'a pas été possible (`xdotool` repose sur XTest, non fonctionnel sur
  une session Wayland native — limitation de l'outil de test, pas du
  thème).
- **Changement d'utilisateur** : `NebulaUserList` reçoit une pulsation
  brève (scale 1.0 → 1.04 → 1.0) sur `onUserSelected`, via la technique
  du « nudge » déjà documentée (`Development-Journal.md`, Phase 2.0.5)
  pour forcer le retriggering du `Behavior` quand la cible numérique ne
  change pas.
- **Validation du mot de passe** : `NebulaPasswordField` reçoit un
  tremblement horizontal ponctuel (-8px → +8px → 0) sur
  `onHasErrorChanged`, même technique de nudge.

Aucune animation permanente/en boucle n'a été ajoutée, conformément au
brief (« éviter animation permanente »).

## HiDPI et multi-écran

Testé réellement sous `sddm-greeter-qt6 --test-mode` (3 écrans physiques
réels de la machine) à 100 %, 125 %, 150 % et 200 % (`QT_SCALE_FACTOR`),
pour les deux variantes :

- Aucune erreur/avertissement QML à aucune des 8 combinaisons
  (2 variantes × 4 échelles).
- Mise en page, texte et espacement restent lisibles et proportionnés à
  chaque échelle — aucun chevauchement, aucun rognage.
- Confirmé sur les 3 écrans réels simultanément à chaque test (un
  `QQuickView` par écran physique, comportement déjà documenté en
  Phase 2.0/2.0.5 — pas spécifique à Glass).

**Un piège de méthodologie de test a été rencontré puis corrigé** (voir
Constat #2) : la première série de tests HiDPI/multi-écran a été
invalidée par un oubli de `QML_XHR_ALLOW_FILE_READ=1` dans l'invocation
de `sddm-greeter-qt6` — les deux variantes affichaient silencieusement
les couleurs par défaut du Core au lieu des leurs. `glass-dark`
paraissait correct par coïncidence de teinte ; `glass-light` (carte
restée sombre au lieu de blanche) l'a immédiatement révélé. Les
résultats ci-dessus viennent de la série refaite avec la variable
correctement définie.

## Performances (comparaison avec Nord)

Méthodologie identique à la référence Phase 1.5
(`Rendering-Guidelines.md` §6) : comptage manuel depuis le code source
réellement exécuté, pas de trace `qmlprofiler`.

| Mesure | Nord | Glass (par variante) |
|---|---|---|
| Objets QML instanciés (approx.) | ~51 | ~131 |
| Timers actifs en continu | 2 (Clock 1s, Date 60s) | 2 (identiques) |
| Mémoire résidente (`ps` RSS, `qml6` seul) | ~378 Mo | ~388 Mo |

- L'écart d'objets (~2.5×) vient entièrement de l'ensemble fonctionnel
  plus large de Glass, pas d'un coût par-composant plus élevé : Nord
  n'utilise ni `NebulaUserList` (~36 objets avec 3 utilisateurs, chaque
  `NebulaAvatar` comptant ~7 objets à lui seul), ni
  `NebulaPasswordField` (~7), ni `NebulaSessionSelector` (~9 avec 2
  sessions), ni `NebulaPowerButtons` (~31 avec 4 actions, chaque
  `NebulaButton` réutilisé comptant ~7 objets). Un Nord reconstruit
  aujourd'hui avec le même ensemble de composants afficherait une
  augmentation comparable — ce n'est pas spécifique au code de Glass.
- **Aucun nouveau timer continu** : le seul `Timer` supplémentaire
  introduit par l'ensemble de composants utilisé (`confirmResetTimer`
  dans `NebulaPowerButtons`) a `running` à `false` par défaut — il ne
  s'active que brièvement après un clic d'action nécessitant
  confirmation, puis s'arrête (3 s ou clic de confirmation).
- **Aucun binding par-frame** identifié en dehors des deux `Timer` —
  toutes les animations de Glass (apparition, pulsation, tremblement)
  sont ponctuelles, déclenchées par un changement d'état réel, jamais en
  boucle continue.
- La hausse mémoire (~+10 Mo, ~2.6 %) est cohérente avec le nombre
  d'objets supplémentaires et le chargement d'un second fond d'écran
  4K — pas un signal d'alerte.

## Constat #1 — Aucune personnalisation d'icône sur `NebulaPowerButtons`/`NebulaPasswordField` (connu, non bloquant)

- **Description** : les 5 icônes générées pour Glass
  (shutdown/restart/suspend/hibernate/reveal-password) ne peuvent pas
  être câblées dans l'interface réelle sans modification du Core.
  `NebulaPowerButtons` compose des `NebulaButton` internes sans exposer
  de propriété d'icône par action ; `NebulaPasswordField` affiche sa
  bascule affichage/masquage sous forme de texte (« Show »/« Hide »),
  sans slot pour une image.
- **Impact** : les icônes existent dans
  `themes/glass-{dark,light}/assets/icons/` (conformes au contrat SDK,
  utilisables par un futur thème une fois le Core étendu) mais ne sont
  actuellement affichées nulle part dans l'écran de connexion réel.
- **Solution retenue** : documenté ici, pas corrigé — modifier
  `NebulaPowerButtons`/`NebulaPasswordField` pour accepter des icônes
  serait une évolution du Core, hors du principe fondamental de cette
  phase (« aucun composant Core ne doit être modifié », brief §Principe
  fondamental). Les icônes restent prêtes pour quand ce besoin sera
  traité.
- **Le Core doit-il évoluer ?** Oui, probablement — une propriété
  d'icône par action sur `NebulaPowerButtons` (ex. `shutdownIcon: url`)
  et une propriété d'icône de bascule sur `NebulaPasswordField`
  seraient cohérentes avec `NebulaButton.icon` qui existe déjà. À
  documenter dans `Core-API.md`/`Roadmap.md` avant implémentation
  (DT-0009), une fois ce besoin confirmé par un second thème qui en a
  également besoin (voir `Nebula-Principles.md` — ne pas faire évoluer
  le Core pour un besoin observé une seule fois).

## Constat #2 — `theme.conf` ne se charge pas sous SDDM réel sans `GreeterEnvironment=` (critique, corrigé)

- **Description** : `NebulaThemeLoader` lit `theme.conf` via
  `XMLHttpRequest`, qui nécessite `QML_XHR_ALLOW_FILE_READ=1` — déjà
  documenté depuis la Phase 2.0.5 pour `qml6`/`sddm-greeter --test-mode`
  (`Compatibility-Matrix.md` §4), mais **jamais vérifié pour le vrai
  service `sddm.service`** lancé par systemd. Confirmé : ni
  `/etc/sddm.conf`, ni `/usr/lib/sddm/sddm.conf.d/default.conf`, ni
  l'unité `sddm.service` ne définissent cette variable. Sans elle, tout
  thème installé (Nord, Template, Glass) retombe silencieusement sur les
  valeurs par défaut du Core.
- **Impact** : découvert en testant Glass (`glass-light` l'a
  immédiatement révélé, `glass-dark` paraissait correct par coïncidence
  de teinte) — mais touche **tout** thème Nebula installé
  système-wide, pas seulement Glass. Un problème d'architecture de
  déploiement (Phase 2.2), pas un défaut de ce thème.
- **Solution retenue** : corrigé immédiatement, par décision explicite
  de l'utilisateur (« cette découverte révèle une limitation de
  l'architecture de déploiement de Nebula et non un problème spécifique
  au thème Glass ») — `scripts/install-nebula.sh` écrit désormais
  `/etc/sddm.conf.d/nebula.conf` avec
  `GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1` ; retiré par
  `scripts/uninstall-nebula.sh --core`/`--all` ; vérifié par
  `scripts/check-installation.sh`. Détail complet, alternatives
  étudiées et limite de vérification assumée (pas de redémarrage du vrai
  `sddm.service` testé) : voir DT-0023 dans `Decisions-Techniques.md` et
  `Compatibility-Matrix.md` §9.
- **Le Core doit-il évoluer ?** Non — `NebulaThemeLoader` garde son
  architecture actuelle (lecture `theme.conf` via XHR, découplée de
  SDDM par principe, voir `Nebula-Principles.md` §2). Une alternative
  plus propre existe en théorie (un Platform Adapter lisant
  `config.<clé>` de SDDM directement) mais changerait l'architecture du
  Loader lui-même — identifiée comme piste future, pas implémentée
  (hors périmètre d'un correctif de déploiement ponctuel).

## Validation

- `qmllint` : propre sur les deux `Main.qml`.
- `qml6` : chargement direct sans erreur, aux 4 échelles HiDPI, pour les
  deux variantes.
- `tests/ThemeHarness.qml -- glass-dark`/`-- glass-light` : 36 tokens
  chargés correctement dans les deux cas.
- `tests/LoginWorkflowHarness.qml`-équivalent (harnais dédié avec
  Mock adapters + tokens Glass) : ensemble fonctionnel complet
  (utilisateurs, mot de passe, sessions, alimentation) rendu et
  interactif, aux mêmes échelles HiDPI.
- `sddm-greeter-qt6 --test-mode --theme themes/glass-dark`/
  `glass-light` : validé sur les 3 écrans réels, 4 échelles HiDPI,
  `QML_XHR_ALLOW_FILE_READ=1` correctement défini (voir Constat #2).
- Installation système (`scripts/install-nebula.sh`) : à valider dans le
  cadre de la Phase 3.0 avant commit final (voir tâche suivante).

## Critère de fin

- [x] Glass fonctionne avec l'ensemble complet de composants Core
      disponibles, sans aucune modification de `core/`.
- [x] Deux variantes indépendantes, contrat SDK respecté par chacune,
      mutualisation limitée au dépôt/implémentation.
- [x] Typographie testée et justifiée (Noto Sans).
- [x] Surfaces testées (4 combinaisons opacité/rayon/ombre), valeurs
      justifiées.
- [x] Cinq animations testées, toutes ponctuelles, dans la fourchette
      150–250 ms.
- [x] HiDPI (100/125/150/200 %) et multi-écran (3 écrans réels)
      validés pour les deux variantes.
- [x] Performances mesurées et comparées à Nord.
- [x] Toutes les découvertes documentées, y compris une limitation
      d'architecture de déploiement affectant tout le framework
      (Constat #2), corrigée par décision explicite de l'utilisateur.
- [ ] Installable comme Nord (`scripts/install-nebula.sh glass-dark`/
      `glass-light`) — validation finale en cours, voir tâche suivante.

Glass démontre que le Core actuel produit une interface moderne et
complète sans modification — la seule limitation Core identifiée
(icônes non personnalisables sur `NebulaPowerButtons`/
`NebulaPasswordField`) reste documentée, pas corrigée, conformément au
principe fondamental de cette phase. La découverte la plus importante
n'est pas un défaut de Glass mais une lacune de l'architecture de
déploiement révélée en le testant au-delà de ce que Nord avait couvert
— exactement le même schéma que le Constat #1 de Nord en Phase 2.1.
