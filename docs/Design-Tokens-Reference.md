# Design Tokens Reference — Nebula

> Référence exhaustive de chaque token exposé par `NebulaThemeProvider`
> (source : `core/config/NebulaThemeConfig.qml`). Ce document liste les
> **valeurs concrètes actuelles** (celles du thème de repli neutre du
> Core — voir `docs/Theme-System.md` §5) et les composants qui les
> consomment réellement aujourd'hui. Pour le vocabulaire et la
> justification de chaque groupe, voir [`Design-System.md`](Design-System.md) ;
> pour le mécanisme d'accès (`ThemeConfig` → `ThemeProvider` →
> composant), voir [`Theme-System.md`](Theme-System.md).
>
> Créé en Phase 1.6 (voir `Roadmap.md`) après un audit complet du Core
> pour éliminer les dernières valeurs codées en dur. Un token listé ici
> avec « Utilisé par : aucun (prévu pour ...) » n'est pas mort code —
> c'est un token déjà défini pour un composant qui n'existe pas encore
> (voir Phase 1, `Roadmap.md`).

---

## Colors

| Token | Type | Défaut | Description | Utilisé par |
| --- | --- | --- | --- | --- |
| `primaryColor` | color | `#4a90d9` | Couleur d'accent principale (bouton `primary`) | `NebulaButton` |
| `secondaryColor` | color | `#6c7a89` | Couleur d'accent secondaire (bouton `secondary`) | `NebulaButton` |
| `accentColor` | color | `#f0a030` | Mise en avant ponctuelle — focus, sélection. Délibérément distinct de `primaryColor` en teinte pour rester visible en anneau de focus (bug trouvé Phase 1.1, voir `Core-Implementation-Status.md`) | `NebulaButton` |
| `backgroundColor` | color | `#1e1e1e` | Fond général de l'écran, repli si aucune image de fond | `NebulaWallpaper`, `NebulaOverlay` (défaut de `color1`) |
| `surfaceColor` | color | `#2a2a2a` | Fond des panneaux/cartes | `NebulaSurface`, `NebulaAvatar` (fond du cadre de découpe) |
| `textPrimary` | color | `#f0f0f0` | Texte principal | `NebulaButton`, `NebulaClock` |
| `textSecondary` | color | `#a0a0a0` | Texte atténué (labels, aide) | `NebulaAvatar` (silhouette de repli), `NebulaSurface` (défaut de `borderColor`), `NebulaButton` (défaut de `border.color`), `NebulaDate` |
| `errorColor` | color | `#d9534f` | Erreur d'authentification, état invalide | aucun (prévu pour `NebulaPasswordField`, `NebulaNotification`) |
| `successColor` | color | `#5cb85c` | Confirmation, état valide | aucun (prévu pour `NebulaNotification`) |

## Spacing

| Token | Type | Défaut | Description | Utilisé par |
| --- | --- | --- | --- | --- |
| `spacingXs` | real | `4` | Espacement minimal (icône ↔ texte) | aucun pour l'instant |
| `spacingSm` | real | `8` | Espacement entre éléments proches | `NebulaButton` (espacement icône/texte) |
| `spacingMd` | real | `16` | Espacement par défaut entre sections | `NebulaButton` (padding vertical), `NebulaSurface` (défaut de `padding`) |
| `spacingLg` | real | `24` | Séparation entre blocs majeurs | `NebulaButton` (padding horizontal), `NebulaLoginLayout` (marges des zones statut/pied de page) |
| `spacingXl` | real | `32` | Marges d'écran | aucun pour l'instant |

## Radius

| Token | Type | Défaut | Description | Utilisé par |
| --- | --- | --- | --- | --- |
| `radiusSmall` | real | `4` | Petits éléments (icônes, badges) | aucun pour l'instant |
| `radiusMedium` | real | `8` | Champs de saisie, boutons | `NebulaButton` |
| `radiusLarge` | real | `16` | Cartes, panneaux | `NebulaSurface` (défaut de `radius`) |
| `radiusPill` | real | `9999` | Éléments totalement arrondis — valeur volontairement supérieure à toute demi-hauteur réaliste, pour que le clamp interne de Qt Quick produise toujours une pilule/cercle complet | `NebulaAvatar` (défaut de `radius`) |

## Typography

