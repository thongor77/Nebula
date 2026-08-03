# Roadmap — Nebula

> Mise à jour à chaque fonctionnalité livrée ou changement de phase
> (voir `META/Workflow-Claude.md`).

---

## Phase 0 — Architecture (terminée)

Objectif : ne pas écrire de code avant d'avoir validé le contrat
Core/Thèmes.

- [x] Définir la mission et les objectifs du projet
- [x] Structurer le dépôt (`core/`, `themes/`, `docs/`, `.github/`)
- [x] Documenter l'architecture cible (`docs/Architecture.md`)
- [x] Documenter les décisions techniques (`docs/Decisions-Techniques.md`)
- [x] Documenter les spécifications de composants (`docs/Specifications-Techniques.md`)
- [x] Définir les conventions de code et le processus de contribution
- [x] Documenter le catalogue de design tokens (`docs/Design-System.md`)
- [x] Documenter le flux de theming Core ↔ composants (`docs/Theme-System.md`)
- [x] Valider les inconnues critiques par prototype — fait en Phase 1.0
      (`docs/Prototype-Results.md`) : API SDDM réelle et multi-écran
      résolus ; coût des effets GPU, rendu HiDPI pixel, mécanisme de
      configuration (écriture/export) et authentification de bout en bout
      restent ouverts, explicitement hors périmètre de ce prototype.
- [x] Revue de l'architecture avant de passer en Phase 1 — satisfaite par
      la Phase 0.6 (`docs/Architecture-Review.md`)

## Phase 0.5 — Architecture Contracts (terminée)

Objectif : produire les contrats techniques (API, compatibilité, environnement
de développement, création de thème) qui guideront toute l'implémentation
future — pour qu'un développeur externe puisse commencer sans ambiguïté.

Statut : terminée.

Livrables :

- [x] Contrat public du Core (`docs/Core-API.md`)
- [x] Matrice de compatibilité SDDM (`docs/SDDM-Compatibility.md`)
- [x] Environnement de développement (`docs/Development-Environment.md`)
- [x] Guide de création de thème (`docs/Theme-Development.md`, renommé
      `docs/Theme-SDK.md` en Phase 2.0)
- [x] Revue de ces quatre documents — faite en Phase 0.6
      (`docs/Architecture-Review.md`)

## Phase 0.6 — Architecture Review (terminée)

Objectif : revue finale de cohérence documentaire avant démarrage du
Core MVP — vérifier que l'architecture permet une implémentation claire,
maintenable et extensible, sans code QML.

Statut : terminée.

Livrables :

- [x] Revue de cohérence croisée de tous les documents d'architecture,
      contradictions et doublons corrigés (`docs/Architecture-Review.md`)
- [x] Frontière Core/Theme/ThemeProvider confirmée explicitement
      (`docs/Architecture-Review.md`, section 4 ; enrichissement de
      `docs/Theme-System.md` avec ordre d'initialisation et valeurs par
      défaut)
- [x] Périmètre exact du Core MVP (`docs/Core-MVP.md`), réconcilié avec
      l'ordre de construction ci-dessous et avec `NebulaButton` désormais
      formalisé
- [x] Spécification du thème pilote (`docs/Nord-Theme-Specification.md`)
- [x] Risques techniques consolidés (SDDM, GPU, Wayland —
      `docs/Architecture-Review.md`, section 5)
- [x] Règle "Core ou Theme, documenter l'API avant d'implémenter, éviter
      toute dépendance à un thème" ajoutée dans `CLAUDE.md`

## Phase 1.0 — SDDM Technical Prototype (terminée)

Objectif : valider l'environnement SDDM réel avant le développement du
Core, par un prototype jetable (`prototype/`) — pas un thème, pas de
composants Core, pas de `ThemeProvider`.

Statut : terminée.

Livrables :

- [x] `prototype/Main.qml`, `theme.conf`, `README.md`
- [x] Testé en standalone (`qml6`) et via `sddm-greeter-qt6 --test-mode`
      sur une installation SDDM 0.21 réelle (voir
      `docs/Prototype-Results.md`)
- [x] API SDDM réelle vérifiée (`sddm`, `userModel`, `sessionModel`,
      `keyboard`, `screenModel`, `config`) — inconnue critique levée
- [x] Comportement multi-écran vérifié (une vue par écran physique) —
      inconnue critique levée, testé avec 3 écrans réels
- [x] Géométrie HiDPI vérifiée sur un setup à échelles mixtes (1 et 1.4)
- [x] `docs/Prototype-Results.md` créé ; répercussions sur
      `SDDM-Compatibility.md`, `Core-API.md`, `Development-Environment.md`,
      `Theme-SDK.md` et `Architecture.md` (Inconnues critiques)
- [ ] Coût réel des effets GPU, rendu pixel HiDPI, mécanisme de
      configuration définitif, authentification de bout en bout —
      délibérément non couverts par ce prototype (voir
      `Prototype-Results.md` §7), à valider plus tard sans bloquer le
      Core MVP (voir `Core-MVP.md`, exclusions)

