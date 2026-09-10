# Developer Experience Review 01 — Nebula (2026-08-03)

> Revue menée du point de vue d'un développeur découvrant Nebula
> aujourd'hui sur GitHub, sans aucune connaissance préalable du projet.
> Question posée : un développeur ne connaissant absolument pas Nebula
> peut-il créer son premier thème sans aide extérieure ? Méthode :
> lecture stricte des seuls documents indiqués à chaque partie, sans
> jamais combler un manque par une connaissance acquise pendant le
> développement du projet — une information qui n'est trouvable que
> parce qu'elle a été écrite plusieurs phases plus tôt et jamais
> republiée au bon endroit est considérée absente. Aucune modification
> de code ou de documentation n'a été faite pendant cette revue (lecture
> seule).

---

## 1. Première impression (README.md seul)

**Comprend-on immédiatement ce qu'est Nebula ?** Oui — la première
phrase après le tagline répond directement et sans ambiguïté à "qu'est-ce
que Nebula n'est pas" : *"Nebula is not a collection of unrelated SDDM
login themes. It is a modular framework."* C'est exactement la bonne
information en premier, formulée en négatif puis en positif. Rare qu'un
README réponde aussi vite à cette question précise.

**Le public visé est-il évident ?** Non, c'est la première vraie
ambiguïté. Le README mélange deux publics sans les distinguer
explicitement : un utilisateur final qui veut juste un bel écran de
connexion (`sudo scripts/install-nebula.sh nord`, section Installation,
très accessible) et un développeur de thème/contributeur (toute la
section Documentation, 33 entrées, très technique). Un visiteur venu
chercher "un joli thème SDDM" tombe, deux paragraphes plus loin, sur une
liste de 15 noms de composants (`NebulaThemeConfig`/`NebulaThemeProvider`/
`NebulaThemeLoader`, `NebulaButton`, ...) dans le paragraphe Status —
information de développeur, sans utilité pour lui, avant même d'avoir vu
comment installer quoi que ce soit.

**Le README donne-t-il envie de poursuivre ?** Globalement oui pour un
développeur (structure claire, section Installation immédiatement
actionnable avec une seule commande), mais la densité technique du
paragraphe Status ralentit l'élan initial — c'est un paragraphe de
statut de projet (utile pour juger la maturité), pas un paragraphe
d'accroche.

Ambiguïté supplémentaire : la table de documentation qui suit (§7)
présente **33 documents** sans aucun ordre de lecture suggéré au-delà du
regroupement par catégorie — un nouveau venu n'a aucun signal du type
"commencez ici, le reste est pour plus tard".

## 2. Installation (documentation officielle uniquement)

`docs/Installation.md` §1 donne une commande directe pour tester sans
installation :

```bash
sddm-greeter-qt6 --test-mode --theme themes/nord
```

Suivie littéralement, sans consulter `Development-Environment.md`
(lien fourni mais pas lu, par hypothèse de cette revue), cette commande
a un piège documenté ailleurs mais pas ici : `NebulaThemeLoader` a
besoin de `QML_XHR_ALLOW_FILE_READ=1` pour lire `theme.conf` — sans
cette variable, le thème se charge quand même mais garde les couleurs
neutres du Core, **sans aucun message d'erreur visible** (ce fait est
lui-même documenté, mais seulement dans la section Dépannage tout en
bas de ce même document, §6, jamais à côté de la commande §1 qui
l'expose). Un développeur qui suit §1 à la lettre et obtient un thème
aux couleurs grises se demandera si Nebula fonctionne, pas s'il manque
une variable d'environnement.

