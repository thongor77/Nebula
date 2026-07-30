# SDDM Compatibility — Nebula

> Contraintes réelles de l'environnement cible. Ce document ne referme
> aucune des inconnues critiques déjà listées dans
> [`Architecture.md`](Architecture.md) — il sert à suivre, ligne par
> ligne, ce qui a été vérifié concrètement et ce qui reste supposé.
>
> **Aucune ligne marquée "à vérifier" ne doit être traitée comme acquise
> pendant l'implémentation.** Elle doit être testée avant que le Core ne
> s'appuie dessus sans plan de repli.
>
> Premières lignes levées par un test réel (Phase 1.0) : voir
> [`Prototype-Results.md`](Prototype-Results.md).

---

## 1. Environnement cible

- SDDM 0.21+
- Qt6
- KDE Plasma 6
- Wayland en priorité (X11 en compatibilité — voir DT-0001)

## 2. Matrice de compatibilité

| Fonction           | Statut                        | Notes |
| -------------------- | -------------------------------- | ------- |
| QML                  | Vérifié                          | Les greeters SDDM sont chargés en QML depuis SDDM 0.18+ ; c'est le mécanisme de base, pas une inconnue. Confirmé réellement par `Prototype-Results.md` (SDDM 0.21.0-7, Qt 6.11.1). |
| QtQuick              | Vérifié                          | Module de base requis par tout greeter QML. Confirmé par `Prototype-Results.md`. |
| QtQuick.Controls     | Vérifié                          | Présent dans `qt6-declarative` (styles Basic/Fusion/Material/Universal/FluentWinUI3), dépendance directe du paquet `sddm` — voir `Prototype-Results.md` §1. Reste "à vérifier" : le rendu visuel réel d'un contrôle Controls dans le greeter (seule la présence du module a été confirmée, pas son usage). |
| QtQuick.Shapes       | Vérifié (présence du module)     | `qmldir` présent dans `qt6-declarative` — voir `Prototype-Results.md` §1. Rendu réel non testé (aucun `Shape` utilisé dans le prototype, hors périmètre Phase 1.0). |
| ShaderEffect         | À vérifier                       | Explicitement hors périmètre du prototype Phase 1.0 (brief : "ne pas créer de shaders"). `qt6-shadertools` est installé, mais seule la présence du paquet est confirmée, pas l'exécution. |
| Blur                 | À vérifier — inconnue critique   | Coût réel non mesuré sur matériel bas de gamme (`Architecture.md`, Inconnues critiques). Explicitement hors périmètre du prototype Phase 1.0. |
| Multi écran          | **Vérifié** — comportement confirmé | Une `QQuickView` par écran physique, chacune chargeant `Main.qml` indépendamment avec son propre `screenModel` (count=1 dans chaque vue) — voir `Prototype-Results.md` §3.3. Testé avec 3 écrans réels (dont deux échelles différentes). |
| HiDPI                | Vérifié (géométrie), rendu pixel à vérifier | Géométries de fenêtre confirmées en coordonnées logiques post-scaling sur un vrai setup mixte (échelles 1 et 1.4 simultanées) — voir `Prototype-Results.md` §3.4. Le rendu visuel pixel (netteté, artefacts) reste à vérifier. |
| Animations GPU       | À vérifier — inconnue critique   | Lié directement au point "Blur" et au coût des effets GPU. Explicitement hors périmètre du prototype Phase 1.0. |
| Vidéo background     | À vérifier                       | Dépend de la disponibilité de Qt Multimedia dans l'environnement (souvent restreint) du greeter — non testé (hors périmètre Phase 1.0). |
| Audio login          | À vérifier                       | Les processus greeter SDDM tournent historiquement dans une session restreinte sans accès garanti au bus audio utilisateur — point de vigilance connu sur d'autres greeters QML, à confirmer pour Nebula. Non testé en Phase 1.0. |
| Permissions utilisateur sddm | À vérifier — risque transverse | L'utilisateur système `sddm` peut avoir un accès restreint (lecture de fichiers hors des chemins standards, groupes GPU/audio, confinement AppArmor/SELinux selon la distribution) — impacte potentiellement le chargement d'assets de thème, les effets GPU et l'audio simultanément. Non testé : le prototype Phase 1.0 a tourné en mode test (sous l'utilisateur courant), pas via le service SDDM réel sous l'utilisateur système `sddm` — voir `Prototype-Results.md` §3.6. |
| Authentification (`sddm.login()`) | À vérifier | Le mode test n'a pas de backend d'authentification réel (`QLocalSocket::connectToServer: Invalid name`) — voir `Prototype-Results.md` §3.5. Un vrai lancement de service serait nécessaire pour tester de bout en bout, délibérément non tenté (risque disproportionné pour un prototype jetable). |

## 3. Comment lever une inconnue

Chaque ligne "à vérifier" doit être levée par un test concret sur une
installation SDDM 0.21+ réelle (Wayland puis X11), avant que la Phase 1
ne s'appuie dessus sans plan de repli :

1. Décrire le test minimal (ex. un greeter de test avec un seul
   `ShaderEffect`).
2. Exécuter via l'environnement décrit dans
   [`Development-Environment.md`](Development-Environment.md).
3. Noter le résultat dans ce tableau (`Statut` → `Vérifié` ou
   `Non supporté`, avec la note expliquant pourquoi).
4. Si un point s'avère non supporté, mettre à jour
   [`Architecture.md`](Architecture.md) (Inconnues critiques) et, si
   l'impact est structurant, ajouter une décision dans
   [`Decisions-Techniques.md`](Decisions-Techniques.md).

## 4. Statut global

Tant que les lignes "à vérifier" n'ont pas été testées, aucun composant
Core dépendant de ces fonctions (`NebulaBlurEffect`, `NebulaGlowEffect`,
`NebulaParticles`, `NebulaWallpaperEngine` en mode vidéo, `NebulaSoundManager`)
ne doit être considéré comme un prérequis du Core MVP — voir `Roadmap.md`,
Phase 1 : ces composants doivent pouvoir être désactivés proprement
(`effects.enableEffects`, voir `Design-System.md`) sans casser le reste du
Core.
