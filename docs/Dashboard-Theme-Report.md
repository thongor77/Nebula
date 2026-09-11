# Dashboard Theme Report — Nebula

> Évolution du thème expérimental (2026-09-11, brief
> `Nebula-Showcase-Dashboard-Theme-Brief.docx`). Statut : thème
> **expérimental, non officiel** — validation d'usage quotidien réel en
> cours (voir [`Dashboard-Usability-Log.md`](Dashboard-Usability-Log.md)),
> pas encore un candidat au statut officiel. Fait suite au stress-test
> d'architecture (`Dashboard-Architecture-Stress-Test.md`, 2026-09-10) qui
> a validé, sur le papier puis en exécution réelle, qu'une composition
> triptyque était atteignable sans aucun changement de Core. **Question
> posée par ce brief** : ce même triptyque peut-il devenir un thème
> présentable (polish visuel, screenshots GitHub) et réellement
> utilisable au quotidien, sans jamais rouvrir l'API Core gelée ?
> Périmètre convenu avec l'utilisateur (2026-09-11, via `AskUserQuestion`
> en amont de l'implémentation) : renommage `dashboard-prototype` →
> `dashboard`, identité visuelle indigo/violet ("cosmic"), fond d'écran
> original généré (ImageMagick), captures d'écran limitées au README du
> thème et à ce rapport (pas encore la galerie du README principal — ça
> attend le verdict §13 du brief). L'usage quotidien réel de 1 à 2
> semaines (§10 du brief) et le verdict PROMOTE/KEEP EXPERIMENTAL/RETIRE
> (§13) restent hors de cette session — ce sont des étapes que
> l'utilisateur mène dans la durée, pas quelque chose qu'une session
> unique peut produire.

---

## 1. Réponse à la question posée

**Oui, avec trois vrais bugs de layout trouvés et corrigés par exécution
réelle** (jamais en les raisonnant sur le papier — voir §3). Le thème
final : renommé `themes/dashboard`, identité indigo/violet distincte de
Nord et Glass, contenu par région conforme au brief §2 (plus aucun
panneau simulé, contrairement au prototype), trois paliers responsives
réels, états auth (idle/busy/erreur/succès) sans saut de mise en page,
navigation clavier complète et bouclée, testé avec succès sous
`sddm-greeter-qt6 --test-mode` réel sur l'écran 4K (`DP-7`) de la
machine — aucun avertissement QML, aucune boucle de binding, une seule
vue par écran physique comme attendu. Aucun fichier `core/` modifié.

## 2. Points forts

- **Suppression complète du contenu simulé du prototype** : les cartes
  Host/Battery/Network (texte statique) et le faux label "Layout:
  (selector not implemented)" n'existent plus. Chaque élément visible
  est câblé à un vrai Service Core ; s'il n'a rien à montrer (ex.
  `SDDMPowerAdapter` squelette sous SDDM réel), le composant — ou tout
  le panneau `NebulaSurface` qui le contient — se masque entièrement au
  lieu d'afficher une coquille vide. Confirmé sur le matériel réel : le
  panneau droit est totalement absent sous `sddm-greeter-qt6
  --test-mode` (aucune session/aucune capacité d'alimentation
  aujourd'hui), sans aucune boîte fantôme.
- **Positionnement par x/y numérique plutôt que par `anchors.*`
  conditionnels** pour les deux panneaux latéraux — plus robuste que
  l'approche initiale (voir Constat #1), sans aucun état d'ancrage
  "encore actif après avoir été effacé" à gérer.
- **Une seule animation d'entrée pour tout le triptyque** (fade + scale
  sur `stage`, pas trois animations séparées par panneau) — cohérent
  avec le "restrained" du brief §4, et le fondu de succès
  (`onSucceeded: stage.opacity = 0`) éteint les trois régions ensemble.
- **Chaîne `KeyNavigation.tab`/`backtab` bouclée et symétrique**, vérifiée
  par une marche programmatique du graphe (pas seulement déclarée) :
  `passwordField → unlockButton → sessionSelector → keyboardToggle →
  powerRow → userList → passwordField`, et son exact miroir en sens
  inverse. Focus initial déjà garanti par `NebulaPasswordField`
  lui-même (`Component.onCompleted: input.forceActiveFocus()`, Core
  existant) — rien à dupliquer côté thème.

## 3. Bugs réels trouvés (par exécution, pas sur le papier)