§2 (installation système) a un piège de flux similaire, plus grave pour
la confiance dans l'outil : après `sudo scripts/install-nebula.sh nord`,
rien ne change visuellement sur la machine — activer le thème est une
étape manuelle distincte (section "Activer le thème installé", plusieurs
paragraphes après la commande d'installation). C'est un choix de design
défendable et bien expliqué une fois qu'on l'a lu, mais l'ordre de
présentation (commande d'abord, avertissement après) inverse ce qu'un
nouveau venu a besoin de savoir avant d'agir.

Points forts : prérequis clairement listés dans le README (§ Requirements,
Plasma 6/SDDM 0.21+/Qt6), section §6 "Résolution des problèmes courants"
réellement utile et bien croisée avec les bonnes causes (`DT-0023`,
`safe.directory`, etc.), `scripts/check-installation.sh` offre une
vérification sans risque après coup.

## 3. Découverte du SDK (Theme-SDK.md, Creating-A-Theme.md, Template, Core-API.md uniquement)

Ordre imposé par la documentation elle-même — cohérent : `Creating-A-
Theme.md` dit explicitement de lire `Theme-SDK.md` en premier, et
`Theme-SDK.md` renvoie vers `Creating-A-Theme.md` pour le tutoriel. Bon
signal : les deux documents savent l'un de l'autre et ne se recopient
pas.

**Trouvaille la plus importante de toute cette revue** : l'en-tête de
`docs/Core-API.md` (ligne 12) affirme *"Aucune implémentation ici —
uniquement le contrat que l'implémentation devra respecter (Phase 1,
voir Roadmap.md)."* Or c'est précisément le document que `Theme-SDK.md`
et `Creating-A-Theme.md` désignent tous les deux comme LA référence pour
savoir ce que chaque composant fait réellement. Un nouveau venu qui
arrive sur ce document — après avoir déjà lu que le README annonce une
API "gelée" et des composants "implemented, documented, and exercised by
real themes" — se retrouve face à une phrase qui dit le contraire :
que ce document ne serait qu'une spécification pré-implémentation. C'est
une contradiction frontale entre deux documents qu'un nouveau
contributeur lira à quelques minutes d'intervalle, exactement au moment
où il a le plus besoin de faire confiance à la doc. Aucune connaissance
du développement du projet n'est nécessaire pour repérer ce problème —
c'est visible en lisant seulement ces deux fichiers.

Séquencement à l'intérieur de `Theme-SDK.md` : §4 ("Ce qu'un thème ne
doit jamais faire") arrive après §1-3 (structure, contenu, conventions).
Le document demande d'être lu en entier, donc ce n'est pas bloquant,
mais placer les interdits dès le paragraphe 2 éviterait qu'un lecteur
pressé commence à expérimenter avant de les avoir vus.

Notion qui arrive tard : la liste réelle des tokens valides
(`Design-Tokens-Reference.md`) n'est jamais donnée en ligne — seulement
liée. Le `theme.conf` du Template (lu en Partie 4) sert dans les faits
de référence plus rapide que le document dédié, mais rien ne le signale
explicitement comme tel.

`Creating-A-Theme.md` §7 ("Test as you go") est le meilleur passage de
toute la documentation SDK du point de vue d'un nouveau venu : trois
outils, dans l'ordre exact où on en a besoin, chacun avec la commande
exacte à taper. C'est le seul endroit de toute la doc SDK qui dit
précisément quoi taper, dans quel ordre, et pourquoi.

## 4. Le Template (`themes/template/`)

`theme.conf` (52 lignes) est un exemple pédagogique réussi : chaque
token a sa valeur par défaut, un commentaire d'en-tête explique quoi
changer et quoi ne pas changer, et le fichier sert de facto de
référence de tokens plus rapide que la documentation dédiée (voir §3).

`Main.qml` (163 lignes) est nettement moins "minimal" que ce que le mot
Template suggère. Il contient : 4 Services complets, câblés à de vrais
adapters `platform/sddm/`, 9 composants Core différents imbriqués
(Background → Wallpaper → Overlay → LoginLayout → Surface → Column →
Clock/Date/UserList/PasswordField/Button, plus footer avec bascule
clavier virtuel, sélecteur de session, boutons d'alimentation). C'est
un **écran de connexion de démonstration complet et fonctionnel**, pas
un point de départ minimal — les deux objectifs sont légitimes mais en
tension, et le Template n'a aujourd'hui qu'une seule forme, qui sert le
second objectif (référence technique complète) au détriment du premier
(outil pédagogique). Rien dans le fichier n'indique visuellement quels
blocs sont indispensables (le câblage `theme`/`ThemeLoader`/
`ThemeProvider`, par exemple) et lesquels sont optionnels
(`NebulaVirtualKeyboard`, `NebulaSessionSelector`, le bouton clavier
virtuel dans le footer) — un nouveau venu qui veut un thème simple sans
authentification multi-session doit deviner ce qui est sûr à retirer.

Aucun fichier inutile ou intimidant trouvé par ailleurs : `metadata.desktop`
est court et chaque champ est explicite ; `preview.png` fait son travail
de placeholder ; `assets/{wallpapers,icons,fonts}/` sont vides avec un
simple `.gitkeep`, sans confusion possible. `README.md` du Template
(déjà lu lors de la précédente revue) reste court et pointe correctement
vers `Creating-A-Theme.md`.

## 5. Créer un premier thème (Template + SDK + doc uniquement, sans regarder les autres thèmes)

En suivant seulement `Creating-A-Theme.md` §1 à §7 : `cp -r
themes/template themes/mytheme`, changer quelques couleurs dans
`theme.conf`, lancer `qmllint`, puis `ThemeHarness.qml`, puis
`check-theme.sh` — ce chemin fonctionne et est réellement sans blocage.
C'est un point fort net.

Blocages/hésitations dès qu'on veut aller au-delà d'un simple changement
de couleurs :

- Aucune indication sur ce qui, dans `Main.qml`, peut être retiré en
  toute sécurité pour un thème plus simple (voir §4).
- `Theme-SDK.md` §2 dit qu'un thème fournit "sa configuration — quels
  composants optionnels sont activés" mais ne dit nulle part *comment*
  rendre un composant optionnel dans `Main.qml` au-delà de ce que le
  Template montre déjà tout câblé — pas d'exemple de thème volontairement
  incomplet dans la doc SDK elle-même (Nord, qui est justement cet
  exemple dans le dépôt, est explicitement hors périmètre de cette
  partie de la revue).
- Question sans réponse dans les documents autorisés : pourquoi
  `NebulaPasswordField.username` doit être câblé manuellement depuis
  `userList.currentUser.name` plutôt que dérivé automatiquement d'un
  service ? Le Template le fait (copié tel quel, ça fonctionne), mais
  aucun des quatre documents de cette partie n'explique pourquoi ce
  câblage existe — un nouveau venu le reproduit par imitation, pas par
  compréhension.

## 6. Messages d'erreur

Point fort net : `scripts/check-theme.sh` produit des messages
directement actionnables et qui renvoient vers le bon document à chaque
fois — `"FAIL: unknown token 'x' (not in NebulaThemeConfig — see
docs/Design-Tokens-Reference.md)"`, `"FAIL: overrides/ found — not part
of the SDK contract... see Theme-SDK.md §1"`. Exactement le niveau de
qualité attendu d'un outil de validation.

Deux lacunes réelles, correspondant aux exemples cités par le brief de
cette revue :

- **Image absente** : `NebulaWallpaper`/`NebulaAvatar` se replient
  silencieusement sur une couleur/silhouette si le fichier référencé est
  introuvable — **aucun message, nulle part**, ni dans la console ni
  dans l'UI (comportement documenté comme volontaire dans le code :
  "no error handling beyond that is needed"). Bon choix de robustesse
  pour la production, mauvais pour un débutant qui a fait une faute de
  frappe dans un chemin d'asset : il voit juste "mon image n'apparaît
  pas" sans aucun indice sur la cause.
- **Token inconnu dans `theme.conf`** : bien signalé par
  `check-theme.sh` (voir ci-dessus) *si* le développeur pense à lancer
  cet outil. S'il ne teste que via `sddm-greeter --test-mode`
  directement, `NebulaThemeLoader` logge bien
  `"[NebulaThemeLoader] Unknown token: x -- ignored."`, mais uniquement
  dans les logs système (`journalctl`) — invisible tant qu'on n'a pas lu
  `Development-Environment.md` pour savoir où regarder. Le thème
  continue de se charger avec la valeur par défaut, sans échec visible.

**Thème incomplet** (composant sans `Service` requis assigné) : QML lève
une erreur de chargement franche (`required property` non fournie) — le
comportement natif de Qt Quick, pas un message spécifique à Nebula, mais
suffisamment clair par lui-même.

## 7. Documentation — navigation, cohérence

Le point le plus structurant de toute cette revue : **34 fichiers** sous
`docs/` (avant cette revue), tous croisés-référencés avec soin et sans
duplication de contenu constatée (chaque sujet a un seul document qui en
est la source, les autres y renvoient plutôt que de répéter — pratique
suivie sans exception dans les documents lus). C'est une vraie qualité
de fond. Mais le volume lui-même est le problème de navigation : rien ne
distingue "les 4-5 documents qu'il faut lire pour commencer" des "29
documents de référence/historique à consulter au besoin" — la table du
README les présente tous au même niveau, seulement groupés par thème
large (Getting started / Architecture / Validation / Historique).

Incohérence concrète trouvée (voir §3) : `Core-API.md` en-tête vs
README §Status — la même information (l'API est-elle implémentée ?) a
deux réponses opposées selon le document ouvert.

Aucun autre endroit où un lecteur suivant strictement les parcours
demandés (README → Installation → SDK → Template) risquerait de se
perdre — les renvois internes (`voir X.md §Y`) sont systématiquement
présents et pointent au bon endroit dans tous les documents lus pour
cette revue.

## 8. API publique (regard neuf)

Noms intuitifs et cohérents dans l'ensemble : préfixe `Nebula` sans
exception, `theme`/`<domaine>Service` comme noms de propriété requise
répétés à l'identique sur chaque composant, signaux `xRequested`/
`xSelected`/`submitted`/`cleared` prévisibles d'un composant à l'autre.
Valeurs par défaut logiques (`variant: "primary"`,
`confirmBeforeAction: false`, `showToggleEnabled: true`) — aucune
n'exige de lire le code source pour deviner un comportement surprenant.

Un seul endroit où un nouveau venu pourrait raisonnablement se tromper,
déjà noté en §5 : `NebulaPasswordField.username` est une simple
`string` à fournir soi-même plutôt qu'une résolution automatique depuis
un Service utilisateur — fonctionne très bien une fois copié depuis le
Template, mais l'API à elle seule ne dit pas pourquoi ce choix a été
fait, ce qui peut donner l'impression d'un oubli plutôt que d'un choix
(alors que c'est un choix, voir la revue d'architecture précédente,
`docs/Architecture-Review-2026.md` §2/§10, qui recommande déjà de le
documenter).

## 9. Temps d'apprentissage estimé

- **Comprendre ce qu'est Nebula** (README + un survol d'Architecture.md) :
  ~15-20 minutes.
- **Créer un premier thème en changeant seulement les couleurs** (copier
  le Template, éditer `theme.conf`, valider avec les 3 outils de
  `Creating-A-Theme.md` §7) : ~15-20 minutes — le chemin le plus rapide
  et le plus fiable de toute la documentation.
- **Comprendre le système de tokens** (théorie + `theme.conf` du
  Template comme référence pratique) : ~10-15 minutes.
- **Personnaliser réellement `Main.qml`** (comprendre quels blocs
  toucher, lesquels laisser, pourquoi le câblage `username` existe) :
  1 à 2 heures, principalement à cause des zones d'ombre identifiées en
  §5 et §8 — pas à cause d'une complexité du code lui-même (le fichier
  est propre et lisible), mais du manque de repères explicites sur ce
  qui est obligatoire.

