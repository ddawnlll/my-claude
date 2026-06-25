# Kayrae Motion Grammar

> Per-section cinematic moments. One thing moves at a time. Never spam.

## Core Principle

```
Motion is NOT entertainment. Motion is spatial narration.
Every animation answers: "Where am I? What happened? What's next?"
```

## The Golden Rule

```
ONE CINEMATIC MOMENT PER SECTION.

Not "everything animates."
Not "nothing animates."
ONE thing per section provides motion interest.
Everything else is static or has subtle hover states.
```

## Per-Section Motion Map

### Hero Section

```
PRIMARY MOMENT:    Headline stagger-text (blur + y + opacity)
                    0.06s/word stagger, 0.85s total, editorial easing

SECONDARY (subtle): CTA card reveal (delayed y:20→0)
                    0.5s delay after headline, 0.6s duration

ATMOSPHERE:         RadialGlow pulse (CSS, not counted as moment)
                    8s ease-in-out, subtle breath

FORBIDDEN:
  - Hero image parallax (unless it IS the product canvas)
  - Everything fading in at once
  - Text flying from random directions
```

```tsx
// Hero motion structure
<>
  {/* Moment 1: Headline stagger */}
  <StaggerText
    text="Gebze'de <em>fiber</em> artık ulaşılabilir"
    as="h1"
    className="text-hero font-bold text-gradient-hero"
  />

  {/* Not animated — just static text */}
  <p className="mt-6 text-body-lg text-text-secondary">
    10+ yıllık tecrübemizle...
  </p>

  {/* Moment 2: CTA reveal (delayed) */}
  <motion.div
    initial={{ y: 20, opacity: 0 }}
    animate={{ y: 0, opacity: 1 }}
    transition={{ duration: 0.6, delay: 0.8, ease: [0.22, 1, 0.36, 1] }}
  >
    <Card variant="glass">
      {/* CTA buttons */}
    </Card>
  </motion.div>
</>
```

### TrustStrip Section

```
PRIMARY MOMENT:    BlurReveal tiles
                   0.85s each, 0.18s stagger, editorial easing

TECHNIQUE:         filter: blur(10px) → blur(0px) + opacity
                   This is THE Kayrae signature motion.

FORBIDDEN:
  - Simple fade-in (too generic)
  - Scale reveal (cheap)
  - All tiles animating simultaneously
```

```tsx
{trustMetrics.map((metric, idx) => (
  <BlurReveal key={metric.label} delay={idx * 0.18}>
    <div className="text-center">
      <span className="text-h2 font-bold text-gradient-cyan">{metric.value}</span>
      <span className="text-sm text-text-secondary">{metric.label}</span>
    </div>
  </BlurReveal>
))}
```

### Services / Card Grid Section

```
PRIMARY MOMENT:    Staggered card entrance
                   0.6s each, 0.18s stagger, y:32→0, editorial easing

SECONDARY:         Hover micro-interaction (not counted as "moment")
                   Border beam appear + card elevation

FORBIDDEN:
  - All cards fading at once
  - Cards animating from different directions
  - Hover scale (use y-translation)
```

### Process Section

```
PRIMARY MOMENT:    Staggered step reveal
                   0.4s each, 0.18s stagger, y:20→0, editorial easing

CONNECTOR:         Clip-path reveal (CSS, not Framer)
                   inset(0 100% 0 0) → inset(0 0 0 0)
                   1.4s, editorial easing, triggers on viewport enter

FORBIDDEN:
  - All steps animating simultaneously
  - Connector animated with JavaScript (use CSS clip-path)
  - Steps animating from different directions
```

### WhyUs Section

```
PRIMARY MOMENT:    Staggered card entrance
                   0.6s each, 0.15s stagger (tighter — 6 cards)

ATMOSPHERE:        DotGrid background (static CSS, not animated)

NOTE:              This section can also be static (server component)
                   if the cards aren't the primary visual interest.
```

### Gallery Section

```
PRIMARY MOMENT:    Staggered thumbnail entrance
                   0.5s each, 0.08s stagger (fast — 6 items)

SECONDARY:         Lightbox dialog enter/exit
                   AnimatePresence, zoom-in-95

HOVER:             Caption slide-up + overlay fade
```

