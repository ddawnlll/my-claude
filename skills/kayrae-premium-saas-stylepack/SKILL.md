---
name: kayrae-premium-saas-stylepack
description: Specific aesthetic DNA for Kayrae/Giydiriyo-level premium dark editorial SaaS. This is a STYLEPACK — it provides component grammar, atmosphere recipes, layout patterns, and motion rhythm. Does NOT replace premium-frontend-director (which owns quality gates). Use when building dark SaaS marketing sites, product landing pages, or editorial-tech surfaces that need Kayrae-level visual identity. Provides copyable visual grammar without cloning.
---

# Kayrae Premium SaaS Stylepack

## Role

You are a **style reference**, not a quality gate. This stylepack provides the specific aesthetic DNA for Kayrae/Giydiriyo-level premium dark editorial SaaS. For quality enforcement, use `premium-frontend-director`. For general design knowledge, use `frontend-design`. For implementation, use relevant animation libraries only when CSS is insufficient.

```
HIERARCHY:
  premium-frontend-director  ← Quality gate, audit, PASS/FAIL
  kayrae-premium-saas-stylepack  ← Aesthetic DNA (THIS SKILL)
  frontend-design               ← General design principles
  motion-framer / gsap          ← Implementation tools (last resort)
```

## Core Identity

```
AESTHETIC:    Editorial-Tech — magazine sophistication meets product precision
PALETTE:      True-black stack + warm metallic accent (copper/gold) OR cool cyan
TEXTURE:      Analog warmth on digital surfaces (grain, dot grid, radial glow)
TYPOGRAPHY:   3-font system — sans primary + serif editorial + mono technical
MOTION:       One cinematic moment per section, editorial easing, .18s stagger
HOVER:        Micro-state grammar — y-translation + border accent + shadow depth
DEPTH:        5-7 background layers, CSS-only, zero JavaScript
```

## When to Use

```
USE THIS STYLEPACK WHEN:
  - Building dark SaaS marketing sites
  - Product landing pages needing editorial sophistication
  - Dark editorial surfaces with layered atmosphere
  - Any project targeting Kayrae/Giydiriyo visual quality level

DO NOT USE WHEN:
  - Light theme required (this is dark-editorial)
  - E-commerce / marketplace (different visual grammar needed)
  - Dashboard / data-heavy (this is marketing, not app UI)
  - Minimalist / brutalist (too much atmosphere for that)
```

## Visual DNA in 30 Seconds

```
1. The page doesn't have a "background color." It has atmosphere.
   → 5+ CSS layers, zero JS

2. Text doesn't just sit there. It has editorial personality.
   → [&_em]:font-serif makes every <em> automatically italic serif

3. Cards don't just exist. They have a surface hierarchy.
   → border opacity 6%→10%→25%, glass with backdrop-blur

4. Hover isn't scale-105. It's a micro-interaction grammar.
   → y:-3px, border accent, shadow depth, inner glow reveal

5. Motion isn't "everything fades in." It's one moment per section.
   → blur reveal for stats, stagger for cards, clip-path for connectors

6. Mobile isn't an afterthought. 620px is the primary breakpoint.
   → clamped typography, aggressive stack, bottom CTA bar
```

## Bundled References

This stylepack includes deep-dive reference docs for each system:

- `references/kayrae-layout-grammar.md` — Section composition, spacing rhythm, responsive patterns
- `references/kayrae-background-system.md` — 5-7 layer atmosphere architecture, CSS recipes
- `references/kayrae-hover-system.md` — Micro-interaction grammar, timing, per-component rules
- `references/kayrae-motion-grammar.md` — Per-section cinematic moments, easing, stagger
- `references/kayrae-component-recipes.md` — Copyable component templates (hero, cards, CTA, FAQ)
- `references/kayrae-anti-clone-policy.md` — What to copy vs what to NOT copy from reference sites