**Total réaliste pour un premier thème fonctionnel et compris (pas
seulement copié)** : une demi-journée. Pour un simple reskin de couleurs
sans rien comprendre en profondeur : moins de 30 minutes — chemin déjà
très bien pavé.

## 10. Expérience générale — notes sur 10

| Catégorie | Note | Justification |
|---|---|---|
| Découverte du projet | 7/10 | Réponse claire à "ce que Nebula n'est pas" dès la première phrase ; pénalisé par l'ambiguïté du public visé et la densité technique prématurée du paragraphe Status. |
| Documentation | 7/10 | Qualité de contenu et cohérence des renvois excellentes ; pénalisée par le volume (34 fichiers) sans hiérarchie de lecture, et par la contradiction Core-API.md/README trouvée en §3. |
| SDK | 8/10 | `Theme-SDK.md`/`Creating-A-Theme.md` forment un parcours cohérent et actionnable, le meilleur sous-ensemble de toute la documentation ; pénalisé par la contradiction de l'en-tête de `Core-API.md`. |
| API | 8/10 | Nommage et valeurs par défaut intuitifs sans exception trouvée ; un seul point de confusion réel (`username` non automatique), déjà identifié et documenté comme choix légitime ailleurs. |
| Installation | 7/10 | Section dépannage solide, commande unique pour démarrer ; pénalisée par l'ordre de présentation de deux pièges réels (XHR local, activation manuelle) après plutôt qu'avant la commande concernée. |
| Création d'un premier thème | 7/10 | Chemin "juste les couleurs" quasi parfait ; chemin "je veux comprendre/adapter la mise en page" nettement plus rugueux faute de Template réellement minimal. |
| Compréhension globale | 7/10 | Le projet est cohérent et bien pensé une fois compris, mais rien ne dit à un nouveau venu qu'il n'a besoin de lire que 4-5 documents pour commencer — il doit le découvrir lui-même. |

