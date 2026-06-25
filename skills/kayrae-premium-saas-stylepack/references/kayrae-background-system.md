# Kayrae Background System

> 5–7 layer CSS-only atmosphere architecture. Zero JavaScript. Copy the technique, not the exact colors.

## Layer Architecture

```
┌─────────────────────────────────────────┐
│ LAYER 7: Card-local glow                │  radial-gradient on individual cards
│          (NOT global blob)              │  opacity 0.08–0.12, positioned per-card
├─────────────────────────────────────────┤
│ LAYER 6: Section vignette               │  radial-gradient edge darkening
│          (framing device)               │  inset, transparent center → dark edges
├─────────────────────────────────────────┤
│ LAYER 5: Noise texture                  │  SVG feTurbulence, opacity 0.04
│          (analog warmth)                │  mix-blend-overlay, pointer-events-none
├─────────────────────────────────────────┤
│ LAYER 4: Dot grid or matrix             │  radial-gradient(circle, dots)
│          (geometric texture)            │  mask-faded to edges
├─────────────────────────────────────────┤
│ LAYER 3: Secondary muted glow           │  warm/cool counter, offset position
│          (color balance)                │  mix-blend-overlay, very low opacity
├─────────────────────────────────────────┤
│ LAYER 2: Primary radial glow            │  accent-colored, hero-anchored
│          (atmospheric light)            │  mix-blend-overlay, pulse animation
├─────────────────────────────────────────┤
│ LAYER 1: Deep base color                │  #050505 page, #080808 sections
│          (foundation)                   │  True black, never pure #000
└─────────────────────────────────────────┘
```

## Layer Recipes

### LAYER 1: Base Color

```css
/* Page */
body { background-color: #050505; }

/* Section alternation */
section:nth-child(odd)  { background-color: #050505; }
section:nth-child(even) { background-color: #080808; }

/* NEVER pure #000 — use #050505 minimum */
```

### LAYER 2: Primary Radial Glow

```tsx
// Hero area — accent-colored atmospheric light
<div
  className="absolute inset-0 pointer-events-none mix-blend-overlay animate-glow-pulse"
  style={{
    background: `
      radial-gradient(
        70% 60% at 50% 35%,
        rgba(0, 163, 224, 0.10) 0%,
        transparent 65%
      )
    `
  }}
/>

// CSS keyframe for subtle breathing
@keyframes glow-pulse {
  0%, 100% { opacity: 0.6; }
  50%      { opacity: 1.0; }
}
```

**Rules:**
- Position at top-center (50% 35%) for hero
- Accent color at 8–12% opacity
- mix-blend-overlay for natural blending
- animate-glow-pulse: 8s ease-in-out infinite (slow, barely perceptible)

### LAYER 3: Secondary Muted Glow

```tsx
// Offset from primary — creates color balance
<div
  className="absolute inset-0 pointer-events-none mix-blend-overlay"
  style={{
    background: `
      radial-gradient(
        60% 40% at 80% 20%,
        rgba(0, 212, 255, 0.06) 0%,
        transparent 60%
      )
    `
  }}
/>
```

**Rules:**
- Smaller than primary (40-60% size)
- Offset position (80% 20% or 20% 80%)
- Lower opacity than primary (4-6%)
- Different hue from primary for color depth

### LAYER 4: Dot Grid

