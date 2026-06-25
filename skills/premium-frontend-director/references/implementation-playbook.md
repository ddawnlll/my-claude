# Implementation Playbook

> Step-by-step implementation order for premium dark editorial SaaS frontend.

---

## Implementation Order (CRITICAL)

This order is non-negotiable. Building out of order creates rework.

### Phase 0: Foundation (DO FIRST)
```
1. Design tokens in globals.css
   - All --color-*, --text-*, --spacing-*, --radii-*, --shadow-*, --motion-*
   - @layer base { em { font-family: var(--font-playfair); font-style: italic; } }
   - @media (prefers-reduced-motion) global override

2. Tailwind config theme extension
   - colors → var(--color-*) references
   - fontFamily → CSS variable references
   - fontSize → clamp() scale
   - borderRadius → 2xl, 3xl
   - boxShadow → card, card-hover, glow-cyan, glow-accent
   - transitionTimingFunction → editorial, spring
   - keyframes → grid-drift, glow-pulse, beam-travel

3. Font loading in layout.tsx
   - next/font/google for all 3 fonts
   - latin-ext subset
   - CSS variable output

4. cn() utility (clsx + tailwind-merge)
```

### Phase 1: Atmosphere (BUILD DEPTH FIRST)
```
5. GrainOverlay component
   - SVG feTurbulence, fixed, z-50, pointer-events-none
   - opacity 0.04, mix-blend-overlay
   - prefers-reduced-transparency: hidden

6. DotGrid component
   - CSS radial-gradient pattern
   - 24px grid, mask-faded to edges
   - Configurable dot color and mask radius

7. RadialGlow component
   - Stacked radial gradients + mix-blend-overlay
   - Configurable color, position, size
   - animate-glow-pulse
```

### Phase 2: UI Primitives (BUILD SURFACES)
```
8. Button component
   - 4 variants: primary/secondary/ghost/whatsapp
   - 3 sizes: sm/md/lg
   - Radix Slot (polymorphic)
   - forwardRef
   - Complete state set: hover/focus/active/disabled

9. Card component
   - 3 variants: default/glass/interactive
   - Border opacity system
   - Glass with backdrop-blur + solid fallback
   - Interactive hover state

10. Badge component
    - accent-soft bg, accent text
    - rounded-full, inline-flex

11. SectionHeading component
    - Eyebrow (accent, uppercase, tracking)
    - Title (H2, accepts dangerouslySetInnerHTML for <em>)
    - Description (body-lg, muted)

12. Container component
    - max-w-7xl, responsive px
```

### Phase 3: Layout Shell (BUILD STRUCTURE)
```
13. Sheet component (shadcn manual copy)
    - Slide from right
    - Overlay bg-[#050505]/95 backdrop-blur
    - ESC to close
    - Focus trap basics

14. Navbar component
    - Fixed, transparent→blur on scroll
    - Desktop: logo + links + CTA
    - Mobile (860px): hamburger → Sheet
    - Anchor link smooth scroll

15. Footer component
    - 4-column grid → stack at 620px
    - Brand, links, contact, region

16. MobileCTABar component
    - Fixed bottom, ≤620px only
    - 3 buttons: WhatsApp, Call, Directions
```

### Phase 4: Section Components (BUILD CONTENT)
```
17. Hero section
    - Atmosphere layers first (RadialGlow, DotGrid)
    - StaggerText H1 (word-by-word, .06s stagger)
    - Glass CTA card (delayed reveal)
    - 2 CTAs: WhatsApp primary, Services secondary

18. TrustStrip section
    - BlurReveal tiles (.85s, .18s stagger)
    - 3 metrics from trust-metrics data
    - Gradient cyan value text

19. Services section
    - Card grid (2-3 cols → 1 at 620px)
    - BorderBeam on hover
    - icon + h3 + description per card

20. Process section
    - Numbered glass cards
    - Vertical connector line (gradient)
    - .18s stagger per step

21. WhyUs section
    - 6 benefits grid + DotGrid background
    - Static cards (server component)

22. Gallery section
    - Photo grid + Radix Dialog lightbox
    - Prev/next navigation
    - Hover caption reveal

23. FAQ section
    - CSS grid-template-rows accordion
    - + icon rotation on open
    - Zero JS for animation (only state tracking)

24. ServiceArea section
    - 4 location cards
    - Static (server component)

25. FinalCTA section
    - DotGrid panel with radial mask
    - Glass-like container
    - Large WhatsApp + secondary phone CTA
```

### Phase 5: Page Composition
```
26. page.tsx
    - Import and render all 9 sections in order
    - Server component (default)
    - Section IDs for anchor navigation

27. layout.tsx
    - Font variables on <html>
    - GrainOverlay (fixed, z-50)
    - Navbar → <main>{children}</main> → Footer → MobileCTABar
    - Metadata: title, description, OG, Twitter
    - LocalBusiness JSON-LD
    - Preconnect Google Fonts
```

### Phase 6: SEO & Performance
```
28. sitemap.ts → /sitemap.xml
29. robots.ts → /robots.txt
30. opengraph-image.tsx → OG image generation
31. Metadata final review (all Turkish, all accurate)
32. Bundle check (<150KB JS, <30KB CSS)
33. Lazy-load verification (Framer Motion next/dynamic)
```

