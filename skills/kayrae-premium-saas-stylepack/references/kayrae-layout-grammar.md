# Kayrae Layout Grammar

> Section composition, spacing rhythm, responsive patterns.

## Core Principle

```
Layout is NOT a grid system. Layout is editorial rhythm.
Every section has a different spatial weight.
Every breakpoint is intentional.
620px is the primary mobile break, not 768px.
```

## Section Composition Order

```
The Kayrae narrative arc:

1. HERO          — Mass, gravity. "This is important."
                  min-h-screen, centered, maximal atmosphere

2. TRUST         — Proof, brevity. "You can trust us."
                  compact horizontal strip, minimal space

3. FEATURES      — Depth, exploration. "Here's what we offer."
                  generous grid, cards with room to breathe

4. PROCESS       — Flow, sequence. "Here's how it works."
                  vertical timeline, numbered, connector line

5. WHY US        — Reinforcement. "And here's why we're different."
                  benefits grid, can be tighter spacing

6. GALLERY       — Evidence, visual proof. "See our work."
                  visual grid, images dominate

7. FAQ           — Reassurance, depth. "Your questions answered."
                  wide single column, generous line height

8. COVERAGE      — Context, breadth. "We're everywhere you need."
                  location cards, compact

9. FINAL CTA     — Conversion, urgency. "Let's work together."
                  single panel, maximal impact, no distractions
```

## Section Spacing System

```
Hero:          min-h-screen (fills viewport)
               Content vertically centered

Trust:         py-16 md:py-20
               Compact. Quick stats. Don't waste space.

Features:      py-section (clamp(4rem, 8vw, 8rem))
               Generous. Cards need breathing room.

Process:       py-section
               Matches Features. Paired sections.

Why Us:        py-section
               Benefits grid. Can be slightly tighter.

Gallery:       py-section
               Visual content. More space = more impact.

FAQ:           py-20 md:py-24
               Reading-heavy. Generous line height.

Coverage:      py-section
               Compact location cards.

Final CTA:     py-24 md:py-32
               Biggest spacing. Finale.
```

## Responsive Breakpoints

```
max-[420px]:   Small mobile
               → Single column everything
               → Reduced heading scale
               → Full-width buttons

max-[620px]:   Primary mobile break (NOT 768px)
               → MobileCTABar visible
               → Grids go single column
               → Section spacing reduces
               → Touch targets ≥44px

max-[860px]:   Tablet
               → Navbar switches to Sheet menu
               → Can use 2-column grids

1024px+:       Desktop
               → 3-column grids
               → Nav links visible inline

1440px+:       Wide
               → Container max-w-7xl (80rem)
               → Content centered, not stretched
```

## Container Rules

```tsx
// Standard container
<div className="mx-auto max-w-7xl px-[var(--spacing-section-x)]">
  {/* px = clamp(1.5rem, 5vw, 3rem) — fluid side padding */}
</div>

// Full-bleed section (for atmosphere layers)
<section className="relative overflow-hidden">
  {/* Atmosphere layers: absolute inset-0, no container */}
  <div className="relative z-10 mx-auto max-w-7xl px-[var(--spacing-section-x)]">
    {/* Content: in container */}
  </div>
</section>
```

## Grid Patterns

### 3-Column Card Grid
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
```
Used for: Services, Benefits, Gallery

### 2-Column Split
```tsx
<div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12">
```
Used for: Feature detail, before/after

### Horizontal Strip
```tsx
<div className="flex flex-col md:flex-row justify-center gap-8 md:gap-16">
```
Used for: Trust metrics, stats

### Vertical Timeline
```tsx
<div className="flex flex-col gap-8 md:gap-10 max-w-3xl mx-auto">
```
Used for: Process steps

### Single Column (Reading)
```tsx
<div className="max-w-2xl mx-auto">
```
Used for: FAQ, long-form content

## Anti-Patterns (FAIL)

```
❌ Every section has the same py-* spacing
❌ Every section is text-center
❌ Every section uses the same grid (grid-cols-3 everywhere)
❌ 768px breakpoint instead of 620px
❌ Container max-w-7xl on everything (some sections need tighter width)
❌ Full-width content without container (except hero)
❌ Mobile as an afterthought (desktop-first CSS)
```

## Layout Audit Checklist

```
[ ] Section spacing varies (not uniform)
[ ] Hero is min-h-screen
[ ] Trust strip is compact (py-16)
[ ] Feature/process sections are generous (py-section)
[ ] FAQ is reading-optimized (wider spacing, max-w-2xl)
[ ] Final CTA is biggest spacing (py-24+)
[ ] 620px is the primary mobile break
[ ] MobileCTABar visible ≤620px
[ ] No horizontal scroll at any breakpoint
[ ] Container max-w-7xl with fluid px
[ ] Section order follows narrative arc
[ ] Each section has unique spatial weight
```
