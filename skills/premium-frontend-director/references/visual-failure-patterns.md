# Visual Failure Patterns

> Catalog of every pattern that causes "generic AI SaaS" look. Each pattern has a FAIL tag and required fix.

---

## FAIL-01: Generic Gradient Background

### What It Looks Like
```tsx
<section className="bg-gradient-to-b from-slate-950 to-black">
<section className="bg-gradient-to-r from-blue-500 to-purple-600">
```

### Why It Fails
One gradient, one color transition. No depth layers. Instantly recognizable as template output. No atmosphere, no texture, no sense of physical space.

### Required Fix
```
Minimum 3 layers:
1. Base color (#050505)
2. Radial glow (brand-colored, mix-blend-overlay)
3. Dot grid or noise texture
```

---

## FAIL-02: transition-all hover

### What It Looks Like
```tsx
<button className="transition-all duration-300 hover:scale-105 hover:bg-white/10">
<div className="transition-all duration-200 hover:shadow-lg">
```

### Why It Fails
- `transition-all` animates every property including expensive ones (width, height, padding)
- `scale-105` is the #1 generic hover cliché
- No differentiation between properties
- Janky on low-end devices
- Feels cheap, not premium

### Required Fix
```tsx
// Premium hover: targeted properties, no scale
<button className="
  transition-[transform,border-color,box-shadow] duration-200 ease-editorial
  hover:translate-y-[-3px]
  hover:border-brand-accent/25
  hover:shadow-card-hover
">
```

---

## FAIL-03: Flat Single-Color Card

### What It Looks Like
```tsx
<div className="bg-gray-900 rounded-xl p-6">
<div className="bg-[#111] rounded-lg p-4">
```

### Why It Fails
No border system. No glass option. No hover elevation. Looks like a default dark mode from any CSS framework. No surface hierarchy.

### Required Fix
```tsx
// Premium card: border system + glass option + hover
<div className="
  bg-bg-card border border-border-subtle rounded-3xl p-6
  hover:border-brand-accent/25 hover:bg-bg-card-elevated
  hover:translate-y-[-2px] hover:shadow-card-hover
  transition-[transform,border-color,background-color,box-shadow] duration-200
">
```

---

## FAIL-04: Raw Opacity Fade

### What It Looks Like
```tsx
<motion.div
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  transition={{ duration: 0.5 }}
>
```

### Why It Fails
Default animation. No personality. Same as every other site. Doesn't create any visual interest. Does NOT use editorial easing. No stagger. No blur reveal.

### Required Fix Options

**Option A: Blur Reveal (for stats/metrics)**
```tsx
<motion.div
  initial={{ filter: "blur(10px)", opacity: 0 }}
  animate={{ filter: "blur(0px)", opacity: 1 }}
  transition={{ duration: 0.85, ease: [0.22, 1, 0.36, 1], delay: index * 0.18 }}
>
```

**Option B: Slide+Fade (for sections)**
```tsx
<motion.div
  initial={{ y: 32, opacity: 0 }}
  animate={{ y: 0, opacity: 1 }}
  transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
>
```

**Option C: Clip-Path (for connectors)**
```tsx
<div style={{
  clipPath: "inset(0 100% 0 0)",
  transition: "clip-path 1.4s cubic-bezier(0.22,1,0.36,1)"
}} />
```

---

## FAIL-05: No Background Texture

### What It Looks Like
```tsx
// Page has no grain, no dots, no glow, no vignette
<body className="bg-black">
```

### Why It Fails
Digital surfaces look synthetic without texture. Human eyes detect the absence of imperfection. Premium products always have micro-texture (grain on metal, texture on paper).

### Required Fix
```
At minimum:
1. GrainOverlay (SVG feTurbulence, opacity 0.04)
2. One RadialGlow (hero area)

Preferably also:
3. DotGrid (section backgrounds)
4. Section vignette (edge darkening)
```

---

## FAIL-06: Default Font Stack

### What It Looks Like
```tsx
// No custom fonts loaded
body { font-family: Inter, system-ui, sans-serif; }
// OR
// Only one font family, no editorial contrast
```

### Why It Fails
System fonts communicate "I didn't think about typography." No editorial personality. No serif contrast. Default Inter/System-ui is the most generic possible choice.

### Required Fix
```
Minimum 2-font stack:
1. Primary sans: Geist Sans (excellent TR support)
2. Editorial serif: Playfair Display (via [&_em]:font-serif)

[&_em] pattern: Every <em> becomes serif italic automatically.
Content: "Gebze'de <em>fiber</em> artık ulaşılabilir"
```

---

## FAIL-07: Centered Everything

### What It Looks Like
```tsx
<section className="text-center flex flex-col items-center">
  <h1>Hero Title</h1>
  <p>Description text centered</p>
  <button>CTA Button</button>
</section>
```

### Why It Fails
Every section centered is the default AI pattern. No editorial layout variation. No asymmetry. No grid-breaking. Looks like a middle-school PowerPoint.

### Required Fix
```
Vary layouts:
- Hero: centered (acceptable here — it's the hero)
- Trust metrics: horizontal spread
- Services: bento or grid with varying card sizes
- Process: left-aligned timeline
- Gallery: masonry or uneven grid
- FAQ: left-aligned, wide
- CTA: centered panel (acceptable — final section)

Never: every section centered with same spacing.
```

