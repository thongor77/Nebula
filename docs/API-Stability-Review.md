# API Stability Review — Nebula

> Rapport de la Phase 3.1 (voir `Roadmap.md` et `Core-Refinement-Review.md`).
> Ce document ne redéfinit aucune API — il classe l'état de stabilité de
> celles déjà documentées dans [`Core-API.md`](Core-API.md), à l'usage
> des futurs auteurs de thèmes et de Core. Établi après trois thèmes
> réels (Nord, Glass Dark, Glass Light) et un thème de référence
> (Template) ont exercé le Core en conditions réelles.

---

## 1. APIs considérées comme stables

Composants dont l'API publique (noms de propriétés, signaux, valeurs
par défaut) n'a pas changé depuis leur introduction et a été exercée
par au moins deux thèmes réels indépendants sans qu'aucun ajustement
n'ait été nécessaire :

- **`NebulaThemeProvider`** — interface stable par conception depuis
  DT-0003 (le mécanisme de stockage sous-jacent peut changer, l'API
  exposée aux composants ne bouge pas). Utilisée sans changement par
  Nord, Glass, Template.
- **`NebulaThemeLoader`** — contrat inchangé depuis la Phase 2.0.5
  (`configPath`, `config`, `themeName`, `loaded`, `loadError`,
  `reload()`, `themeLoaded()`/`themeLoadFailed()`). Trois thèmes réels
  l'utilisent identiquement.
- **`NebulaClock`** / **`NebulaDate`** — inchangés depuis la Phase 1.2.
- **`NebulaAvatar`** — inchangé depuis la Phase 1.2 ; repli sur
  silhouette générique vérifié réel.
- **`NebulaBackground`** / **`NebulaWallpaper`** / **`NebulaOverlay`** /
  **`NebulaSurface`** — inchangés depuis la Phase 1.5, utilisés par les
  quatre thèmes existants sans aucune surcharge de leur API.
- **`NebulaLoginLayout`** — inchangé depuis la Phase 1.3 (les quatre
  zones — wallpaper/main/status/footer — couvrent tous les cas
  rencontrés jusqu'ici).
- **`NebulaAuthService`** / **`NebulaUserService`** /
  **`NebulaSessionService`** / **`NebulaPowerService`** — contrat
  Service/Adapter inchangé depuis la Phase 1.4 (`NebulaPowerService` a
  gagné `canHibernate`/`hibernate()` en Phase 2.3 — un ajout, jamais une
  rupture).
- **`NebulaUserList`** / **`NebulaSessionSelector`** — inchangés depuis
  leur introduction en Phase 2.3, utilisés sans modification par Glass
  et Template.

## 2. Points susceptibles d'évoluer

- **`NebulaButton` / `NebulaPasswordField` / `NebulaPowerButtons` —
  support d'icônes** (`icon`/`showIcon`/`hideIcon`/`shutdownIcon`/.../
  `iconSize`, Phase 3.1) : n'a été exercé que par un seul thème réel
  (Glass) à ce jour, et seulement pour `NebulaButton`/
  `NebulaPowerButtons` — le chemin `NebulaPasswordField`
  `showIcon`/`hideIcon` n'a pas encore été vérifié visuellement avec un
  vrai thème (voir `Core-Refinement-Review.md` §2). À reconfirmer
  stable une fois un second thème l'utilise réellement.
- **`NebulaButton.icon` reste nommé `icon`, pas `iconSource`** :
  décision prise cette phase pour rester cohérent avec le nom déjà
  établi depuis la Phase 1.1 plutôt qu'avec l'exemple donné par le brief
  de la Phase 3.1. Considéré stable, mais noté ici car un futur brief
  pourrait à nouveau suggérer `iconSource` sans connaître cette
  décision.
- **Libellés localisables** (`showLabel`/`hideLabel` sur
  `NebulaPasswordField`, `shutdownLabel`/.../`confirmLabel` sur
  `NebulaPowerButtons`, Phase 3.1) : portée volontairement minimale
  (propriétés string surchageables), pas une vraie infrastructure de
  traduction (`qsTr`/fichiers de locale). Si un besoin réel de
  changement de langue à l'exécution apparaît (pas seulement une valeur
  fixe par thème), cette API devra être reconsidérée — actuellement
  suffisante pour le seul besoin observé (chaînes codées en dur non
  personnalisables).
- **Couleur du texte des boutons** (`NebulaButton` utilise
  `theme.colors.textPrimary` pour tout `variant`) : un contraste
  insuffisant a été mesuré réellement pour Nord (1.74:1) et Glass
  (~3.6:1, voir `Core-Refinement-Review.md` §6). Un futur token dédié
  (ex. `colors.textOnPrimary`) est probable mais non implémenté cette
  phase — si ajouté, ce sera une propriété *supplémentaire* avec repli
  sur `textPrimary`, donc non cassant.
- **`NebulaKeyboardSelector`** — documenté dans `Core-API.md` mais
  toujours non implémenté (comme en Phase 1.4/2.3) ; son API pourrait
  encore changer à l'implémentation, aucun thème ne l'utilise encore.
- **Réutilisation d'animations** (`Core-Refinement-Review.md` §5) :
  aucune animation n'a été déplacée dans le Core cette phase, faute de
  réutilisation démontrée entre thèmes indépendants. Si un second thème
  reprend les mêmes motifs que Glass (fondu+zoom, pulsation,
  tremblement), une future `NebulaAnimationManager` en absorbera
  probablement la logique — pas encore engagé.

## 3. Dépréciations futures

Aucune dépréciation identifiée cette phase — toutes les évolutions
listées ci-dessus sont additives (nouvelles propriétés optionnelles
avec des valeurs par défaut reproduisant le comportement précédent),
jamais des retraits ou des renommages. Rien dans `core/` n'est marqué
comme obsolète à ce jour.

## 4. Recommandation

Les composants du §1 peuvent être considérés comme une base stable pour
les futurs thèmes plus exigeants (AMOLED, Hyprland, Cyberpunk, Hacker —
voir `Roadmap.md` Phase 3) sans attendre de rupture d'API. Les points du
§2 méritent d'être revérifiés au fur et à mesure que de nouveaux thèmes
les exercent réellement, plutôt que d'être considérés figés après un
seul thème d'usage.