```tsx
<div
  className="absolute inset-0 pointer-events-none"
  style={{
    backgroundImage: `
      radial-gradient(circle, rgba(255,255,255,0.06) 1px, transparent 1px)
    `,
    backgroundSize: '24px 24px',
    maskImage: `
      radial-gradient(ellipse 80% 80% at 50% 50%, #000 30%, transparent 100%)
    `,
    WebkitMaskImage: `
      radial-gradient(ellipse 80% 80% at 50% 50%, #000 30%, transparent 100%)
    `
  }}
/>
```

**Rules:**
- 1px dots, 24px grid spacing
- 4-8% white opacity (barely visible)
- Radial mask: visible center, faded edges
- Can animate: `animation: grid-drift 20s linear infinite` (translate by grid-size)

### LAYER 5: Grain Noise

```tsx
<div className="fixed inset-0 z-50 pointer-events-none opacity-[0.04] mix-blend-overlay">
  <svg className="w-full h-full">
    <filter id="grain">
      <feTurbulence
        type="fractalNoise"
        baseFrequency="0.65"
        numOctaves="3"
        stitchTiles="stitch"
      />
      <feColorMatrix type="saturate" values="0" />
    </filter>
    <rect width="100%" height="100%" filter="url(#grain)" />
  </svg>
</div>
```

**Rules:**
- Fixed position (covers entire viewport, doesn't scroll)
- opacity 0.04 — barely perceptible, but absence is felt
- z-50 — above content, below modals/overlays
- pointer-events-none — never blocks interaction
- SVG < 5KB — essentially free
- prefers-reduced-transparency: display:none

### LAYER 6: Section Vignette

```tsx
// Frames section content — draws eye to center
<div
  className="absolute inset-0 pointer-events-none"
  style={{
    background: `
      radial-gradient(
        ellipse 100% 80% at 50% 50%,
        transparent 40%,
        rgba(0, 0, 0, 0.3) 100%
      )
    `
  }}
/>
```

**Rules:**
- Applied per-section, NOT globally
- Transparent center → dark edges
- Subtle — should be felt, not consciously seen
- Only on sections with heavy content (hero, CTA)

### LAYER 7: Card-Local Glow

```tsx
// NOT a global blob — per-card, understated
<div className="absolute -inset-px rounded-3xl opacity-0 group-hover:opacity-100
                transition-opacity duration-500 pointer-events-none"
     style={{
       background: `
         radial-gradient(
           300px circle at var(--mouse-x, 50%) var(--mouse-y, 50%),
           rgba(0, 212, 255, 0.08),
           transparent 60%
         )
       `
     }}
/>
```

**Rules:**
- Per-card, NOT one global gradient
- Very low opacity (6-10%)
- Only visible on hover
- Follows cursor position (JS-tracked CSS variables, optional enhancement)
- Without JS: positioned at card center, opacity 0→1 on hover

## Putting It Together

```tsx
// Complete atmosphere for a hero section
<section className="relative min-h-screen overflow-hidden bg-[#050505]">
  {/* L2: Primary glow */}
  <div className="absolute inset-0 mix-blend-overlay animate-glow-pulse"
       style={{ background: 'radial-gradient(70% 60% at 50% 35%, rgba(0,163,224,0.10) 0%, transparent 65%)' }} />

  {/* L3: Secondary glow */}
  <div className="absolute inset-0 mix-blend-overlay"
       style={{ background: 'radial-gradient(60% 40% at 80% 20%, rgba(0,212,255,0.06) 0%, transparent 60%)' }} />

  {/* L4: Dot grid */}
  <div className="absolute inset-0"
       style={{
         backgroundImage: 'radial-gradient(circle, rgba(255,255,255,0.06) 1px, transparent 1px)',
         backgroundSize: '24px 24px',
         maskImage: 'radial-gradient(ellipse 80% 80% at 50% 50%, #000 30%, transparent 100%)'
       }} />

  {/* L6: Vignette */}
  <div className="absolute inset-0"
       style={{ background: 'radial-gradient(ellipse 100% 80% at 50% 50%, transparent 40%, rgba(0,0,0,0.3) 100%)' }} />

  {/* L1: Content (base bg is #050505 from body) */}
  <div className="relative z-10">
    {/* hero content */}
  </div>
</section>

{/* L5: Grain (in layout.tsx, global, fixed) */}
```

## Atmosphere Checklist

```
[ ] Page bg is #050505 (not #000)
[ ] Sections alternate #050505 / #080808
[ ] ≥1 RadialGlow in hero area (accent-colored, mix-blend-overlay)
[ ] ≥1 Secondary muted glow (offset, different hue)
[ ] DotGrid on ≥1 section (24px grid, mask-faded)
[ ] GrainOverlay global (SVG feTurbulence, opacity 0.04)
[ ] Section vignettes on content-heavy areas
[ ] Card-local glows (NOT global blobs)
[ ] Zero JavaScript for any atmosphere layer
[ ] prefers-reduced-transparency: grain hidden, glass → solid
[ ] All layers pointer-events-none, aria-hidden
```

## Anti-Patterns (FAIL)

```
❌ Single color background (#050505 with no layers)
❌ One global gradient as the only atmosphere
❌ bg-gradient-to-r from-X to-Y (AI template smell)
❌ Glass morphism without backdrop-filter fallback
❌ Noise > opacity 0.08 (becomes visible grain, looks dirty)
❌ Dot grid without mask (harsh edges, looks like a spreadsheet)
❌ Radial glow centered exactly (looks fake)
❌ All sections same background (no hierarchy)
```