Le dossier `prototype/` est jetable : il ne sera pas conservé comme base
de code du Core (voir `Core-MVP.md` et `Theme-SDK.md` pour la
structure définitive d'un thème réel).

## Phase 1 — Core MVP

Objectif : un Core minimal mais complet, sans aucun thème visuel dessus.
Démarre après validation de la Phase 1.0.

**Sous-étape Phase 1.1 — Core Foundation Skeleton (terminée) :** premiers
pas d'implémentation réelle (`ThemeConfig`, `ThemeProvider`, tokens,
`NebulaButton`), testés visuellement (`qmllint` + rendu réel). Décisions
prises et bug de conception trouvé/corrigé (tokens `accentColor` ==
`primaryColor`) : voir
[`docs/Core-Implementation-Status.md`](Core-Implementation-Status.md).
Pas de thème complet, pas d'effets avancés — conforme au périmètre de
cette sous-étape.

**Sous-étape Phase 1.2 — Core Components Expansion (terminée) :**
`NebulaAvatar`, `NebulaClock`, `NebulaDate` implémentés et testés
(`qmllint`, rendu réel, scaling différent `QT_SCALE_FACTOR=2`). Critère de
fin atteint : écran de login statique (avatar + heure + date + bouton)
démontré dans `tests/LoginScreenHarness.qml`, sans thème ni API SDDM.
Décisions de réconciliation avec le brief (format libre pour `NebulaClock`
en plus de `use24HourFormat`/`showSeconds`, `radius` ajouté à
`NebulaAvatar`, `fallbackIcon` conservé) : voir
[`docs/Core-Implementation-Status.md`](Core-Implementation-Status.md).

**Sous-étape Phase 1.3 — Layout Foundation (terminée) :** `NebulaLoginLayout`
implémenté (`core/layouts/`) — squelette commun à quatre zones (fond,
contenu principal, statut, pied de page), géométrie uniquement, testé à
plusieurs tailles/ratios et à `QT_SCALE_FACTOR=2`. Critère de fin atteint :
`tests/LoginScreenHarness.qml` instancie désormais `NebulaLoginLayout` au
lieu d'assembler les composants directement, résultat visuel identique à
la Phase 1.2. Un bug de boucle de binding (`anchors.centerIn` sur une zone
qui se dimensionne sur son propre contenu) et une limitation de
débordement vertical sur ratio extrême ont été trouvés et documentés —
voir [`docs/Development-Journal.md`](Development-Journal.md), nouveau
document créé cette phase pour ce type de découverte.

**Sous-étape Phase 1.4 — Services & Platform Abstraction (terminée) :**
`NebulaAuthService`, `NebulaUserService`, `NebulaSessionService`,
`NebulaPowerService` (`core/services/`) implémentés — contrat public
uniquement, délèguent à un `adapter` injecté. Squelettes
`platform/sddm/SDDM*Adapter.qml` créés (aucun appel SDDM réel). Testé
réellement via `tests/ServicesHarness.qml` (instanciation + cycle complet
authenticating→succeeded avec `tests/mocks/`) et via
`LoginScreenHarness.qml` (nom d'utilisateur et authentification
maintenant servis par les Services, plus de valeur codée en dur). Critère
de fin atteint : aucun composant Core n'appelle `sddm.*` directement, le
Harness fonctionne toujours sans SDDM. Nouveaux documents
[`docs/Services-Architecture.md`](Services-Architecture.md) et
[`docs/Nebula-Principles.md`](Nebula-Principles.md). Bug réel trouvé et
corrigé (`Connections{}` invalide comme enfant direct d'un `QtObject` —
pas de default property) : voir DT-0011 et
[`docs/Development-Journal.md`](Development-Journal.md).

**Sous-étape Phase 1.5 — Visual Foundation (terminée) :**
`NebulaBackground` (revu — conteneur racine pur, voir DT-0012),
`NebulaWallpaper`, `NebulaOverlay`, `NebulaSurface` implémentés et
testés. `tests/LoginScreenHarness.qml` affiche désormais un écran de
connexion en couches complet (Background → Wallpaper → Overlay →
LoginLayout → Surface → composants fonctionnels) — critère de fin
atteint, le Core est considéré visuellement complet pour le périmètre du
MVP. Bonus réalisés : `tests/VisualHarness.qml` (tous les composants sur
une page) et une référence de performance (voir
[`docs/Rendering-Guidelines.md`](Rendering-Guidelines.md) §6). Nouveau
document [`docs/Rendering-Guidelines.md`](Rendering-Guidelines.md). Deux
bugs réels trouvés et corrigés (contrainte `Row`/`anchors.fill`, tokens
`overlay`/`surface` non répercutés dans `NebulaThemeProvider`) : voir
[`docs/Development-Journal.md`](Development-Journal.md).

