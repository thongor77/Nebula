# Nebula Principles

> Règles fondamentales du projet. Volontairement peu nombreuses et
> stables — elles peuvent évoluer, mais toute évolution doit être
> délibérée (voir `Decisions-Techniques.md` pour tracer un changement).
> Chaque principe pointe vers le document qui le détaille.

---

1. **Le Core ne connaît jamais un thème.** Aucun nom de thème
   (`cyberpunk`, `nord`, ...) n'apparaît dans `core/` — voir
   [`Core-API.md`](Core-API.md) §1.
2. **Le Core ne connaît jamais SDDM directement.** Voir
   [`Services-Architecture.md`](Services-Architecture.md).
3. **Les composants utilisent uniquement `NebulaThemeProvider`** pour
   toute valeur visuelle — jamais `ThemeConfig`/`ThemeLoader`
   directement. Voir DT-0006 dans
   [`Decisions-Techniques.md`](Decisions-Techniques.md).
4. **Les composants utilisent uniquement les Services** pour toute
   interaction avec le système — jamais SDDM directement. Voir
   [`Services-Architecture.md`](Services-Architecture.md).
5. **Les Services utilisent uniquement les Platform Adapters** — jamais
   d'API système en dur dans un Service. Voir
   [`Services-Architecture.md`](Services-Architecture.md).
6. **Les Platform Adapters sont les seuls à dialoguer avec SDDM.** Voir
   `platform/sddm/`.
7. **Les thèmes n'étendent jamais le Core par copie.** Composition
   uniquement — voir DT-0002 dans
   [`Decisions-Techniques.md`](Decisions-Techniques.md).
8. **Toute découverte réelle est documentée** dans
   [`Development-Journal.md`](Development-Journal.md) — pas seulement
   corrigée en silence.
9. **Toute limitation connue est assumée ou documentée** — jamais
   ignorée silencieusement (ex. débordement vertical de
   `NebulaLoginLayout` sur ratio extrême, voir
   `Core-Implementation-Status.md`).
10. **Les API publiques évoluent de manière compatible autant que
    possible.** Toute rupture volontaire est tracée dans
    [`Decisions-Techniques.md`](Decisions-Techniques.md) (voir DT-0009).