Conformément à la pratique du projet (voir `[[nebula-workflow-feedback]]`
dans la mémoire de session) : `qmllint`/`check-theme.sh` ne peuvent pas
détecter un mauvais positionnement géométrique — seuls `qml6` +
`grabToImage()` (rendu offscreen déterministe, capture réelle) et
`sddm-greeter-qt6 --test-mode` (matériel réel) l'ont révélé.

### Constat #1 — Ancres conditionnelles restées actives après un flip initial (critique, corrigé)

- **Symptôme** : au premier lancement en mode large, les panneaux
  gauche et droit rendaient tous les deux au même endroit,
  géométriquement absurde (largeur = largeur de `stage`, hauteur
  négative), superposant tout leur contenu.
- **Cause** : `anchors.left: root.isNarrow ? undefined : parent.left`
  (et les trois autres lignes d'ancrage équivalentes) — `root.isNarrow`
  vaut transitoirement `true` à la toute première évaluation (avant que
  `root.width` ne se stabilise), activant la branche narrow ; au
  re-calcul suivant (`isNarrow` repasse à `false`), la ligne d'ancrage
  opposée (`anchors.horizontalCenter`) reste active en plus de la
  nouvelle — deux contraintes horizontales simultanées sur le même axe,
  géométrie résultante non définie.
- **Correction** : remplacé par un positionnement `x`/`y` numérique pur
  (voir `themes/dashboard/Main.qml`, commentaire à `contextPanel`) — un
  binding numérique n'a pas cet état "ligne d'ancrage encore active"
  à nettoyer.
- **Portée** : uniquement ce thème (seul thème à combiner des ancres
  conditionnelles multi-axes sur un panneau) — pas un signal de gel de
  Core à rouvrir.

### Constat #2 — Palier medium : le panneau droit chevauchait la carte (critique, corrigé)

- **Symptôme** : à 1000px de large, le panneau droit (session +
  clavier + alimentation) chevauchait la carte centrale sur ~150px.
- **Cause** : `NebulaPowerButtons` contient un `Row` interne fixe de 4
  boutons (~460px de large) — un composant Core qui ne peut pas
  s'enrouler. L'espace réellement laissé à côté de la carte au palier
  medium (mesuré : 248 à 397px selon la largeur) n'est **jamais**
  suffisant pour ce `Row`, même à la largeur maximale du palier.
- **Correction** : le palier medium replie désormais session/clavier/
  alimentation **sous** la carte (comme narrow), tout en gardant le
  panneau gauche (horloge/date, toujours assez étroit) à côté d'elle —
  une compression honnête plutôt qu'un chevauchement caché.
- **Portée** : potentiellement tout thème utilisant `NebulaPowerButtons`
  à une largeur moyenne avec peu d'espace latéral — voir §4 pour la
  piste Core minimale.

### Constat #3 — Palier narrow : la ligne de contrôles débordait l'écran (critique, corrigé)

- **Symptôme** : à 480px de large, "Sleep"/"Hibernate" débordaient hors
  de la fenêtre, texte coupé net au bord.
- **Cause** : même limitation Core que le Constat #2 — le `Flow` du
  panneau de contrôles était contraint à la largeur de la carte (292px),
  plus étroite que le `Row` interne de `NebulaPowerButtons`.
- **Correction** : en narrow, le `Flow` utilise la pleine largeur de
  `stage` (centrée sur `stage`, pas sur la carte) au lieu de la largeur
  de la carte — tous les boutons wrappent et tiennent, vérifié par
  `grabToImage()` à 480/700/900/1000/1199/1400px, plus aucun
  débordement à aucune largeur testée.

## 4. Gap Core réel identifié (documenté, non implémenté)

**`NebulaPowerButtons` n'a ni mode compact/icônes seules, ni `Flow`
interne** — son `Row` de 4 boutons ne peut jamais se réduire ni
s'enrouler. Conséquence mesurée : même en lui donnant toute la largeur
disponible d'un écran de 480px (cas extrême, plus étroit que tout
écran desktop/laptop réaliste), les 4 boutons ne tiennent parfois pas.
Pourquoi la composition côté thème ne peut pas résoudre ça seule : le
`Row` interne n'est pas exposé, un thème ne peut agir que sur ce qui
*entoure* le composant, jamais sur sa mise en page interne. Thèmes
concernés : tout thème `NebulaPowerButtons` à espace latéral contraint
— aujourd'hui uniquement Dashboard le mesure vraiment, mais Nord/Glass/
Template y seraient tout autant exposés dans un contexte étroit.
Changement Core minimal proposé (non implémenté, un seul thème ne
suffit pas au critère du gel d'API) : remplacer le `Row` interne par un
`Flow`, ou ajouter une propriété `compact`/`iconOnly` optionnelle. À
implémenter seulement si un second thème démontre le même besoin.

## 5. Validation

- `qmllint themes/dashboard/Main.qml` — propre, exit 0. Balayage complet
  du dépôt (`find . -name "*.qml" | xargs qmllint`, identique au CI) —
  propre également.
- `scripts/check-theme.sh dashboard` — `PASS`. Re-testé sur
  `nord`/`glass-dark`/`glass-light`/`template` — tous `PASS`, aucune
  régression.
- `tests/ThemeHarness.qml -- dashboard` (offscreen) — 17 tokens chargés,
  zéro avertissement `Unknown token`.
- États d'authentification — testés via une séquence scriptée
  (`SequentialAnimation` + `grabToImage()`) pilotant directement
  `NebulaAuthService.authenticate()` avec `MockAuthAdapter` (le seul
  moyen d'exercer un vrai échec, `--test-mode` n'authentifie jamais
  réellement) : idle → busy ("Authenticating…", champ désactivé,
  bouton désactivé) → erreur ("Mock authentication failure" en rouge,
  bordure rouge, **carte de même taille qu'à l'idle** — confirmation
  visuelle qu'il n'y a aucun saut de mise en page) → succès (les trois
  régions du triptyque s'estompent ensemble).
- Navigation clavier — marche programmatique du graphe
  `KeyNavigation.tab`/`backtab` (voir §2) plutôt qu'une simulation de
  frappe (confirmé de longue date sur ce projet : `xdotool` ne peut pas
  piloter une fenêtre Wayland native `qml6`).
- Responsive — 6 largeurs balayées en offscreen (480/750/900/1000/
  1199/1400px), les trois Constats ci-dessus trouvés et corrigés puis
  re-vérifiés à chaque largeur, plus aucun chevauchement ni débordement
  mesuré (vérification programmatique des bords, pas seulement visuelle).
- **Matériel réel** : `sddm-greeter-qt6 --test-mode --theme
  themes/dashboard` sur le poste de développement (3 écrans réels,
  `eDP-1`/`DP-7`/`DP-9`, mixed-DPI, EndeavourOS/SDDM 0.21/Qt 6.11.1).
  Log de démarrage vide (aucun avertissement). Trois vues indépendantes
  confirmées, une par écran physique. Utilisateurs système réels
  chargés par `SDDMUserAdapter` (confirmation que l'adaptateur
  fonctionne bel et bien, au-delà du cas mock) — capture d'écran de
  cette validation gardée en preuve technique
  (`photos/dashboard/multi-monitor.png`) mais **jamais utilisée comme
  visuel de présentation** (voir §6, hygiène des captures).
- Échelle — la portion offscreen du balayage responsive n'est pas
  affectée par le facteur d'échelle du bureau (dimensions logiques
  explicites), couvrant de fait l'équivalent d'une échelle 1.0 ; les 3
  écrans réels du poste sont tous nativement à l'échelle ~1.4
  (confirmé par `xrandr`), donc le passage matériel réel couvre
  l'échelle 1.4.

## 6. Hygiène des captures (brief §12)

Les captures issues du greeter réel exposent les noms d'utilisateurs
système réels (`SDDMUserAdapter` charge le vrai `userModel`) — non
conformes à l'exigence "nom d'utilisateur/avatar non sensible" du
brief. Les visuels de présentation (`hero.png`, `detail.png`,
`responsive.png` dans `themes/dashboard/README.md` et ce rapport)
utilisent donc les rendus `grabToImage()` avec `MockUserAdapter`
("Nebula User"/"Alice"/"Bob", entièrement synthétiques) plutôt que les
captures matériel réel. `multi-monitor.png` reste la seule capture
matériel réel conservée, comme preuve technique de robustesse
multi-écran — les trois zones de nom d'utilisateur y ont été
retouchées (rectangle plein à la couleur `surfaceColor`) avant tout
commit, décision prise avec l'utilisateur plutôt que silencieusement.

## 7. Critère de fin

Le thème existe sous `themes/dashboard/`, conforme au SDK
(`check-theme.sh` PASS), avec une identité visuelle propre, un
comportement responsive réel à trois paliers vérifié programmatiquement
et visuellement, zéro contenu simulé, et une validation matérielle réelle
réussie sur écran 4K. Ce rapport documente le point de départ de
l'expérience d'usage quotidien (§10 du brief) — la suite (journal
d'usage, verdict §13) vit dans
[`Dashboard-Usability-Log.md`](Dashboard-Usability-Log.md) et appartient
à l'utilisateur, pas à cette session.
