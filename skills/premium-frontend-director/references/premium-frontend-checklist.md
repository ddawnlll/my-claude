# Premium Frontend Checklist

> Detailed PASS/FAIL audit by component category. Every item must be checked before claiming completion.

---

## 1. GLOBAL ATMOSPHERE

### Layer Audit
```
[ ] Background base color is #050505 (true black, not #000)
[ ] Section alternate bg is #080808 (subtle differentiation)
[ ] ≥1 RadialGlow present (hero area, accent-colored)
[ ] GrainOverlay active (SVG feTurbulence, opacity 0.04, mix-blend-overlay)
[ ] DotGrid present on ≥1 section (24px grid, mask-faded)
[ ] prefers-reduced-transparency: grain hidden, glass → solid
```

### CSS Custom Properties
```
[ ] --color-bg-base through --color-bg-glass defined in :root
[ ] --color-brand-primary (#00A3E0), --color-brand-accent (#00D4FF)
[ ] --color-text-primary (#EDEDED), secondary (#A0A0A0), muted (#6B6B6B)
[ ] --color-text-on-brand (#050505) — AA/AAA contrast verified
[ ] --color-border-subtle (6%), default (10%), strong (18%)
[ ] --motion-easing-editorial: cubic-bezier(0.22, 1, 0.36, 1)
[ ] --spacing-section-y: clamp(4rem, 8vw, 8rem)
[ ] --radii-2xl (18px), --radii-3xl (22px)
```

### Reduced Motion
```
[ ] @media (prefers-reduced-motion: reduce): animation-duration: 0.01ms !important
[ ] transition-duration: 0.01ms !important
[ ] scroll-behavior: auto !important
[ ] Framer Motion: MotionConfig reducedMotion="user"
```

---

## 2. TYPOGRAPHY

### Font Loading
```
[ ] Geist Sans loaded via next/font/google, subsets: ['latin-ext']
[ ] Playfair Display loaded via next/font/google, subsets: ['latin-ext']
[ ] Geist Mono loaded via next/font/google, subsets: ['latin-ext']
[ ] CSS variables: --font-geist-sans, --font-playfair, --font-geist-mono
[ ] font-display: swap on all
[ ] Preconnect to fonts.googleapis.com and fonts.gstatic.com
```

### [&_em]:font-serif Pattern
```
[ ] @layer base { em { font-family: var(--font-playfair); font-style: italic; } }
[ ] At least one <em> in heading text (hero H1)
[ ] At least one <em> in body text
[ ] Turkish characters render correctly in serif (ğşiçöüĞŞİÇÖÜ)
```

### Heading Hierarchy
```
[ ] Hero: text-hero (clamp 2.5rem-5rem), line-height 0.95, weight 700
[ ] H2: text-h2 (clamp 1.75rem-2.5rem), line-height 1.1, weight 600
[ ] H3: text-h3 (clamp 1.25rem-1.75rem), line-height 1.15, weight 600
[ ] Gradient text on hero H1 (bg-clip-text, text-transparent)
[ ] Eyebrow: 0.75rem, uppercase, 0.1em tracking, accent color
```

### Body & Caption
```
[ ] Body LG: 1.125rem, line-height 1.65 (descriptions, lead paragraphs)
[ ] Body: 1rem, line-height 1.6 (general content)
[ ] Caption: 0.75rem, line-height 1.5 (footer, meta)
[ ] All Turkish, no English content
```

---

## 3. COLOR SYSTEM

### Contrast Verification
```
[ ] Text primary (#EDEDED) on bg-base (#050505): ≥ 12:1 AAA ✓
[ ] Text secondary (#A0A0A0) on bg-base: ≥ 7:1 AAA ✓
[ ] Text muted (#6B6B6B) on bg-base: ≥ 4.5:1 AA ✓
[ ] Text on-brand (#050505) on brand-primary (#00A3E0): ≥ 10.5:1 AAA ✓
[ ] Text on-brand (#050505) on whatsapp (#25D366): ≥ 8.4:1 AA ✓
```

### Color Usage
```
[ ] Brand primary (#00A3E0): buttons, links, active states ONLY
[ ] Brand accent (#00D4FF): glow, focus rings, BorderBeam ONLY
[ ] WhatsApp green (#25D366): WhatsApp CTAs ONLY (not decorative)
[ ] No hardcoded colors outside CSS variables
[ ] No tailwind.config hardcoded hex values (must use var(...) references)
```

---

## 4. SURFACE SYSTEM

### Buttons
```
[ ] 4 variants: primary, secondary, ghost, whatsapp
[ ] 3 sizes: sm, md, lg
[ ] Radix Slot for polymorphic (asChild)
[ ] forwardRef
[ ] Hover: brightness-110 + translate-y-[-1px] (NOT scale-105)
[ ] Active: scale-[0.98]
[ ] Focus: ring-2 ring-[#00D4FF] ring-offset-2 ring-offset-[#050505]
[ ] Disabled: opacity-50 cursor-not-allowed
[ ] Primary/whatsapp: text-on-brand for WCAG AA/AAA
```