---

## FAIL-08: Uniform Spacing

### What It Looks Like
```tsx
<section className="py-16">  // Every section
<section className="py-16">  // Every section
<section className="py-20">  // Every section
// All use the same padding, same gap, same rhythm
```

### Why It Fails
Uniform spacing reads as "I used a loop." No editorial rhythm. No breathing room variation. Sections should have different spatial weights based on content density.

### Required Fix
```
Section spacing should vary:
- Hero: min-h-screen (fills viewport)
- Trust metrics: py-16 (compact, quick stats)
- Services: py-section (var(--spacing-section-y), generous)
- Process: py-section (same as services — paired)
- Why Us: py-section (benefits grid)
- Gallery: py-section (visual — more space)
- FAQ: py-20 (reading-heavy — generous)
- Service area: py-section (compact)
- Final CTA: py-24 (big finale)
```

---

## FAIL-09: Missing State Feedback

### What It Looks Like
```tsx
<button>Submit</button>
// No loading, no success, no error, no disabled state
```

### Why It Fails
Product feels broken or fake. Real products have states. Missing states feel like a demo, not a real service.

### Required Fix
```
Every interactive element needs:
- Default state (visible, styled)
- Hover state (premium micro-interaction)
- Focus state (ring-2 cyan, visible on keyboard nav)
- Active/pressed state (subtle scale feedback)
- Disabled state (opacity-50, cursor-not-allowed)
- Loading state (if async action)
- Success state (if form/interaction)
- Error state (if validation)
```

---

## FAIL-10: Wrong Mobile Breakpoint

### What It Looks Like
```tsx
// Using 768px (Tailwind default md)
<div className="md:flex-row">
<div className="max-md:hidden">
```

### Why It Fails
768px is the default. giydiriyo uses 620px. More aggressive mobile breakpoint = more intentional design decision. 768px leaves a wide tablet zone that often looks awkward.

### Required Fix
```
Breakpoints:
- max-[420px]: Small mobile (Galaxy S, iPhone SE)
- max-[620px]: Mobile (MobileCTABar visible, grid stack)
- max-[860px]: Tablet (Navbar Sheet menu)
- 1024px+: Desktop
- 1440px+: Wide (Container max-w-7xl)
```

---

## FAIL-11: No Glass Morphism

### What It Looks Like
```tsx
// All surfaces are solid colors
<div className="bg-[#0A0A0A] rounded-3xl">
```

### Why It Fails
Solid surfaces feel flat. Glass morphism (backdrop-blur + translucent bg) creates depth by revealing background layers through the surface. It's the easiest way to add perceived depth without complex CSS.

### Required Fix
```tsx
// Glass surface
<div className="
  bg-[rgba(10,10,10,0.7)] backdrop-blur-[20px]
  border border-[rgba(255,255,255,0.08)] rounded-3xl
">

// With solid fallback
@supports not (backdrop-filter: blur(20px)) {
  .glass-surface { background: #0A0A0A; backdrop-filter: none; }
}
```

---

## FAIL-12: No Gradient Text in Hero

### What It Looks Like
```tsx
<h1 className="text-white font-bold text-5xl">Title</h1>
```

### Why It Fails
Flat white text at large scale is visually boring. Gradient text (especially top-to-bottom white→transparent gradient) creates dimension on the hero heading without any layout changes.

### Required Fix
```css
.text-gradient-hero {
  background: linear-gradient(
    180deg,
    rgba(255,255,255,0.92) 0%,
    rgba(255,255,255,0.58) 50%,
    rgba(255,255,255,0.08) 100%
  );
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}
```

---

## Quick Reference: Find → Classify → Fix

| Pattern | grep/scan for | FAIL Tag | Fix |
|---------|--------------|----------|-----|
| Generic gradient bg | `bg-gradient-to` | FLAT_BACKGROUND | Add 3+ depth layers |
| transition-all hover | `transition-all` | CHEAP_HOVER | Targeted transitions |
| scale-105 hover | `scale-105` | CHEAP_HOVER | translate-y instead |
| Flat card | `bg-gray-900\|bg-\[#111\]` | FLAT_SURFACE | Border system + glass |
| Raw opacity fade | `initial=\{.*opacity: 0` | RAW_MOTION | Blur/slide/clip reveal |
| No texture | No `feTurbulence\|DotGrid\|RadialGlow` | MISSING_ATMOSPHERE | Add grain+glow |
| System font | No `next/font\|font-family` | BAD_TYPOGRAPHY | 2-font editorial stack |
| Centered everything | `text-center` in every section | WEAK_NARRATIVE | Vary layouts |
| Uniform spacing | Same `py-\d+` everywhere | GENERIC_TEMPLATE | Variable section spacing |
| Missing states | No `hover:\|focus:\|disabled:` | NO_STATE_FEEDBACK | Complete state set |
| 768px break | `md:\|max-md:` everywhere | GENERIC_TEMPLATE | 620px breakpoint |
| No glass | No `backdrop-blur` | FLAT_SURFACE | Glass surfaces |
| Flat hero text | `text-white` in hero H1 | BAD_TYPOGRAPHY | Gradient text |