**Sous-étape Phase 1.6 — Design System Hardening (terminée) :** audit
complet des 14 fichiers du Core, nouveau groupe de tokens `interaction`
(`opacityDisabled`, `scalePressed`, `pressedDarkenFactor`,
`borderWidthThin`, `borderWidthFocus`) extrait de valeurs codées en dur
dans `NebulaButton`, `NebulaSurface.shadowOpacity` promue en propriété,
largeur responsive de `NebulaLoginLayout` dédupliquée. Nouveau document
[`docs/Design-Tokens-Reference.md`](Design-Tokens-Reference.md) (chaque
token : nom, type, défaut, description, composants utilisateurs).
`tests/ThemeSyncCheck.qml` (nouveau) détecte automatiquement toute
divergence `ThemeConfig`/`ThemeProvider` — la régression trouvée en
Phase 1.5 — testé réellement dans les deux sens.
`scripts/check-design-system.sh` (nouveau) : point d'entrée unique
(`qmllint` + `ThemeSyncCheck` + harnais visuels) avant un commit. Aucune
régression visuelle (capture d'écran, taille par défaut et
`QT_SCALE_FACTOR=2`). Le Core est considéré stable : voir
[`docs/Core-Implementation-Status.md`](Core-Implementation-Status.md).

Ordre de construction recommandé (plomberie avant composants visuels,
composants simples avant composants interactifs — voir
[`Theme-System.md`](Theme-System.md)) :

1. [x] `ThemeConfig` — Phase 1.1, `core/config/NebulaThemeConfig.qml`
       (voir `docs/Core-Implementation-Status.md`)
2. [x] Design tokens — Phase 1.1, premiers tokens implémentés dans
       `NebulaThemeConfig` (colors, spacing, radius, typography, animation)
3. [x] `ThemeLoader` — Phase 2.0.5, `core/theme/NebulaThemeLoader.qml`
       (voir `docs/ThemeLoader.md` et DT-0017/DT-0018 dans
       `Decisions-Techniques.md`)
4. [x] `ThemeProvider` — Phase 1.1, `core/theme/NebulaThemeProvider.qml`
5. [x] `Button` — Phase 1.1 ; [x] `Avatar` — Phase 1.2, tous deux dans
       `core/components/`
6. [x] `LoginLayout` — Phase 1.3, `core/layouts/NebulaLoginLayout.qml`
7. [x] `AuthService`, `UserService`, `SessionService`, `PowerService` —
       Phase 1.4, `core/services/` (contrat public + adapter injecté,
       squelettes `platform/sddm/` — pas de câblage SDDM réel)
8. [x] `Background` — Phase 1.5, `NebulaBackground` + `NebulaWallpaper` +
       `NebulaOverlay` + `NebulaSurface` (`core/components/`)
9. [x] `UserList`, `PasswordField` — Phase 2.3,
       `core/components/NebulaUserList.qml`,
       `core/components/NebulaPasswordField.qml` (dépendent de
       `UserService`/`AuthService`, voir `Core-API.md`)
10. [x] `Clock`, `Date` — Phase 1.2, `core/components/NebulaClock.qml`,
       `core/components/NebulaDate.qml`
11. [x] `PowerButtons` — Phase 2.3, `core/components/NebulaPowerButtons.qml`
       (shutdown / reboot / sleep / hibernate — composé sur `Button` et
       `PowerService`, étendu avec `canHibernate`/`hibernate()` — DT-0019)
12. [x] `SessionSelector` — Phase 2.3,
       `core/components/NebulaSessionSelector.qml` (dépend de
       `SessionService`) ; [ ] `KeyboardSelector` reste à faire (aucun
       Service dédié, voir `Core-API.md`)
13. [ ] `Notification`
14. [ ] `AnimationManager` (version minimale)
15. [ ] Mettre en place `tests/` avec une première suite de tests pour
       les composants livrés ci-dessus
16. [ ] Zéro warning QML sur l'ensemble du Core

Périmètre exact et exclusions du MVP : voir
[`Core-MVP.md`](Core-MVP.md).

## Phase 2 — Premier thème de référence

Objectif : prouver que le Core suffit à construire un thème complet sans
aucune duplication.