### Phase 7: Polish & Audit
```
34. Visual audit against premium-frontend-checklist.md
35. Accessibility audit (keyboard nav, screen reader, contrast)
36. Cross-browser fallback verification
37. Responsive test (320, 375, 620, 860, 1024, 1440)
38. Lighthouse run (target: ≥90 all categories)
39. axe-core run (target: 0 violations)
```

---

## Component Implementation Templates

### Hover State Template

```tsx
// PREMIUM HOVER (use this pattern everywhere)
className={cn(
  // Base
  "border border-border-subtle rounded-3xl",
  "bg-bg-card",
  // Hover — targeted properties, no scale, no transition-all
  "hover:border-brand-accent/25",
  "hover:bg-bg-card-elevated",
  "hover:translate-y-[-3px]",
  "hover:shadow-card-hover",
  // Transition — specific properties
  "transition-[transform,border-color,background-color,box-shadow]",
  "duration-200",
  "ease-editorial"
)}
```

### Glass Surface Template

```tsx
// GLASS (use for overlay cards, CTA panels, process cards)
<div className="
  bg-[rgba(10,10,10,0.7)]
  backdrop-blur-[20px]
  border border-[rgba(255,255,255,0.08)]
  rounded-3xl
  p-6 md:p-8
">
  {/* content */}
</div>

// CSS fallback (in globals.css)
@supports not (backdrop-filter: blur(20px)) {
  .glass-surface {
    background: #0A0A0A;
    backdrop-filter: none;
  }
}
```

### Card Grid Template

```tsx
// SERVICE/PRODUCT CARD GRID
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
  {items.map((item, idx) => (
    <RevealSection key={item.id} delay={idx * 0.18}>
      <Card variant="interactive" className="relative group overflow-hidden">
        {/* Border beam — visible on hover */}
        <BorderBeam className="opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
        
        {/* Card content */}
        <div className="text-3xl mb-4">{item.icon}</div>
        <h3 className="text-lg font-semibold mb-2">{item.title}</h3>
        <p className="text-sm text-text-secondary">{item.description}</p>
      </Card>
    </RevealSection>
  ))}
</div>
```

### Section Template

```tsx
// STANDARD SECTION
<section id="section-id" className="py-section bg-bg-base relative overflow-hidden">
  {/* Optional atmosphere */}
  <DotGrid className="opacity-60" />
  
  <Container className="relative z-10">
    <RevealSection>
      <SectionHeading
        eyebrow="Eyebrow Text"
        title="Başlıkta <em>Vurgulu</em> Kelime"
        description="Açıklama metni buraya. İki cümle ideal."
      />
    </RevealSection>
    
    {/* Section content */}
    <div className="mt-12 md:mt-16">
      {/* ... */}
    </div>
  </Container>
</section>
```

### Motion Reveal Template

```tsx
// SCROLL REVEAL (use this for every section entrance)
<RevealSection delay={idx * 0.18} direction="up">
  <div>content</div>
</RevealSection>

// BLUR REVEAL (use for metrics/stats only)
<BlurReveal delay={idx * 0.18}>
  <div>stat value</div>
</BlurReveal>

// STAGGER TEXT (use for hero H1 only)
<StaggerText
  text="Gebze'de <em>fiber</em> artık ulaşılabilir"
  className="text-hero font-bold text-gradient-hero"
  as="h1"
/>
```

---

## Common Mistakes to Avoid

### ❌ Building cards before background
You can't get card hover states right without knowing the background. Atmosphere first.

### ❌ Adding animations before layout is solid
Animation should enhance a good layout, not compensate for a bad one. Layout first.

### ❌ Using transition-all anywhere
This is the #1 signal of AI-generated frontend. Never use it.

### ❌ scale-105 on hover
This is the #2 signal. Use translate-y instead. Scale causes sub-pixel rendering issues.

### ❌ Same animation on every element
"One cinematic moment per section" means MOST things are static. Only ONE thing provides motion interest per scroll zone.

### ❌ Adding GSAP before CSS animation is exhausted
CSS offset-path, clip-path, grid-template-rows, and @keyframes handle 90% of premium animation. Add GSAP only for scroll-triggered timelines that CSS truly can't handle.

### ❌ Writing mobile styles as overrides
Design mobile-first. 620px is the primary breakpoint, not 768px.

### ❌ Missing glass fallbacks
Firefox and older Safari don't support backdrop-filter. Always include `@supports not` fallback.

---

## Quick Start: Audit Current State

```bash
# 1. Count depth layers
grep -r "radial-gradient\|DotGrid\|GrainOverlay\|RadialGlow" src/

# 2. Find forbidden patterns
grep -r "transition-all" src/
grep -r "scale-105" src/
grep -r "scale-\[1\.0" src/

# 3. Check motion quality
grep -r "initial={{ opacity: 0 }}" src/
grep -r "ease: \[0\.22" src/

# 4. Verify typography
grep -r "<em>" src/
grep -r "font-playfair" src/

# 5. Check responsive
grep -r "620px\|max-\[620px\]" src/

# 6. Count section cinematic moments
# (Each section should have exactly 1 Framer Motion import/usage)

# 7. Bundle size
npm run build 2>&1 | grep "First Load JS"
```