### Cards
```
[ ] 3 variants: default, glass, interactive
[ ] Border system: border-subtle (6%) → border-accent/25 (25% on hover)
[ ] Glass: backdrop-blur-[20px], border rgba(255,255,255,0.08)
[ ] Interactive: hover bg-card-elevated + translate-y-[-2px]
[ ] Rounded-3xl (22px) — matches giydiriyo premium radius
[ ] Glass fallback: @supports not (backdrop-filter) → solid #0A0A0A
```

### Badges
```
[ ] bg-brand-accent-soft (rgba(0,212,255,0.12))
[ ] text-brand-accent
[ ] border border-brand-accent/15
[ ] rounded-full, inline-flex
```

---

## 5. LAYOUT SHELL

### Navbar
```
[ ] Fixed position, z-[90]
[ ] Transparent → bg-[#050505]/90 backdrop-blur-md on scroll
[ ] Border-b on scrolled state
[ ] Desktop: logo + nav links + WhatsApp CTA
[ ] Mobile (≤860px): hamburger → Sheet slide from right
[ ] Sheet: overlay bg-[#050505]/95, menu items, WhatsApp CTA
```

### Footer
```
[ ] 4-column grid → stack at 620px
[ ] Brand col: logo + description
[ ] Links col: anchor navigation
[ ] Contact col: phone, WhatsApp, email
[ ] Region col: Gebze, Darıca, Çayırova, Kocaeli
[ ] Copyright + address bottom bar
```

### MobileCTABar
```
[ ] Fixed bottom, z-[80]
[ ] Visible ONLY ≤620px (md:hidden)
[ ] bg-[#050505]/95 backdrop-blur-md
[ ] 3 buttons: WhatsApp, Ara, Yol Tarifi
[ ] Icons 22px, labels 12px
```

---

## 6. SECTION COMPONENTS

### Hero
```
[ ] min-h-screen, flex flex-col justify-center
[ ] RadialGlow: cyan, positioned at top-center
[ ] DotGrid: subtle, background layer
[ ] H1: gradient text (white→transparent), text-hero
[ ] StaggerText: word-by-word, 0.06s stagger
[ ] Glass card: CTA container, backdrop-blur
[ ] 2 CTAs: WhatsApp (primary) + Hizmetler (secondary)
[ ] <em> on key word: "Gebze'de <em>fiber</em> artık ulaşılabilir"
```

### TrustStrip
```
[ ] 3 metrics: 10+ Yıl, 500+ Müşteri, 1000+ km
[ ] BlurReveal: blur(10px)→0, .85s editorial
[ ] .18s stagger between tiles
[ ] Gradient cyan value text
[ ] Mobile: vertical stack
```

### Services
```
[ ] Grid: 2-3 columns → 1 at 620px
[ ] Card interactive: hover border accent + elevation
[ ] BorderBeam: CSS offset-path, cyan gradient, 2.2s
[ ] Each card: icon + h3 + description
[ ] prefers-reduced-motion: beam static opacity .35
```

### Process
```
[ ] 4 steps: 01-04 numbered
[ ] Glass cards (glass-surface), rounded-[18px]
[ ] Connector line: vertical gradient line
[ ] Stagger: .18s per step
[ ] Each step: number badge + icon + title + description
```

### WhyUs
```
[ ] 6 benefits grid
[ ] DotGrid background layer
[ ] Cards with icon + title + description
[ ] SectionHeading: "Neden Biz" eyebrow
```

### Gallery
```
[ ] Photo grid: 2-3 columns
[ ] Radix Dialog lightbox
[ ] Overlay: bg-[#050505]/95 backdrop-blur-md
[ ] Navigation: prev/next arrows + close button
[ ] Hover: caption reveal + overlay tint
```

### FAQ
```
[ ] CSS grid-template-rows accordion
[ ] Closed: 0fr, Open: 1fr
[ ] Transition: .3s ease
[ ] + icon rotates 45° on open
[ ] Border-b between items
```

### ServiceArea
```
[ ] 4 location cards: Gebze, Darıca, Çayırova, Kocaeli
[ ] Each: location name + neighborhoods
[ ] Card border system
```

### FinalCTA
```
[ ] DotGrid panel: rounded-[22px]
[ ] Radial mask: fade dots at edges
[ ] Glass-like container
[ ] Large WhatsApp button
[ ] Secondary phone CTA
```

---

## 7. MOTION QUALITY