**Sous-étape Phase 2.0 — Theme SDK Foundation (terminée) :** premier SDK
officiel de thèmes, avant l'implémentation de Nord. `themes/template/`
créé (`README.md`, `metadata.desktop`, `theme.conf`, `Main.qml`,
`preview.png`, `assets/{wallpapers,icons,fonts}/`) — référence officielle
de structure. `docs/Theme-Development.md` absorbé dans
[`docs/Theme-SDK.md`](Theme-SDK.md), désormais l'unique référence
normative (contrat, conventions de nommage, dossiers réservés, tokens
attendus) ; [`docs/Creating-A-Theme.md`](Creating-A-Theme.md) (nouveau)
reste un tutoriel pas-à-pas qui y renvoie plutôt que de répéter les
règles (DT-0014). `scripts/check-theme.sh` (nouveau) valide la structure
statique d'un thème ; `tests/ThemeHarness.qml` (nouveau) charge et
visualise réellement les tokens d'un thème en standalone, sans SDDM. Deux
décisions de réconciliation avec le brief : pas de dossier `overrides/`
dans le Template (DT-0015), `metadata.desktop` réel plutôt que
`metadata.json` inventé (DT-0016). Premier audit du SDK réalisé en
construisant le Template lui-même — a révélé que `NebulaThemeConfig` ne
supporte pas la surcharge déclarative de tokens groupés, et qu'aucun pont
Core n'existe encore de `theme.conf`/`config` vers `NebulaThemeConfig` ;
résolu par une petite fonction dupliquée (`applyFlatValues()`, assignation
impérative) dans `Main.qml`/`ThemeHarness.qml`, documentée comme un
pis-aller temporaire à promouvoir en `NebulaThemeLoader` dès qu'un
deuxième thème réel (Nord) en a besoin (DT-0017) — **le Core n'a reçu
aucune modification cette phase**, conformément à l'objectif de prouver
qu'il est déjà suffisant. Deux bugs réels trouvés et corrigés en testant
sous `sddm-greeter --test-mode` réel (pas seulement `qml6` standalone) :
voir [`docs/Development-Journal.md`](Development-Journal.md).

**Sous-étape Phase 2.0.5 — Theme Loading Architecture (terminée) :**
`core/theme/NebulaThemeLoader.qml` (nouveau) devient l'unique
responsable du chargement de `theme.conf` — lit le fichier directement
(jamais la propriété de contexte SDDM `config`, pour ne jamais faire
dépendre le Core de SDDM, voir
[`docs/ThemeLoader.md`](ThemeLoader.md) §3), valide chaque token de façon
tolérante (token inconnu ignoré et journalisé, token absent laisse la
valeur par défaut, valeur invalide détectée après coup et la valeur par
défaut restaurée), ne plante jamais. `applyFlatValues()` retirée de
`themes/template/Main.qml` et `tests/ThemeHarness.qml`, qui consomment
désormais exclusivement le Loader — DT-0017 résolu par anticipation,
sans modification de l'API publique du Core existante. Nouveaux
documents [`docs/ThemeLoader.md`](ThemeLoader.md) (contrat, cycle de
chargement, piège des signaux au premier chargement) et
[`docs/Compatibility-Matrix.md`](Compatibility-Matrix.md) (différences
factuelles `qml6`/`sddm-greeter --test-mode`/SDDM réel). Nouveau
`tests/ThemeLoaderHarness.qml` couvrant les 5 scénarios requis (thème
valide, token inconnu, token absent, fichier vide, valeur invalide) — les
deux derniers ont révélé deux bugs réels (indistinction fichier vide/
manquant/lectures désactivées, DT-0018 ; référence vivante au lieu d'une
copie en capturant une propriété `color` dans une variable JS), tous deux
corrigés et re-vérifiés. Revalidé sous `sddm-greeter --test-mode` réel
sur les 3 écrans de la machine : voir
[`docs/Development-Journal.md`](Development-Journal.md).

**Sous-étape Phase 2.1 — Nord (terminée) :**

- [x] Thème de référence retenu : `nord`. Choix confirmé après analyse
      d'une proposition alternative (`cyberpunk`) : `nord` reste préféré
      car sa simplicité visuelle permet de valider le contrat Core/Thème
      sans dépendre des effets GPU (blur/glow/particules), encore non
      stabilisés à ce stade (voir Phase 3). `cyberpunk` sert de second
      thème pour valider justement ces effets.
- [x] Implémenté en partant de `themes/template/` en suivant
      [`docs/Creating-A-Theme.md`](Creating-A-Theme.md) (contrat détaillé :
      [`docs/Theme-SDK.md`](Theme-SDK.md)), composition pure sur le Core —
      palette officielle Nord (9 tokens couleur, voir
      `Nord-Theme-Specification.md` §2), typographie/espacement/rayon/
      animation laissés aux défauts du Core. Portée décidée avec
      l'utilisateur (2026-07-31) : uniquement les composants Core
      existants aujourd'hui (pas `NebulaPasswordField`/`NebulaUserList`/
      etc., toujours non implémentés) — un écran cohérent visuellement,
      volontairement incomplet fonctionnellement. Wallpaper original
      généré pour le projet (dégradé Nord, sans dépendance externe).
- [x] Validé avec `scripts/check-theme.sh nord`, `tests/ThemeHarness.qml`,
      `tests/ThemeInspector.qml` (nouveau, optionnel — origine
      thème/défaut de chaque token) et `sddm-greeter --test-mode` (3
      écrans réels + `QT_SCALE_FACTOR=2`).