| Token | Type | Défaut | Description | Utilisé par |
| --- | --- | --- | --- | --- |
| `fontFamilyPrimary` | string | `"sans-serif"` | Police principale (titres, horloge, boutons) | `NebulaButton`, `NebulaClock`, `NebulaDate` |
| `fontFamilySecondary` | string | `"sans-serif"` | Police secondaire (texte courant) | aucun pour l'instant |
| `fontSizeTitle` | real | `24` | Taille des titres | aucun pour l'instant |
| `fontSizeBody` | real | `14` | Taille du texte courant | `NebulaButton` (texte + taille d'icône), `NebulaDate` |
| `fontSizeClock` | real | `32` | Taille de l'horloge | `NebulaClock` |
| `fontWeightNormal` | int (`Font.Normal`) | — | Graisse normale — valuée directement avec l'énumération Qt plutôt qu'une échelle de noms (D4, Phase 1.1) | `NebulaButton`, `NebulaClock`, `NebulaDate` |
| `fontWeightBold` | int (`Font.Bold`) | — | Graisse grasse | aucun pour l'instant |

## Animation

| Token | Type | Défaut | Description | Utilisé par |
| --- | --- | --- | --- | --- |
| `durationFast` | int (ms) | `120` | Micro-interactions (focus, hover, pression) | `NebulaButton` (`Behavior` sur `scale`/`color`) |
| `durationNormal` | int (ms) | `250` | Transitions standards | aucun pour l'instant |
| `durationSlow` | int (ms) | `500` | Transitions d'écran, apparitions | aucun pour l'instant |

Courbes d'easing volontairement non figées — voir `Design-System.md` §5.

## Overlay (Phase 1.5)

| Token | Type | Défaut | Description | Utilisé par |
| --- | --- | --- | --- | --- |
| `overlayOpacity` | real | `0.35` | Opacité du voile plat posé sur le fond | `NebulaOverlay` |

## Surface (Phase 1.5)

| Token | Type | Défaut | Description | Utilisé par |
| --- | --- | --- | --- | --- |
| `surfaceOpacity` | real | `1.0` | Opacité globale d'une `NebulaSurface` | `NebulaSurface` |
| `surfaceBorderWidth` | real | `1` | Épaisseur de bordure d'une `NebulaSurface` | `NebulaSurface` (défaut de `borderWidth`) |

`surfaceRadius`/`surfacePadding` n'existent délibérément pas comme tokens
dédiés : `NebulaSurface` réutilise `radiusLarge`/`spacingMd` — voir
`Decisions-Techniques.md`, DT-0013.

## Interaction (Phase 1.6)

Ajouté lors de l'audit du Design System : ces valeurs de retour visuel
(pression, focus, désactivation) étaient codées en dur dans
`NebulaButton`. Regroupées ici pour que tout futur composant interactif
(`NebulaPasswordField`, `NebulaUserList`, `NebulaSessionSelector`, ...)
réutilise le même vocabulaire au lieu d'inventer ses propres valeurs de
retour — voir `Roadmap.md`, Phase 1.6.

| Token | Type | Défaut | Description | Utilisé par |
| --- | --- | --- | --- | --- |
| `opacityDisabled` | real | `0.5` | Opacité d'un composant désactivé | `NebulaButton` |
| `scalePressed` | real | `0.97` | Facteur d'échelle pendant la pression | `NebulaButton` |
| `pressedDarkenFactor` | real | `1.3` | Facteur d'assombrissement (`Qt.darker`) de la couleur de base pendant la pression | `NebulaButton` |
| `borderWidthThin` | real | `1` | Épaisseur de bordure fine (ex. variante `ghost` au repos) | `NebulaButton` |
| `borderWidthFocus` | real | `2` | Épaisseur de bordure d'un composant focus | `NebulaButton` |

---

## Valeurs volontairement non tokenisées

Certaines valeurs codées en dur trouvées lors de l'audit Phase 1.6 sont
restées locales à leur composant, en dehors du Design System — elles ne
sont pas des identités visuelles mais des contraintes de géométrie ou de
décoration propres au composant :

- **`NebulaAvatar`** — taille par défaut (`64`), ratios de la silhouette
  de repli (`0.42`, `0.18`, `0.7`, `0.45`, `0.25` du côté du parent) :
  géométrie décorative interne, jamais paramétrée par un thème.
- **`NebulaSurface`** — `shadowColor` (`"#000000"`) et `shadowOffset`
  (`2`) : une ombre plate est conventionnellement sombre quelle que soit
  l'identité du thème ; les deux restent des propriétés surchargeables
  par instance, avec un défaut raisonnable, pas des tokens globaux.
  `shadowOpacity` (`0.25`) a été promue de valeur inline codée en dur à
  propriété par instance en Phase 1.6, pour rester cohérente avec
  `shadowColor`/`shadowOffset` — toujours pas un token global, pour la
  même raison.
- **`NebulaLoginLayout`** — largeur responsive des zones Main
  Content/Status (`min(90% de la largeur, 640)`) : contrat de layout du
  Core lui-même (empêcher une carte de connexion absurdement large sur
  un écran 4K), pas une valeur d'identité visuelle qu'un thème devrait
  pouvoir changer. Dédupliquée en une seule propriété interne
  (`_contentWidth`) en Phase 1.6, réutilisée par les deux zones.

## Vérifier la synchronisation ThemeConfig / ThemeProvider

`tests/ThemeSyncCheck.qml` (ajouté en Phase 1.6) compare les groupes de
tokens définis dans `NebulaThemeConfig` à ceux réellement exposés par
`NebulaThemeProvider`, et échoue (code de sortie non nul) si un groupe
est oublié — la régression trouvée en Phase 1.5 (`overlay`/`surface`
définis mais non exposés, voir `Development-Journal.md`). Exécuter avec
`qml6 tests/ThemeSyncCheck.qml`, ou via `scripts/check-design-system.sh`.