### Per-Section Motion
```
[ ] Hero: StaggerText (word stagger) → CTA reveal (delayed)
[ ] TrustStrip: BlurReveal (filter blur→clear, .85s, .18s stagger)
[ ] Services: RevealSection (slide up, .6s) + BorderBeam (hover)
[ ] Process: RevealSection (slide up, .4s, .18s stagger)
[ ] WhyUs: RevealSection (slide up, .6s)
[ ] Gallery: RevealSection (slide up, .6s)
[ ] FAQ: CSS grid accordion (zero JS)
[ ] ServiceArea: Static (server component)
[ ] FinalCTA: Static panel
```

### Easing
```
[ ] All Framer Motion: cubic-bezier(0.22, 1, 0.36, 1)
[ ] All CSS transitions: ease-editorial
[ ] No default easing (cubic-bezier(0.4, 0, 0.2, 1)) on reveals
```

### Stagger
```
[ ] .18s between items (giydiriyo standard)
[ ] .06s between words (hero text)
[ ] Stagger delay increases per index: idx * 0.18
```

### Keyframes (CSS)
```
[ ] grid-drift: 20s linear infinite (dot grid movement)
[ ] glow-pulse: 8s ease-in-out infinite (radial glow breathing)
[ ] beam-travel: 2.2s linear infinite (border beam rotation)
```

---

## 8. RESPONSIVE QUALITY

### 620px Break (Mobile)
```
[ ] MobileCTABar visible
[ ] Section heading scales down
[ ] Grids go single column
[ ] Cards full width
[ ] Footer stacks vertically
[ ] No horizontal scroll (critical!)
[ ] Touch targets ≥44px
```

### 860px Break (Tablet)
```
[ ] Navbar switches to hamburger + Sheet
[ ] Nav links hidden, Sheet menu activated
```

### 1024px+ (Desktop)
```
[ ] Full multi-column grids
[ ] Nav links visible inline
[ ] Desktop CTA visible in navbar
```

### 1440px+ (Wide)
```
[ ] Container max-w-7xl (80rem)
[ ] Content centered, not stretched
```

---

## 9. ACCESSIBILITY

### Keyboard Navigation
```
[ ] Tab order logical (left→right, top→bottom)
[ ] Focus ring visible: ring-2 ring-[#00D4FF]
[ ] Skip-to-content available (optional, single-page)
[ ] Escape closes Sheet/Dialog
```

### Screen Readers
```
[ ] All images have alt text (Turkish)
[ ] Dialog has aria-modal="true"
[ ] Sheet has role="dialog" aria-modal="true"
[ ] FAQ buttons have aria-expanded
[ ] Nav has aria-label="Main navigation"
```

### Contrast
```
[ ] All text passes WCAG AA (≥4.5:1)
[ ] Large text passes WCAG AA (≥3:1)
[ ] Interactive elements have visible focus indicators
```

### Motion
```
[ ] prefers-reduced-motion: all disabled
[ ] prefers-reduced-transparency: glass → solid, grain hidden
```

---

## 10. PERFORMANCE

### Bundle
```
[ ] First Load JS < 150KB (gzipped)
[ ] CSS < 30KB (gzipped)
[ ] Framer Motion: next/dynamic lazy-loaded (ssr:false)
[ ] No unused JavaScript on static pages
```

### Images
```
[ ] next/image used (not <img>)
[ ] width/height specified
[ ] Hero image: loading="eager" fetchpriority="high"
[ ] Below-fold images: loading="lazy"
[ ] AVIF/WebP format preference
```

### Fonts
```
[ ] next/font, not Google Fonts <link>
[ ] Subset to latin-ext
[ ] font-display: swap
[ ] Preconnect to Google Fonts CDN
```

---

## 11. SEO

```
[ ] metadata: title (TR), description (TR)
[ ] openGraph: title, description, image, locale
[ ] twitter: card summary_large_image
[ ] robots: index, follow
[ ] geo.region: TR-41, geo.placename: Gebze/Kocaeli
[ ] LocalBusiness JSON-LD schema
[ ] sitemap.ts → /sitemap.xml
[ ] robots.ts → /robots.txt
[ ] opengraph-image.tsx → OG image generation
[ ] canonical URL
```

---

## 12. CROSS-BROWSER

```
[ ] Chrome: all features work (primary target)
[ ] Firefox: backdrop-filter verified
[ ] Safari: offset-path verified, static fallback if missing
[ ] Edge: full parity with Chrome expected
[ ] @supports fallback for backdrop-filter
[ ] @supports fallback for offset-path
```

---

## FINAL GATE

Before marking ANY frontend task complete:

```
[ ] Site does NOT look like a Tailwind template
[ ] Site does NOT look like shadcn default
[ ] Site does NOT look like an AI generated it
[ ] Visual hierarchy is intentional and clear
[ ] Typography has personality (serif emphasis visible)
[ ] Background has depth (multiple layers perceptible)
[ ] Hover states feel premium (not transition-all scale)
[ ] Motion has purpose (not random fade spam)
[ ] Mobile at 620px feels native, not desktop-shrunk
```

**Only PASS if ALL items checked. Otherwise FAIL — fix and re-audit.**