- [x] Rapport de validation créé :
      [`docs/Nord-Validation-Report.md`](Nord-Validation-Report.md).
      Constat majeur : un thème copié seul vers son vrai emplacement
      d'installation (`/usr/share/sddm/themes/<nom>/`) ne peut pas
      charger le Core (imports relatifs `../../core/...` invalides hors
      du dépôt) — SDDM bascule proprement sur son thème de secours,
      aucun risque pour la session réelle, mais aucun thème Nebula n'est
      aujourd'hui installable hors du dépôt. Documenté dans
      `Theme-SDK.md`, `Creating-A-Theme.md`, `Compatibility-Matrix.md`
      §7 — non résolu cette phase (voir Phase 2.2 ci-dessous).

**Sous-étape Phase 2.2 — Distribution / Packaging (terminée) :** résout
le Constat #1 de `Nord-Validation-Report.md`. Trois architectures
prototypées et testées réellement (thème autonome, module QML, génération
à l'installation) — voir
[`docs/Deployment-Decision.md`](Deployment-Decision.md) pour la
comparaison complète. Solution retenue : `core/`/`platform/sddm/`
installés comme module QML (`import Nebula`/
`import Nebula.Platform.Sddm`) au chemin QML par défaut de Qt
(`qmake6 -query QT_INSTALL_QML`) — **aucune** variable d'environnement
requise, contrairement à la crainte initiale (`QML2_IMPORT_PATH`),
vérifié réellement (DT-0022 dans `Decisions-Techniques.md`). Nouveaux
scripts `scripts/install-nebula.sh` (idempotent), `uninstall-nebula.sh`
(ne supprime que ce que Nebula a installé, marqueur `.nebula-managed`),
`check-installation.sh` (vérifie sans jamais modifier le système,
y compris un vrai test de chargement `qml6`) — tous testés en conditions
réelles (installation, vérification, désinstallation complète sur le
système de développement). Nouveaux documents
[`docs/Deployment-Decision.md`](Deployment-Decision.md) et
[`docs/Installation.md`](Installation.md)/[`docs/Packaging.md`](Packaging.md).
`Theme-SDK.md`/`Creating-A-Theme.md`/`Compatibility-Matrix.md` mis à
jour pour refléter la limitation résolue. Voir
[`docs/Development-Journal.md`](Development-Journal.md) pour les
découvertes réelles (chemin QML par défaut, modules à espace de noms à
points, protection Git `safe.directory` sous root).

**Sous-étape Phase 2.3 — Interactive Login Components (terminée) :**
démarrée malgré la Phase 2.2 non terminée — décision utilisateur
explicite, le brief affirmait à tort que la distribution était résolue,
voir DT-0021 (`Decisions-Techniques.md`). Quatre nouveaux composants
Core : `NebulaUserList`, `NebulaPasswordField`, `NebulaSessionSelector`,
`NebulaPowerButtons` (`core/components/`) — tous parlent uniquement aux
Services existants, jamais à SDDM directement. `NebulaPowerService`
étendu avec `canHibernate`/`hibernate()` (DT-0019). Pas de nouveau type
d'état d'authentification créé — chaque composant reflète directement
l'état de son Service (DT-0020). Nouveau
[`docs/Login-Architecture.md`](Login-Architecture.md) (responsabilités,
flux complet d'authentification) et `tests/LoginWorkflowHarness.qml`
(écran de connexion complet et interactif, Mock adapters). Confirmé
réellement : chaque composant se dégrade proprement (aucune entrée,
aucun bouton) quand son adapter SDDM reste un squelette (Phase 1.4) —
navigation clavier/souris et flux complet d'authentification exercés
uniquement via les Mock adapters tant que le câblage SDDM réel n'est pas
fait. `themes/template/Main.qml` mis à jour pour utiliser les quatre
nouveaux composants (référence SDK à jour) ; Nord n'a reçu aucun
traitement particulier, conformément au brief. Validé sous `qml6`,
`sddm-greeter --test-mode` (3 écrans réels) et `QT_SCALE_FACTOR=2` — voir
[`docs/Development-Journal.md`](Development-Journal.md).

## Phase 3 — Thèmes suivants et effets avancés

**Sous-étape Phase 3.0 — Glass (terminée) :** deuxième thème officiel,
en deux variantes indépendantes (`themes/glass-light/`,
`themes/glass-dark/`), toutes deux conformes au contrat SDK actuel.
Portée décidée avec l'utilisateur (2026-07-31) : deux thèmes
indépendants, mutualisation (contenu `Main.qml`, assets) limitée au
dépôt/implémentation, jamais un nouveau mécanisme SDK. Premier thème à
utiliser l'ensemble fonctionnel complet issu de la Phase 2.3
(`NebulaUserList`/`NebulaPasswordField`/`NebulaSessionSelector`/
`NebulaPowerButtons` ensemble) — Nord (Phase 2.1) avait été
délibérément limité à un sous-ensemble plus restreint. Style verre
dépoli sobre (Fluent Design/Breeze moderne/macOS Sonoma), sans effet
GPU (aucun `BlurEffect` — pas encore dans le Core, voir
[`docs/Rendering-Guidelines.md`](Rendering-Guidelines.md)). Typographie
testée et justifiée (Noto Sans — Inter non installée sur la machine de
test, Cantarell spécifique à GNOME/GTK). Surfaces réglées après
comparaison réelle de 4 combinaisons opacité/rayon/ombre
(`surfaceOpacity=0.75`/`radiusLarge=20`/ombre 0.3/décalage 4). Cinq
animations testées (apparition, disparition, focus, changement
d'utilisateur, validation du mot de passe), toutes ponctuelles,
150–250 ms. HiDPI (100/125/150/200 %) et multi-écran (3 écrans réels)
validés pour les deux variantes. Performances mesurées et comparées à
Nord (~131 objets QML contre ~51, hausse entièrement due à l'ensemble
fonctionnel plus large, pas au coût par composant ; mémoire résidente
+~10 Mo). Rapport complet :
[`docs/Glass-Theme-Report.md`](Glass-Theme-Report.md). Découverte
majeure, non spécifique à Glass : `NebulaThemeLoader` ne peut pas lire
`theme.conf` sous le vrai service `sddm.service` sans
`GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1` (SDDM 0.21.0-7, Qt6
6.11.1) — touchait silencieusement Nord et Template de la même façon,
corrigé immédiatement dans `scripts/install-nebula.sh` (DT-0023 dans
`Decisions-Techniques.md`, `Compatibility-Matrix.md` §9). Limitation
Core réelle documentée, non corrigée par principe (aucun composant Core
modifié cette phase) : ni `NebulaPowerButtons` ni `NebulaPasswordField`
n'exposent de propriété d'icône — les 5 icônes générées pour Glass
existent mais ne sont câblées nulle part dans l'interface réelle (voir
`Glass-Theme-Report.md`, Constat #1). Installation système réelle
validée (`scripts/install-nebula.sh glass-dark` +
`check-installation.sh`).

**Sous-étape Phase 3.1 — Core Refinement & API Stabilization
(terminée) :** consolidation du Core à partir des seuls besoins
observés dans Nord/Glass, sans anticipation — voir
[`docs/Core-Refinement-Review.md`](Core-Refinement-Review.md) (revue
complète des 8 sections du brief) et
[`docs/API-Stability-Review.md`](API-Stability-Review.md) (statut de
stabilité de chaque API publique). Support d'icônes ajouté à
`NebulaButton` (`iconSize`, `icon` existait déjà depuis la Phase 1.1),
`NebulaPasswordField` (`showIcon`/`hideIcon`/`iconSize`) et
`NebulaPowerButtons` (`shutdownIcon`/`rebootIcon`/`suspendIcon`/
`hibernateIcon`/`iconSize`) — `iconColor` du brief délibérément non
implémenté (teinter une image sans shader est impossible en QtQuick pur,
`ShaderEffect`/`MultiEffect` interdits dans le Core). Six chaînes
codées en dur (`"Show"`/`"Hide"`/`"Shut Down"`/...) rendues
surchargeables (`showLabel`/`hideLabel`/`shutdownLabel`/.../
`confirmLabel`) pour la localisation. Bug réel trouvé et corrigé :
`KeyNavigation.tab` ciblant `NebulaPasswordField` laissait le focus
clavier sur le `Rectangle` racine plutôt que sur le `TextInput` interne
— touchait Glass et Template depuis la Phase 2.3, jamais remarqué avant
(voir `Development-Journal.md`). Contraste WCAG mesuré réellement :
libellé du bouton Unlock de Nord à 1.74:1 (non conforme), Glass à
~3.6:1 (limite) — cause structurelle documentée (`NebulaButton` sans
token « texte sur couleur primaire ») mais non corrigée cette phase
(portée trop large). Aucune animation déplacée vers le Core (réutilisation
non démontrée entre thèmes indépendants — Nord/Template n'en ont aucune,
seul Glass, dont les deux variantes partagent déjà le même `Main.qml`).
Nord, Glass Dark, Glass Light et Template revalidés sans aucune
modification après les changements Core (`qmllint`, `qml6`,
`sddm-greeter --test-mode`, installation système réelle réinstallée et
revérifiée) — aucune régression.

**Sous-étape Phase 3.2 — Real SDDM Platform Integration (terminée) :**
implémentation réelle des 4 adapters `platform/sddm/`
(`SDDMUserAdapter`, `SDDMSessionAdapter`, `SDDMPowerAdapter`,
`SDDMAuthAdapter`), toujours des squelettes depuis la Phase 1.4 —
condition bloquante identifiée en testant `nord` sous le vrai
`sddm.service` (Milestone 0.1 Beta, 2026-08-02) : aucun thème ne peut
authentifier, lister les utilisateurs/sessions ni agir sur
l'alimentation tant que ce câblage n'existe pas, indépendamment du
thème testé — un gap Core/Platform partagé par tous les thèmes, pas un
bug par thème. Ordre délibéré par risque croissant plutôt que par ordre
logique de l'API : les 3 premiers adapters se valident entièrement sous
`--test-mode`, le dernier (`SDDMAuthAdapter`) exige le vrai
`sddm.service` (jamais de backend d'authentification en mode test, voir
`Prototype-Results.md` §3.5) et suit le protocole sûr déjà documenté
pour l'incident VT/DRM du même jour (pas de session bureau vivante en
parallèle pendant le test).

- [x] **3.2.0 — Vérification des inconnues (sans risque)** : rôles
      réels de `userModel`/`sessionModel` et forme réelle des signaux de
      `sddm` (`loginSucceeded`/`loginFailed`), établis par lecture
      statique du thème `breeze` réel installé sur la machine (déjà en
      production, zéro exécution du greeter nécessaire) plutôt que par
      un test actif — voir `Development-Journal.md`, 2026-08-02 — Phase
      3.2. Découverte notable : SDDM réel ne transmet **aucune chaîne de
      raison** au greeter en cas d'échec de connexion (`onLoginFailed()`
      sans argument) — `NebulaAuthService.errorMessage` restera donc
      toujours un texte générique choisi par Nebula, jamais un message
      SDDM.
- [x] **3.2.1 — `SDDMPowerAdapter` réel** : mapping direct
      `sddm.can*`/`sddm.hibernate()`/`suspend()`/`reboot()`/`powerOff()`
      — aucune inconnue restante. Piège de nommage réel : notre
      `canShutdown`/`shutdown()` correspond à `sddm.canPowerOff`/
      `sddm.powerOff()`, pas à un `sddm.canShutdown` qui n'existe pas.
      Validé sous `sddm-greeter-qt6 --test-mode` avec `glass-dark` (seul
      thème câblant `NebulaPowerButtons` à ce jour) : aucune erreur QML
      sur les 3 écrans réels de la machine, sans jamais cliquer sur un
      bouton d'action réel (risque déjà identifié : `--test-mode` ne
      bloque pas forcément `sddm.powerOff()` comme il bloque
      `sddm.login()` — vérification passive uniquement, voir
      `Development-Journal.md`, 2026-08-02 — Phase 3.2).
