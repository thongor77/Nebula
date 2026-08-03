# VK-001 — Clavier virtuel Qt (`qtvirtualkeyboard`) démesuré

> Investigation indépendante du développement des thèmes (voir brief
> `~/Desktop/Projet Nebula/brief-experimentation.md`). Contrainte du
> brief : aucune conclusion sans preuve expérimentale, ne jamais modifier
> le Core pendant l'investigation elle-même. Menée sous le vrai
> `sddm.service` (jamais `--test-mode`, qui ne reflète pas la détection
> DPI réelle du serveur X du greeter), protocole sûr respecté (voir
> `vt-switch-incident-context.md` / mémoire `nebula-vt-switch-freeze`) —
> greeter observé sans session bureau (`kwin_wayland`) vivante en
> parallèle.
>
> Corrige et remplace le diagnostic provisoire de
> `Compatibility-Matrix.md` §10 (2026-07-31), qui concluait à tort que ce
> n'était "pas un bug Nebula" — voir Conclusion ci-dessous.

---

## Résumé

Le clavier virtuel apparaît automatiquement, à une taille démesurée et
**fixe** (ne change pas en changeant d'écran), sur tout thème Nebula
utilisant un vrai champ de saisie. Cause identifiée avec certitude,
jusqu'au niveau des symboles binaires réels de `libQt6VirtualKeyboard.so` :
**Nebula ne fournit nulle part de composant `InputPanel`** (l'item QML
que Qt Virtual Keyboard attend qu'une application héberge elle-même,
"Application Integration"). En son absence, Qt Virtual Keyboard retombe
sur son propre mécanisme de secours ("Desktop Integration",
`QtVirtualKeyboard::DesktopInputPanel`), qui crée une fenêtre séparée,
entièrement déconnectée de l'arbre QML et du système d'échelle de
l'application — d'où la taille figée, indépendante de l'écran et des
variables Qt standard.

## Partie 1 — Comparaison des thèmes sous le vrai `sddm.service`

| Thème | Comportement du clavier |
|---|---|
| `breeze` (officiel KDE) | N'apparaît **jamais automatiquement** — bouton de bascule manuel en bas à gauche (`virtualKeyboardButton` dans `Main.qml`), appelant `inputPanel.showHide()`. |
| `template` (Nebula, minimal) | Apparaît automatiquement dès le focus du champ password, démesuré. |
| `nord` | **N/A** — n'a jamais eu de vrai champ password (voir `themes/nord/Main.qml`, commentaire + `Nord-Validation-Report.md` : scope Phase 2.1, `authService.authenticate(username, "")` codé en dur). Aucun `TextInput` à focus, donc aucune possibilité de déclencher le clavier, peu importe le bug. Pas une preuve négative. |
| `glass-dark` | Apparaît automatiquement, démesuré — confirmé le 2026-08-03 pendant la validation Phase 3.2 (`photos/3-screens.jpg`, référencé dans `Real-Adapter-Validation.md`), et suit le focus clavier (seul l'écran actif l'affiche). |

`grep` sur `core/`, `themes/`, `platform/` : **zéro** référence à
`InputPanel`/`VirtualKeyboard`/`InputMethod`. `breeze/Main.qml` en
contient plusieurs (`VirtualKeyboardLoader`, composant KDE partagé réel :
`/usr/lib/qt6/qml/org/kde/breeze/components/VirtualKeyboardLoader.qml`).

**Conclusion Partie 1** : le facteur commun n'est pas un thème
particulier mais l'absence, dans tout le Core Nebula, d'un composant
gérant explicitement le clavier virtuel.

## Partie 2 — DPI réel : greeter (X11) vs session réelle (Wayland)

| Écran | Résolution | Taille physique (EDID) | DPI physique réel | Échelle KWin réelle (Wayland) | `devicePixelRatio` vu par Qt sur le greeter |
|---|---|---|---|---|---|
| eDP (laptop) | 2560×1440 | 310×174mm | ~210 dpi | 1.4 | 1 |
| DisplayPort-6 (4K) | 3840×2160 | 597×336mm | ~163 dpi | 1.4 | 1 |
| DisplayPort-8 (HD) | 1920×1200 | 518×324mm | ~94 dpi | 1.0 | 1 |

- `xdpyinfo` (protocole X11 core) ne rapporte qu'**une valeur globale**
  (96 dpi) pour tout l'écran virtuel combiné — limitation structurelle
  d'X11 (un seul "screen", aucune notion native de DPI par sortie).
- Le vrai bureau (`~/.config/kwinoutputconfig.json`) configure une
  échelle fractionnaire **différente par sortie** (1.4 / 1.4 / 1.0),
  confirmant le contexte du brief d'origine ("facteurs d'échelle 1.0 et
  1.4").
- Interrogé directement via Qt (`qml6` + `Qt.application.screens` sur le
  display réel du greeter, `DISPLAY=:0` + xauth du greeter) :
  `devicePixelRatio` vaut **1 sur les 3 écrans**, sans exception. Aucune
  variable Qt liée au HiDPI n'est positionnée nulle part
  (`GreeterEnvironment` de Nebula ne fixe que
  `QML_XHR_ALLOW_FILE_READ=1`).

**Conclusion Partie 2** : écart mesurable et réel (rapport 2.2× de
densité physique entre écrans), mais — voir Partie 3 — ne suffit pas à
lui seul à expliquer le symptôme.

## Partie 3 — Variables Qt testées une par une (sur `template`, réel `sddm.service`)

| Variable testée | Valeur | Effet sur le reste de l'UI | Effet sur le clavier |
|---|---|---|---|
| `QT_AUTO_SCREEN_SCALE_FACTOR` | `1` | Aucun changement visible | Aucun |
| `QT_AUTO_SCREEN_SCALE_FACTOR` | `2` | Aucun changement visible | Aucun |
| `QT_SCALE_FACTOR` | `2` | **Tout double** (horloge, avatar, boutons, texte) | **Aucun changement** |

Chaque variable vérifiée comme réellement propagée au process réel du
greeter (`/proc/<pid>/environ`, PID du vrai process Qt — pas
`sddm-helper`, qui matche aussi le nom en ligne de commande et a piégé
une première vérification).

**Conclusion Partie 3 (résultat le plus net de l'investigation)** : le
clavier ne réagit à **aucune** variable de mise à l'échelle Qt standard,
alors que `QT_SCALE_FACTOR=2` prouve sans ambiguïté que ces variables
sont bien actives et appliquées au reste de la scène QML. Le clavier
n'est donc pas seulement mal dimensionné — il est rendu par un mécanisme
qui ne participe pas du tout au même pipeline de mise à l'échelle que
l'application.

Parties restantes du plan Qt (`QT_FONT_DPI`,
`QT_ENABLE_HIGHDPI_SCALING`, `QT_SCALE_FACTOR_ROUNDING_POLICY`) non
testées individuellement — décision explicite de l'utilisateur
(2026-08-03) une fois ce résultat obtenu, jugé suffisamment concluant
pour ne pas continuer à tester des variantes du même mécanisme.

## Partie 5 — Étude du composant Qt Virtual Keyboard réel (lecture seule)

Fichiers réels lus sur la machine (`/usr/lib/qt6/qml/QtQuick/VirtualKeyboard/`,
`/usr/lib/libQt6VirtualKeyboard.so`) :

- `InputPanel.qml`, documentation officielle en tête de fichier : *"The
  keyboard size is automatically calculated from the available width...
  the application should only set the width and y coordinates of the
  InputPanel, and not the height."* — la hauteur n'est **jamais**
  indépendante : elle dérive du `width` que l'application assigne
  explicitement, via le ratio d'aspect du style
  (`KeyboardStyle.scaleHint = keyboardHeight / keyboardDesignHeight`).
  Sans application qui instancie `InputPanel` et lui assigne un `width`
  réel, rien ne dérive jamais une hauteur cohérente avec un écran donné.
- `strings` sur `libQt6VirtualKeyboard.so` révèle deux classes C++
  distinctes et mutuellement exclusives :
  - `QtVirtualKeyboard::AppInputPanel` — utilisée quand l'app fournit son
    propre item QML `InputPanel` ("Application Integration"), qui
    s'enregistre via `QVirtualKeyboardInputContextPrivate::registerInputPanel()`.
  - `QtVirtualKeyboard::DesktopInputPanel` — mécanisme de secours
    ("Desktop Integration"), avec ses propres `createView()`,
    `destroyView()`, `repositionView()`, `screenChanged(QScreen*)`,
    `setInputRect()` : une **fenêtre entièrement séparée**, créée quand
    rien n'a appelé `registerInputPanel()`.

**Conclusion Partie 5** : preuve directe, au niveau du binaire réellement
installé sur la machine, du mécanisme exact. `breeze` s'enregistre comme
`AppInputPanel` (son `VirtualKeyboardLoader`/`InputPanel.qml` explicite,
avec `width: parent.width`). Aucun thème Nebula ne le fait jamais —
`DesktopInputPanel` prend systématiquement le relais, avec ses propres
dimensions et sa propre logique de repositionnement, découplées de tout
ce que l'application QML fait. Ceci explique intégralement, sans aucune
contradiction, les quatre observations expérimentales :
apparition automatique sans code applicatif, indifférence totale à
`QT_SCALE_FACTOR`/`QT_AUTO_SCREEN_SCALE_FACTOR`, repositionnement correct
entre écrans sans jamais redimensionner, et immunité de `breeze`.

## Parties non exécutées (décision explicite, 2026-08-03)

Parties 4 (contrôles officiels SDDM), 6 (scénarios matériels) et 7
(recherche amont) du brief n'ont pas été exécutées — décision de
l'utilisateur une fois la Partie 5 obtenue, jugée suffisamment probante
(preuve au niveau du binaire réel, pas une hypothèse). Elles
corroboreraient probablement la conclusion plutôt que la remettre en
cause, mais ce n'est pas vérifié.

---

## Conclusion

**Répond aux questions du brief :**

- **Est-ce Nebula ?** Oui, en partie — et ceci **corrige** le diagnostic
  provisoire de `Compatibility-Matrix.md` §10 (2026-07-31), qui concluait
  à tort que ce n'était "pas un bug Nebula" sur la seule base qu'aucun
  fichier `core/`/`themes/`/`platform/` ne référence `InputPanel`.
  L'absence elle-même est la cause : Nebula est la seule pièce du
  système qui pourrait enregistrer un `AppInputPanel` (comme `breeze` le
  fait) et ne le fait nulle part. Ce n'est pas un bug de rendu dans le
  Core, mais une **fonctionnalité manquante** dont l'absence a un effet
  démontré.
- **Est-ce SDDM ?** Non directement — SDDM ne fait qu'activer
  `qtvirtualkeyboard` via `InputMethod=` et laisser le thème (ou son
  absence de gestion) déterminer le mode d'intégration.
- **Est-ce Qt Virtual Keyboard ?** Le mécanisme `DesktopInputPanel` est
  un comportement de secours documenté et intentionnel de Qt (pas un
  bug Qt) — mais son déclenchement ici est une conséquence directe de
  l'absence de `AppInputPanel` côté Nebula.
- **Est-ce X11/Wayland ou le DPI ?** Contributeur réel et mesuré (écart
  physique 94–210 dpi non communiqué au greeter X11), mais Partie 3
  prouve que ce n'est pas la cause du symptôme précis observé — même
  une correction de DPI forcée (`QT_SCALE_FACTOR`) n'a aucun effet sur le
  clavier, uniquement sur le reste de l'UI.
- **Un correctif propre existe-t-il ?** Oui, avec un haut degré de
  confiance : ajouter un composant Core (`NebulaVirtualKeyboard` ou
  équivalent) qui instancie un vrai `InputPanel` avec `width` lié à
  l'écran réel — le même patron que `breeze`/`VirtualKeyboardLoader.qml`,
  adapté au Core. Non implémenté dans cette investigation (hors périmètre
  du brief : *"L'objectif n'est PAS de corriger Nebula immédiatement"*).
- **Nebula doit-il intervenir ou seulement documenter ?** Intervenir,
  sur la base de cette preuve — mais la décision de planifier et
  implémenter ce composant reste un choix produit séparé, à prendre
  explicitement (voir `Roadmap.md`), pas une suite automatique de cette
  investigation.

**Statut** : investigation close. Reproductible : tout thème sans
`InputPanel` explicite reproduira le symptôme sur n'importe quelle
machine avec `InputMethod=qtvirtualkeyboard` actif, indépendamment du
matériel exact.