### FAQ Section

```
PRIMARY MOMENT:    CSS grid-template-rows accordion
                   0.3s ease, 0fr ⇄ 1fr

NOTE:              Zero JavaScript for the animation itself.
                   Only JS for tracking which item is open.
                   The animation is pure CSS, GPU-accelerated.

FORBIDDEN:
  - JavaScript height calculations
  - max-height animation hacks
  - Framer Motion for accordion (overkill, worse perf)
```

### ServiceArea Section

```
MOTION:            None. Static server component.

RATIONALE:         This is informational content. Not every section
                   needs a cinematic moment. Restraint = sophistication.
```

### FinalCTA Section

```
MOTION:            None. Static panel.

RATIONALE:         The CTA is the final message. Animation would
                   distract from the conversion goal. Static weight
                   communicates confidence.
```

## Stagger Reference

```
ALWAYS 0.18s between items. This is the Kayrae standard.

3 items:  0s, 0.18s, 0.36s
4 items:  0s, 0.18s, 0.36s, 0.54s
6 items:  0s, 0.15s, 0.30s, 0.45s, 0.60s, 0.75s (tighter for grids)
8 items:  0s, 0.10s, 0.20s, ... 0.70s (tight for large grids)

Words:    0.06s between words (hero stagger-text)
```

## Easing Reference

```
EDITORIAL (primary):  cubic-bezier(0.22, 1, 0.36, 1)
                      → Section reveals, hover, blur reveal, stagger

DEFAULT (Tailwind):   cubic-bezier(0.4, 0, 0.2, 1)
                      → NEVER use for reveals. Only for very fast UI.

SPRING (optional):    cubic-bezier(0.175, 0.885, 0.32, 1.275)
                      → Only for success/confirmation animations

NONE (scroll):        linear
                      → For continuous scroll-driven animations only
```

## Duration Reference

| Purpose | Duration | Easing |
|---------|----------|--------|
| Button hover | 150ms | editorial |
| Nav hover | 150ms | editorial |
| Card hover | 200ms | editorial |
| Card entrance | 600ms | editorial |
| Process step | 400ms | editorial |
| Blur reveal | 850ms | editorial |
| Border beam | 2200ms | linear |
| Glow pulse | 8000ms | ease-in-out |
| Grid drift | 20000ms | linear |
| FAQ accordion | 300ms | ease |
| Gallery lightbox | 300ms | editorial |

## What NOT to Animate

```
❌ Bounce/spring (unless delivering success feedback)
❌ Spin/rotate (unless a loading indicator)
❌ Parallax overkill (one layer max, and only if justified)
❌ Scroll-jacking (smooth-scroll hijack = FAIL)
❌ Random reveals (every section should NOT animate)
❌ Same animation on every element (lazy, boring)
❌ Animations that compete for attention
❌ Animations slower than 1s (feels sluggish)
❌ Animations faster than 100ms (imperceptible)
```

## Reduced Motion

```
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

Framer Motion:
<MotionConfig reducedMotion="user">
```

This is MANDATORY. No exceptions. Every animation must have a reduced-motion path.

## Motion Audit Checklist

```
[ ] Hero has stagger-text (or blur-reveal) — NOT raw opacity fade
[ ] TrustStrip has BlurReveal tiles (Kayrae signature)
[ ] Services has staggered card entrance (0.18s)
[ ] Process has staggered steps + clip-path connector
[ ] WhyUs: staggered OR static (either is acceptable)
[ ] Gallery: staggered thumbnails + lightbox transition
[ ] FAQ: CSS grid-template-rows accordion (zero JS)
[ ] ServiceArea: static (no animation)
[ ] FinalCTA: static (no animation)
[ ] Total cinematic moments = section count (not element count)
[ ] All animations use editorial easing
[ ] All staggers are 0.18s (or 0.15s/0.10s for >5 items)
[ ] prefers-reduced-motion global override present
[ ] MotionConfig reducedMotion="user" on all Framer components
[ ] No bounce/spring without justification
[ ] No parallax without justification
[ ] No random motion
[ ] No scroll-jacking
```