- [x] **3.2.2 — `SDDMSessionAdapter` réel** : matérialisation de
      `sessionModel` en tableau JS via un `Instantiator` interne
      (`Item`, pas `QtObject` — même contrainte que `MockAuthAdapter`,
      Phase 1.4), même patron que le correctif `screenModel.count` de la
      Phase 1.0. Piège réel trouvé en testant (pas en lisant la doc) :
      un rôle de modèle exposé sous forme d'identifiant nu dans un
      délégué `QtObject` (`property string name: ""`) reste vide —
      seul l'accès explicite `model.name` fonctionne (confirmé en
      reproduisant exactement le style du vrai `SessionButton.qml` de
      Breeze). `currentIndex` initialisé une fois depuis
      `sessionModel.lastIndex`, puis géré localement par
      `selectSession()` sans jamais rappeler `sddm` (même comportement
      que Breeze). Validé sous `sddm-greeter-qt6 --test-mode` avec
      `glass-dark` : les deux vraies sessions de la machine
      ("Plasma (Wayland)", "Plasma (X11)") apparaissent correctement,
      aucune erreur QML. Voir `Development-Journal.md`, 2026-08-02 —
      Phase 3.2 (3.2.2).
- [x] **3.2.3 — `SDDMUserAdapter` réel** : même patron `Instantiator` +
      `model.<rôle>` explicite que 3.2.2. Seuls `name` (identifiant
      système réel, transmis tel quel à `sddm.login()`), `realName`
      (repli sur `name` si vide, même logique que le vrai `breeze`) et
      `icon` sont retenus — les autres rôles `userModel` confirmés en
      3.2.0 (`homeDir`, `needsPassword`, `vtNumber`, ...) n'ont aucun
      consommateur dans le contrat actuel de `NebulaUserList`/
      `NebulaAvatar` (`Core-API.md`), donc pas repris. Validé sous
      `sddm-greeter-qt6 --test-mode` (`nord` et `glass-dark`) : les deux
      vrais comptes de la machine apparaissent correctement
      (`luust`/"luust", `claudesvc`/repli sur son propre nom faute de
      `realName`), icônes réelles résolues en `file://` valide, aucune
      erreur QML. Voir `Development-Journal.md`, 2026-08-02 — Phase 3.2
      (3.2.3).
