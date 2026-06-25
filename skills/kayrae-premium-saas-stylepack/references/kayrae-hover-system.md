# Kayrae Hover System

> Micro-interaction grammar for premium dark editorial surfaces.

## Core Principle

```
Hover is NOT decoration. Hover is product feedback.
Every hover state communicates: "I am interactive. I respond precisely. I am well-made."
```

## The Forbidden Pattern

```tsx
// ❌ THIS IS THE ENEMY. Never write this.
className="transition-all duration-300 hover:scale-105 hover:bg-white/10"
```

Why it fails:
- `transition-all` animates expensive properties (width, height, padding, margin)
- `scale-105` causes sub-pixel rendering, blurry text, layout shift
- `bg-white/10` is the laziest possible hover state
- `duration-300` is the wrong speed for micro-interactions

## The Premium Pattern

```tsx
// ✅ THIS IS THE STANDARD. Adapt per component.
className="
  transition-[transform,border-color,background-color,box-shadow]
  duration-200
  ease-editorial
  hover:translate-y-[-3px]
  hover:border-brand-accent/25
  hover:bg-bg-card-elevated
  hover:shadow-card-hover
"
```

Why it works:
- Only 4 specific properties animate (GPU-composited)
- 200ms — fast enough to feel responsive, slow enough to perceive
- editorial easing — custom cubic-bezier, feels distinctive
- y-translation — crisp, pixel-perfect (not sub-pixel scale)
- Border accent — visual "activation" signal
- Shadow depth — elevation change, physical metaphor

## Per-Component Grammar

### Button Hover

```tsx
// Primary / WhatsApp
className="
  transition-[transform,filter] duration-150 ease-editorial
  hover:brightness-110 hover:translate-y-[-1px]
  active:scale-[0.98]
"

// Secondary / Ghost
className="
  transition-[transform,border-color,color] duration-150 ease-editorial
  hover:border-brand-accent/30 hover:translate-y-[-1px]
  active:scale-[0.98]
"
```

**Button rules:**
- 150ms (fastest hover — buttons are immediate actions)
- brightness-110 for filled buttons (keeps text contrast)
- border accent for outlined buttons
- active: scale-[0.98] — press feedback
- y: -1px (subtle — buttons are small, doesn't need -3px)

### Card Hover

```tsx
// Interactive card
className="
  transition-[transform,border-color,background-color,box-shadow]
  duration-200 ease-editorial
  hover:translate-y-[-3px]
  hover:border-brand-accent/25
  hover:bg-bg-card-elevated
  hover:shadow-card-hover
"
```

**Card rules:**
- 200ms (medium — cards are larger surfaces)
- y: -3px to -4px (noticeable elevation)
- Border accent 25% (strong signal)
- Shadow depth increase
- Background subtle elevation (#0A0A0A → #111111)
- Inner elements: independent reveal (icon moves 2-4px, glow fades in)

### Card Inner Elements

```tsx
// Inside a hovered card
<div className="group">

  {/* Hidden glow — appears on hover */}
  <div className="
    absolute inset-0 rounded-3xl
    opacity-0 group-hover:opacity-100
    transition-opacity duration-500 ease-editorial
  " style={{
    background: 'radial-gradient(400px circle at center, rgba(0,212,255,0.08), transparent 60%)'
  }} />

  {/* Icon — subtle lift */}
  <span className="
    text-3xl transition-transform duration-200 ease-editorial
    group-hover:translate-y-[-2px]
  ">{icon}</span>

  {/* Border beam — appears on hover */}
  <BorderBeam className="
    opacity-0 group-hover:opacity-100
    transition-opacity duration-500
  " />

</div>
```

### Nav Link Hover

```tsx
// Navigation links
className="
  text-sm text-text-secondary
  transition-colors duration-150 ease-editorial
  hover:text-text-primary
"
```

**Nav rules:**
- 150ms (fast — navigation should feel instant)
- Color-only transition (no transform — nav items don't need elevation)
- text-secondary → text-primary (subtle activation)

### Gallery Thumb Hover

```tsx
// Gallery image thumbnail
<div className="group relative overflow-hidden rounded-2xl">

  {/* Image — subtle scale within container */}
  <div className="
    transition-transform duration-500 ease-editorial
    group-hover:scale-[1.03]
  ">{image}</div>

  {/* Overlay — fades in */}
  <div className="
    absolute inset-0
    bg-brand-accent/0 group-hover:bg-brand-accent/10
    transition-colors duration-300 ease-editorial
  " />

  {/* Caption — slides up */}
  <div className="
    absolute bottom-0 inset-x-0 p-3
    translate-y-full group-hover:translate-y-0
    transition-transform duration-300 ease-editorial
  ">
    <span className="text-xs bg-bg-base/90 backdrop-blur-sm rounded-lg px-3 py-1.5">
      {caption}
    </span>
  </div>

</div>
```

**Gallery rules:**
- Image scale 1.03 inside overflow-hidden (contained, no layout shift)
- Overlay fade (not scale, not brightness)
- Caption slide-up (separate timing from overlay)
- 300ms (slower — larger visual change, more to appreciate)

### FAQ Toggle Hover

```tsx
// FAQ question button
className="
  w-full flex items-center justify-between py-[18px]
  transition-colors duration-150 ease-editorial
  group
"
// Icon rotation on open — CSS, not JS animation
className="
  transition-transform duration-200 ease-editorial
  group-hover:text-brand-accent
  data-[open]:rotate-45
"
```

## Timing Reference

| Component | Duration | Properties | Notes |
|-----------|----------|------------|-------|
| Button | 150ms | transform, filter, border-color | Fastest — immediate action |
| Nav link | 150ms | color | Fastest — navigation |
| Card | 200ms | transform, border, bg, shadow | Medium — surface elevation |
| Card inner | 200-500ms | opacity, transform (staggered) | Children animate after container |
| Gallery overlay | 300ms | background-color | Slower — visual reveal |
| Gallery caption | 300ms | transform (translate-y) | Slide up, parallel with overlay |
| Border beam | 500ms | opacity (appear/disappear) | Slowest — decorative, not functional |

## Easing

```
ALL hovers use: cubic-bezier(0.22, 1, 0.36, 1)
Tailwind: ease-editorial
Framer: ease: [0.22, 1, 0.36, 1]
```

Never use:
- ease-in (feels sluggish)
- ease-out (feels generic)
- ease-in-out (Tailwind default — too symmetric)
- linear (feels robotic)

## Hover Audit Checklist

```
[ ] Zero instances of transition-all anywhere
[ ] Zero instances of scale-105 (or any hover scale)
[ ] Zero instances of hover:bg-white/10
[ ] Every interactive element has hover state
[ ] Hover uses targeted properties (4 max)
[ ] Timing matches component type (150-500ms range)
[ ] All hovers use editorial easing
[ ] Inner elements have independent reveal timing
[ ] No hover causes layout shift
[ ] No hover on non-interactive elements
[ ] prefers-reduced-motion: all hover animations disabled
```
