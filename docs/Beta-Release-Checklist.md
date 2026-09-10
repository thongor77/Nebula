# 0.1 Beta Release Checklist — Nebula

> Liste de vérification avant de considérer la 0.1 Beta prête. Un seuil
> de qualité de release, pas une exigence de complétude fonctionnelle
> (brief Phase 3.3, §5) : chaque porte ci-dessous s'appuie sur un outil
> ou une validation déjà existante — aucun nouvel outillage inventé pour
> ce document.

---

## Portes de validation

| Porte | Comment elle est vérifiée |
|---|---|
| Zéro avertissement QML sur tout le dépôt | `find . -name "*.qml" -not -path "./.git/*" \| xargs qmllint` (déjà documenté dans [`Development-Environment.md`](Development-Environment.md) §6) |
| Chaque thème officiel structurellement sain | `scripts/check-theme.sh <nom>` → `PASS` pour `template`, `nord`, `glass-dark`, `glass-light` |
| Round-trip install/uninstall propre | `scripts/check-installation.sh` → `PASS` après un cycle réel `install-nebula.sh`/`uninstall-nebula.sh` sur une machine réelle |
| Validation réelle multi-écran/HiDPI | `sddm-greeter-qt6 --test-mode` lancé pour chaque thème officiel sur du matériel réel à DPI mixte, vérifié par capture d'écran (même méthode déjà utilisée pour Dashboard et VK-001) |
| Aucune dette Critique/Importante non résolue | [`Architecture-Review-2026.md`](Architecture-Review-2026.md) §9 — Critique : aucune trouvée ; Importante : les deux éléments (duplication `scripts/lib/common.sh`, `MockAuthAdapter.login()`) résolus en Phase 3.3 |
| Documentation interne cohérente | Les incohérences documentaires de Phase 3.3 (`Core-API.md` vs README, commentaires obsolètes) toutes corrigées — `Core-API.md` ne contredit plus `README.md` |
| Chaque public a un point de départ documenté | Section "Where to start" du `README.md` existe et ses liens résolvent |
| Déclaration de stabilité SDK existante, jamais étiquetée 1.0 | [`API-Stability-Review.md`](API-Stability-Review.md) à jour (voir §0 de ce document) |

## Ce que cette checklist ne couvre pas volontairement

Conformément au brief Phase 3.3 §6 ("What not to do before 0.1") :
aucune de ces portes n'exige l'ajout de fonctionnalités (info système,
Dashboard officiel, thèmes placeholder supplémentaires) — la 0.1 Beta
est prête quand ce qui existe déjà est cohérent et validé, pas quand
davantage a été ajouté.

## Utilisation

À exécuter avant toute annonce publique de la 0.1 Beta, et à nouveau
avant toute future version mineure de la ligne 0.1 — chaque porte reste
rapide à rejouer (aucune n'exige plus que les scripts/commandes déjà
listés ci-dessus).
