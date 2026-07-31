# Third-Party Licenses — Nebula

> Audit de la Phase Milestone 0.1 Beta (voir `Roadmap.md`) : licences de
> chaque police, icône, fond d'écran utilisé par le Core et les quatre
> thèmes officiels (`template`, `nord`, `glass-dark`, `glass-light`).
> Nebula lui-même est distribué sous GPLv3 — voir [`LICENSE`](../LICENSE).

---

## Résumé

**Aucun asset tiers n'est embarqué dans ce dépôt.** Toutes les images
(fonds d'écran, icônes) présentes sous `themes/*/assets/` ont été
générées spécifiquement pour ce projet (ImageMagick, primitives
vectorielles ou dégradés programmatiques — jamais une image existante
retouchée). Les polices référencées par nom dans `theme.conf` ne sont
**jamais** embarquées dans le dépôt — elles dépendent de ce qui est
installé sur le système de l'utilisateur final (`assets/fonts/` reste
vide dans les quatre thèmes officiels, confirmé par audit réel).

## Polices

| Police | Thème(s) | Statut | Licence |
| --- | --- | --- | --- |
| `sans-serif` (générique, résolue par le système) | `template` | Dépendance système, non embarquée | N/A — alias générique CSS/Qt, résolu vers la police par défaut du système |
| **Noto Sans** | `glass-dark`, `glass-light` | Dépendance système, non embarquée — testée réellement installée et disponible sur la machine de développement (`fc-match "Noto Sans"`, voir `Glass-Theme-Report.md`) | [SIL Open Font License 1.1](https://openfontlicense.org/) (Google Fonts / Noto project) — permissive, permet l'usage sans restriction y compris commercial ; aucune obligation d'attribution dans un produit qui se contente de *référencer* la police par nom (l'OFL encadre la redistribution du fichier de police lui-même, pas son usage par nom) |

Aucune police n'est embarquée dans `themes/*/assets/fonts/` (vérifié :
les quatre dossiers sont vides ou ne contiennent qu'un `.gitkeep`) —
`NebulaClock`/`NebulaDate`/`NebulaButton`/etc. utilisent la propriété Qt
`font.family`, qui retombe silencieusement sur une police système
disponible si celle demandée est absente (comportement Qt standard, pas
un mécanisme Nebula). **Limitation connue** : si `Noto Sans` n'est pas
installée sur la machine cible, Glass affichera la police de repli du
système sans avertissement — non testé sur une machine sans `Noto Sans`
du tout (voir `CHANGELOG.md`, limitations connues).

## Icônes

| Fichier | Thème(s) | Origine | Licence |
| --- | --- | --- | --- |
| `shutdown.png`, `restart.png`, `suspend.png`, `hibernate.png`, `reveal-password.png` | `glass-dark`, `glass-light` | Générées pour ce projet (ImageMagick, primitives vectorielles simples, gris `#8E8E93`, 64×64, transparent — voir `Glass-Theme-Report.md`) | GPLv3, comme le reste du dépôt — aucune source externe |

`template` et `nord` n'embarquent aucune icône (`assets/icons/` vide) —
`NebulaAvatar` retombe sur une silhouette générique dessinée en QML pur
(aucun asset requis, voir `Core-API.md`).

## Fonds d'écran

| Fichier | Thème | Origine | Licence |
| --- | --- | --- | --- |
| `nord-gradient.png` | `nord` | Dégradé vertical simple entre deux couleurs de la palette Nord officielle (`#2E3440` → `#3B4252`), généré programmatiquement (ImageMagick) — voir `themes/nord/README.md` | GPLv3, comme le reste du dépôt — aucune source externe |
| `glass-dark.png` / `glass-dark-compressed.jpg` | `glass-dark` | Dégradé original basse saturation, généré pour ce projet (ImageMagick) — voir `Glass-Theme-Report.md` | GPLv3, comme le reste du dépôt — aucune source externe |
| `glass-light.png` / `glass-light-compressed.jpg` | `glass-light` | Idem, variante claire | GPLv3, comme le reste du dépôt — aucune source externe |

`template` n'embarque aucun fond d'écran (`assets/wallpapers/` vide) —
`NebulaWallpaper` retombe sur la couleur de fond plate du thème
(`backgroundColor`) si `source` n'est pas défini.

## Palette Nord (couleurs, pas un asset)

La palette de couleurs officielle [Nord](https://www.nordtheme.com/)
(spécification, pas du code ni une image) est sous licence MIT. Seules
les valeurs hexadécimales publiées sont réutilisées, mappées vers les
Design Tokens de Nebula (`primaryColor`, `backgroundColor`, ...) — voir
`Nord-Theme-Specification.md` §2. Aucun fichier ni asset du projet Nord
n'est copié.

## Dépendances logicielles (non embarquées, hors périmètre licence d'assets)

Qt6, SDDM — dépendances système, jamais embarquées dans ce dépôt, sous
leurs licences respectives (LGPL/GPL selon les modules Qt, GPL pour
SDDM). Nebula ne redistribue aucun binaire Qt/SDDM.

## Conclusion

Aucune action requise avant publication : tous les assets visuels sont
des créations originales pour ce projet (GPLv3, cohérent avec le reste
du dépôt), et la seule dépendance externe non embarquée (Noto Sans) est
sous une licence permissive qui n'impose aucune obligation pour un usage
par simple référence de nom.
