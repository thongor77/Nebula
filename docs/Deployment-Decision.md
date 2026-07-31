# Deployment Decision — Nebula

> Comparaison objective des architectures de distribution envisagées
> pour résoudre le Constat #1 de
> [`Nord-Validation-Report.md`](Nord-Validation-Report.md) (un thème
> installé séparément du dépôt ne peut pas charger le Core). Introduit en
> Phase 2.2 (voir `Roadmap.md`). Devient l'ADR de référence sur ce sujet
> — voir aussi DT-0022 dans
> [`Decisions-Techniques.md`](Decisions-Techniques.md), qui pointe ici
> pour le détail complet plutôt que de le dupliquer.
>
> Les trois solutions ont été réellement prototypées et testées (voir
> §4) avant ce choix — rien ici n'est spéculatif.

---

## 1. Les trois solutions évaluées

### Solution A — Thème autonome (Core embarqué de façon permanente)

Chaque thème du dépôt embarque sa propre copie de `core/`/`platform/`,
committée et maintenue comme telle.

### Solution B — Core comme véritable module QML

`core/`/`platform/` installés une seule fois à un chemin système partagé
(`/usr/lib/qt6/qml/Nebula/`), consommés par tous les thèmes via
`import Nebula`.

### Solution C — Génération à l'installation

Le dépôt reste modulaire (comme aujourd'hui). Un script génère, au
moment de l'installation, un thème autonome (Core copié à côté) —
mécaniquement identique au résultat de la Solution A, mais jamais
committé : uniquement un artefact d'installation.

## 2. Comparaison

| Critère | A — Autonome | B — Module QML | C — Génération |
| --- | --- | --- | --- |
| Fonctionne sans dépôt Git | ✅ (vérifié) | ✅ (vérifié) | ✅ (vérifié) |
| Configuration système requise | Aucune | **Aucune** si installé dans le chemin QML par défaut de Qt (vérifié — voir §4) | Aucune |
| Duplication du Core | Une copie par thème, committée dans le dépôt | **Aucune** — une seule installation partagée | Une copie par thème, générée (pas committée) |
| Mise à jour du Core | Il faut mettre à jour chaque copie de thème individuellement | **Une seule mise à jour** profite à tous les thèmes installés | Il faut régénérer chaque thème installé |
| Risque de version Core incohérente entre thèmes | Réel (chaque thème peut dériver) | Aucun — un seul Core, une seule vérité | Réel si les thèmes ne sont pas tous régénérés ensemble |
| Isolation entre thèmes (un Core cassé n'affecte qu'un thème) | ✅ | ❌ — tous les thèmes partagent le même Core | ✅ |
| Complexité d'implémentation | Faible (copie simple) | Moyenne (fichier `qmldir`, structure de module) | Moyenne (script de génération + logique de copie) |
| Cohérence avec la philosophie anti-duplication du projet (`Architecture.md`, section Problème) | ❌ — recrée exactement la duplication que Nebula existe pour éliminer | ✅ | ⚠️ — la source reste propre, mais chaque installation dépliée duplique quand même sur disque |
| Taille sur disque (mesurée, `core/`+`platform/` = 192 Ko) | ~192 Ko × nombre de thèmes installés | 192 Ko, une seule fois | ~192 Ko × nombre de thèmes installés |

## 3. Choix retenu : Solution B — Core comme module QML

**Décision** : installer `core/`/`platform/` comme un module QML nommé
`Nebula`, à un chemin déjà recherché par défaut par Qt
(`/usr/lib/qt6/qml/Nebula/` sur cette distribution — voir
`qmake6 -query QT_INSTALL_QML`). Les thèmes consomment
`import Nebula` au lieu d'imports relatifs vers `core/`/`platform/`.

### Pourquoi

- **Aucune configuration système supplémentaire** : contrairement à la
  crainte initiale (`QML2_IMPORT_PATH` à définir pour le service SDDM
  réel, potentiellement absent de son environnement systemd), installer
  le module directement dans le chemin QML **par défaut** de Qt élimine
  ce problème entièrement — vérifié réellement (voir §4).
- **Seule solution sans duplication** — cohérente avec le principe
  fondateur de Nebula (`Architecture.md`, section Problème : la
  duplication de composants entre thèmes est un bug).
- **Une seule vérité** : impossible pour deux thèmes installés de
  tourner sur des versions différentes du Core, contrairement à A/C.

### Pourquoi pas les autres

- **Solution A** rejetée : reproduit exactement la duplication que
  Nebula est censé éliminer, committée en plus (le dépôt lui-même
  deviendrait incohérent avec son propre principe fondateur). Maintenance
  multipliée par le nombre de thèmes dès qu'un bug Core doit être corrigé
  partout.
- **Solution C** rejetée : la source reste propre (avantage réel sur A),
  mais le résultat installé duplique quand même sur disque et exige de
  régénérer chaque thème à chaque mise à jour du Core — complexité d'un
  script de génération sans le bénéfice de la vérité unique de B.

### Inconvénient assumé de B

Tous les thèmes installés partagent le même Core — un Core cassé ou
incompatible affecte tous les thèmes simultanément, contrairement à
l'isolation de A/C. Jugé acceptable : c'est exactement le même modèle de
couplage que n'importe quelle bibliothèque partagée système (Qt
lui-même, par exemple) — un compromis standard, pas une découverte
propre à Nebula.

## 4. Validation réelle effectuée

Les trois prototypes ont été testés avec le thème Nord réel, adapté pour
chaque solution :

- **`qml6` standalone** : les trois chargent et rendent correctement
  depuis un emplacement entièrement hors du dépôt (`/tmp/...`).
- **`sddm-greeter --test-mode`** : les trois chargent correctement sur
  les 3 écrans réels de la machine (résolutions différentes :
  1829×1029, 2743×1543, 1920×1200 — couvre de fait « plusieurs
  résolutions » et « multi-écran »).
- **Test décisif pour B** : le module installé dans
  `/usr/lib/qt6/qml/Nebula/` (chemin par défaut de Qt, confirmé via
  `qmake6 -query QT_INSTALL_QML`) se charge **sans aucune variable
  d'environnement** (`env | grep -i QML` vide, confirmé) — contrairement
  à `QML2_IMPORT_PATH` seul, qui échoue si non défini
  (`module "Nebula" is not installed`, SDDM bascule proprement sur son
  thème de secours). Testé dans les trois configurations pour bien
  isoler la cause : sans aucune variable (échec), avec
  `QML2_IMPORT_PATH` (succès), dans le chemin par défaut sans variable
  (succès) — voir `Development-Journal.md`.
- **HiDPI** (`QT_SCALE_FACTOR=2`) : testé sur B (la solution retenue),
  rendu nickel, aucun artefact.
- **Installation système réelle** : le module de B a été copié dans
  `/usr/lib/qt6/qml/Nebula/` via un accès root direct de l'utilisateur
  (cette session n'a pas de `sudo` fonctionnel) — voir
  `Development-Journal.md` pour le détail de cette contrainte
  d'environnement.

Aucun des trois prototypes n'a été conservé tel quel — voir
`scripts/install-nebula.sh` pour l'implémentation réelle de la Solution
B retenue.