**Moyenne : 7,3/10.** Un projet dont la profondeur documentaire est un
vrai atout une fois qu'on sait où regarder, mais qui ne guide pas encore
activement un nouveau venu vers le sous-ensemble minimal dont il a
besoin.

## 11. Quick Wins (effort/impact, documentation/organisation/messages/pédagogie uniquement)

**Très fort impact**

- Corriger l'en-tête de `docs/Core-API.md` ("Aucune implémentation
  ici...") pour refléter l'état réel (implémenté, API gelée) — une
  phrase, contradiction directe avec le README résolue, trouvée par le
  premier nouveau venu qui lira les deux documents à la suite.
- Ajouter, dans le README ou en tête de la table de documentation, un
  chemin de lecture explicite en 4-5 documents pour "je veux juste créer
  un thème" (`Installation.md` §1 → `Theme-SDK.md` → `Creating-A-
  Theme.md` → `Core-API.md`), le reste étant explicitement labellisé
  "référence, à consulter au besoin".

**Fort impact**

- Déplacer/dupliquer l'avertissement `QML_XHR_ALLOW_FILE_READ` (couleurs
  silencieusement fausses) directement à côté de la commande §1 de
  `Installation.md`, pas seulement dans la section Dépannage.
- Ajouter un court avertissement juste après la commande
  `sudo scripts/install-nebula.sh` rappelant qu'activer le thème est une
  étape manuelle séparée (déjà documentée, seulement mal placée).
- Ajouter un `console.warn` quand `NebulaWallpaper`/`NebulaAvatar` ne
  parviennent pas à charger une image fournie explicitement (distinct du
  cas "aucune source fournie", qui doit rester silencieux) — rend visible
  l'erreur "image absente" citée en exemple par cette revue.

**Impact moyen**

- Annoter `themes/template/Main.qml` (commentaires) pour distinguer
  explicitement le câblage obligatoire (theme/services de base) des
  blocs optionnels (clavier virtuel, sélecteur de session, boutons
  d'alimentation) — évite d'avoir à deviner ce qui est sûr à retirer.
- Documenter en une phrase, dans `Login-Architecture.md` ou
  `Core-API.md`, pourquoi `NebulaPasswordField.username` est fourni
  manuellement plutôt que dérivé automatiquement (déjà recommandé dans
  `docs/Architecture-Review-2026.md`, Recommandation 4 — même
  correction, deux angles différents la justifient).

**Faible impact**

- Réordonner `Theme-SDK.md` pour placer §4 ("Ce qu'un thème ne doit
  jamais faire") plus tôt — le document est de toute façon lu en
  entier avant de commencer, donc gain marginal.
- Signaler plus visiblement, dans `Theme-SDK.md` §6, que
  `scripts/test-theme.sh` n'existe pas encore (déjà écrit, mais noyé
  dans une liste à trois éléments dont deux fonctionnent réellement).

## 12. Ce qu'il ne faut surtout pas changer

- **`docs/Creating-A-Theme.md`**, en particulier son §7 ("Test as you
  go") — le meilleur exemple de toute la documentation d'instructions
  concrètes, dans le bon ordre, avec la commande exacte à chaque étape.
  Modèle à reproduire ailleurs, pas à modifier ici.
- **Le renvoi croisé systématique `Theme-SDK.md` ↔ `Creating-A-
  Theme.md`** ("normatif" vs "tutoriel", chacun ne répétant jamais
  l'autre) — organisation à préserver telle quelle pour tout futur
  document du même type.
- **`themes/template/theme.conf`** — exemple pédagogique déjà réussi en
  l'état (commentaires, valeurs neutres, sert de référence de tokens
  plus rapide que la doc dédiée). Ne pas le complexifier.
- **Les messages d'erreur de `scripts/check-theme.sh`** — le niveau de
  qualité ("quoi", "pourquoi", "où en savoir plus" dans un seul message)
  à répliquer si d'autres outils de validation sont ajoutés.
- **La convention de nommage `Nebula*`/`theme`/`<domaine>Service`** —
  déjà jugée intuitive et sans exception ; toute future API doit s'y
  conformer, pas la faire évoluer.
- **La séparation stricte README (accroche + structure) / docs/
  (détail)** — le README ne doit pas grossir avec plus de détail
  technique ; le problème identifié en §1 est un problème d'ordre et de
  densité du paragraphe Status, pas un manque de contenu à ajouter.

---

## Ce qui est excellent

- Réponse immédiate et sans ambiguïté, dès la première phrase du README,
  à "qu'est-ce que Nebula n'est pas".
- `docs/Creating-A-Theme.md`, en particulier son §7 — instructions
  concrètes, ordonnées, testables à chaque étape.
- Cohérence des renvois croisés entre documents : aucune duplication de
  contenu trouvée, chaque sujet a une seule source de vérité.
- Messages d'erreur de `scripts/check-theme.sh` : actionnables et
  toujours reliés à la bonne documentation.
- `theme.conf` du Template : référence de tokens pratique et
  immédiatement utilisable, mieux que le document dédié pour démarrer.
- Convention de nommage de l'API publique : intuitive et sans exception
  trouvée sur l'ensemble des composants lus.
- Chemin "je veux juste changer les couleurs" : rapide, fiable, sans
  blocage — moins de 20 minutes du clone à un thème personnalisé validé.

## Les premiers points de friction

- Public visé ambigu dans le README (utilisateur final vs développeur de
  thème mélangés sans distinction).
- Paragraphe Status du README trop technique trop tôt (liste de 15 noms
  de composants avant même la section Installation).
- Deux pièges d'installation réels documentés, mais après la commande
  concernée plutôt qu'à côté (`QML_XHR_ALLOW_FILE_READ`, activation
  manuelle du thème).
- Template non minimal : 163 lignes entièrement câblées, aucun signal
  sur ce qui est obligatoire vs optionnel.
- Aucun message d'erreur pour une image d'asset introuvable — échec
  silencieux.

## Les informations difficiles à trouver

- La contradiction directe entre `docs/Core-API.md` (en-tête : "aucune
  implémentation") et le README (§Status : "implemented... frozen") —
  ne se découvre qu'en lisant les deux à quelques minutes d'intervalle,
  sans qu'aucun renvoi ne prévienne le lecteur.
- Pourquoi `NebulaPasswordField.username` est câblé manuellement plutôt
  qu'automatique — absent des quatre documents du parcours SDK.
- Ce qui, dans `Main.qml` du Template, est réellement optionnel — non
  écrit nulle part, seulement déductible en lisant le code source des
  composants eux-mêmes (hors périmètre d'un nouveau venu suivant
  strictement la documentation).
- Le fait que `theme.conf` mal formé (token inconnu) échoue
  silencieusement sauf si on pense à lancer `check-theme.sh` ou à lire
  les logs système.

## Les améliorations prioritaires

Voir §11 (Quick Wins) pour le détail classé par impact. En résumé, dans
l'ordre : corriger l'en-tête contradictoire de `Core-API.md`, ajouter un
chemin de lecture minimal explicite, déplacer les deux avertissements
d'installation à côté de la commande concernée, ajouter un avertissement
sur les images introuvables.

## Les éléments déjà suffisamment bons

Voir §12 pour la liste complète et argumentée. En résumé :
`Creating-A-Theme.md`, la relation `Theme-SDK.md`/`Creating-A-Theme.md`,
`theme.conf` du Template, les messages de `check-theme.sh`, la
convention de nommage de l'API, et la structure générale README/docs —
tous à préserver sans modification.

## Conclusion générale

Un développeur ne connaissant pas Nebula **peut** créer un premier thème
sans aide extérieure, à condition de se limiter à un reskin de couleurs
via le Template — ce chemin précis est rapide, fiable, et bien
documenté de bout en bout (moins de 20 minutes, sans blocage rencontré
pendant cette revue). Dès qu'il cherche à comprendre ou modifier la mise
en page au-delà de ce que le Template montre déjà, l'expérience se
dégrade : le Template ne distingue pas l'obligatoire de l'optionnel, et
au moins une contradiction documentaire réelle (`Core-API.md` vs README)
peut faire douter un nouveau venu de la maturité du projet au pire
moment — juste après avoir lu qu'elle est justement acquise. Aucun de
ces problèmes n'est structurel : ce sont des corrections de quelques
phrases ou de réordonnancement, jamais une refonte. Note globale
7,3/10 — un projet dont la documentation est déjà largement au-dessus de
la moyenne du genre, freiné par des détails de présentation plutôt que
par un manque de contenu.