- [x] **3.2.4 — `SDDMAuthAdapter` réel** : implémenté
      (`sddm.login(username, password, sessionIndex)`, repli sur
      `sessionModel.lastIndex` si `sessionIndex < 0` ; écoute impérative
      de `sddm.loginSucceeded`/`loginFailed`, confirmés sans argument,
      voir 3.2.0 ; `NebulaAuthService.sessionService` — référence
      optionnelle, voir DT-0024 — câblée dans `glass-dark`/`glass-light`
      pour transmettre le vrai index de session sélectionné). **Round-trip
      réel validé le 2026-08-03** sous le vrai `sddm.service` (`glass-dark`,
      protocole sûr de `nebula-vt-switch-freeze` respecté) — voir
      `Real-Adapter-Validation.md`.
- [x] Critère de sortie de phase : login réel bout-en-bout observé
      (2026-08-03, `glass-dark`, compte `luust`), documenté dans
      `Real-Adapter-Validation.md`. Phase 3.2 terminée.

**Investigation VK-001 (clavier virtuel) — close le 2026-08-03**, menée
juste après la Phase 3.2 (voir `docs/Investigations/VK-001-VirtualKeyboard.md`).
Cause identifiée avec un haut degré de confiance (symboles binaires réels
de `libQt6VirtualKeyboard.so`) : Nebula ne fournit aucun composant
`InputPanel` ("Application Integration"), donc Qt Virtual Keyboard
retombe sur son mécanisme de secours (`DesktopInputPanel`), une fenêtre
séparée aux dimensions figées, indépendantes de l'écran et du scaling Qt
de l'application — contrairement à `breeze`, qui enregistre son propre
`InputPanel`. Corrige le diagnostic provisoire de `Compatibility-Matrix.md`
§10 (2026-07-31), qui concluait à tort que ce n'était pas un bug Nebula.
**Décision produit non prise** : un composant Core dédié (mirroring
`breeze`) résoudrait vraisemblablement le problème, mais son
implémentation reste un choix séparé, à planifier explicitement plutôt
que déduit automatiquement de cette investigation.

