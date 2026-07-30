# SDDM Compatibility — Nebula

> Contraintes réelles de l'environnement cible. Ce document ne referme
> aucune des inconnues critiques déjà listées dans
> [`Architecture.md`](Architecture.md) — il sert à suivre, ligne par
> ligne, ce qui a été vérifié concrètement et ce qui reste supposé.
>
> **Aucune ligne marquée "à vérifier" ne doit être traitée comme acquise
> pendant l'implémentation.** Elle doit être testée avant que le Core ne
> s'appuie dessus sans plan de repli.

---

## 1. Environnement cible

- SDDM 0.21+
- Qt6
- KDE Plasma 6
- Wayland en priorité (X11 en compatibilité — voir DT-0001)

## 2. Matrice de compatibilité

| Fonction           | Statut                        | Notes |
| -------------------- | -------------------------------- | ------- |
| QML                  | Vérifié                          | Les greeters SDDM sont chargés en QML depuis SDDM 0.18+ ; c'est le mécanisme de base, pas une inconnue. |
| QtQuick              | Vérifié                          | Module de base requis par tout greeter QML. |
| QtQuick.Controls     | À vérifier                       | Disponibilité et thème par défaut du module dans l'environnement du greeter selon la distribution (packaging Qt6 minimal parfois utilisé pour SDDM) — voir DT-0007. |
| QtQuick.Shapes       | À vérifier                       | Dépend du backend de rendu du greeter, non testé à ce jour. |
| ShaderEffect         | À vérifier                       | Dépend du backend de scène Qt Quick actif (OpenGL/software) dans le contexte du greeter — inconnue critique, voir `Architecture.md`. |
| Blur                 | À vérifier — inconnue critique   | Coût réel non mesuré sur matériel bas de gamme (`Architecture.md`, Inconnues critiques). |
| Multi écran          | À vérifier — inconnue critique   | Comportement exact de SDDM avec plusieurs sorties Wayland non confirmé (`Architecture.md`, Inconnues critiques). |
| HiDPI                | Probable, à confirmer            | Géré nativement par Qt6 en général ; comportement spécifique au processus greeter SDDM non testé. |
| Animations GPU       | À vérifier — inconnue critique   | Lié directement au point "Blur" et au coût des effets GPU. |
| Vidéo background     | À vérifier                       | Dépend de la disponibilité de Qt Multimedia dans l'environnement (souvent restreint) du greeter — non testé. |
| Audio login          | À vérifier                       | Les processus greeter SDDM tournent historiquement dans une session restreinte sans accès garanti au bus audio utilisateur — point de vigilance connu sur d'autres greeters QML, à confirmer pour Nebula. |

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