- [x] **Correctif VK-001 implémenté (2026-08-03)** : `NebulaVirtualKeyboard`
      + `NebulaInputPanel` (`core/components/`), câblés dans `template`,
      `glass-dark`, `glass-light` (bouton bascule explicite dans le pied
      de page, `NebulaLoginLayout.bottomInset` pour garder le contenu
      visible au-dessus du clavier). `nord` hors périmètre (pas de champ
      mot de passe réel). Voir `docs/Core-API.md`,
      `docs/API-Stability-Review.md` §2,
      `docs/Investigations/VK-001-VirtualKeyboard.md` §Résolution.
- [x] **Validation réelle du correctif VK-001 (2026-08-03)** : testé
      sous `sddm.service` réel sur `blade14` (protocole VT sûr de
      `nebula-vt-switch-freeze`), sur les trois thèmes concernés
      (`template`, `glass-dark`, `glass-light`). Confirmé sur les trois
      écrans : plus d'apparition automatique, bouton bascule fiable,
      dimensionnement proportionnel, saisie fonctionnelle, aucun
      chevauchement du clavier avec le contenu de connexion, et
      `QT_SCALE_FACTOR=2` (mesuré sur `template`) affecte désormais le
      clavier comme le reste de l'UI (inverse de la preuve VK-001
      Partie 3). Deux bugs réels trouvés et corrigés pendant cette
      validation (course `keyboardActive`/`InputMethod.visible`,
      chevauchement `mainArea`/`footerArea` sur écrans à faible hauteur
      disponible) — détail complet dans
      `docs/Investigations/VK-001-VirtualKeyboard.md` §Validation
      réelle.

- [ ] `BlurEffect`, `GlowEffect`, `Particles` dans `core/effects/`
- [ ] Thèmes `cyberpunk`, `hacker`, `amoled`, `hypr`
- [x] Thème `glass` (voir sous-étape Phase 3.0 ci-dessus)
- [ ] `WallpaperEngine`, `SoundManager`

## Phase 4 — Outillage avancé (vision long terme)

Non planifié tant que les phases précédentes ne sont pas stables :

- [ ] **Nebula Designer** — application graphique compagnon permettant de
      modifier visuellement les tokens d'un thème (couleurs, animations,
      blur, glow, wallpapers, paramètres visuels du
      [Design System](Design-System.md)) puis d'exporter le résultat dans
      un format rechargeable par `NebulaThemeLoader` (ex. `theme.conf`).
      Voir le complément à DT-0003 dans `Decisions-Techniques.md`.
      Non développé maintenant — seule l'architecture (flux de theming
      dans `Theme-System.md`) est préparée dès aujourd'hui.
- [ ] Aperçu live
- [ ] Système de plugins
- [ ] Bibliothèque de shaders
- [ ] Marketplace de thèmes en ligne
- [ ] Installeur / updater de thème

Une restructuration du dépôt en `src/{core,themes,tools,shared}/` a été
étudiée pour préparer l'arrivée de Nebula Designer, mais différée — voir
DT-0008. À réévaluer seulement si cette phase devient active.

---

## Vision long terme

Nebula doit devenir une implémentation de référence pour les thèmes SDDM
modernes sous KDE Plasma. La qualité du code prime toujours sur la quantité
de fonctionnalités.
