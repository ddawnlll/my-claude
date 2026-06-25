# Kayrae Component Recipes

> Copyable templates for premium dark editorial components. Adapt colors, typography, and content to your brand.

---

## Hero Recipe

```tsx
export function Hero() {
  return (
    <section className="relative min-h-screen flex flex-col justify-center overflow-hidden bg-[#050505]">
      {/* L2: Primary glow */}
      <div className="absolute inset-0 mix-blend-overlay animate-glow-pulse"
        style={{ background: 'radial-gradient(70% 60% at 50% 35%, rgba(ACCENT_R,ACCENT_G,ACCENT_B,0.10) 0%, transparent 65%)' }} />

      {/* L3: Secondary glow */}
      <div className="absolute inset-0 mix-blend-overlay"
        style={{ background: 'radial-gradient(60% 40% at 80% 20%, rgba(ACCENT_R,ACCENT_G,ACCENT_B,0.06) 0%, transparent 60%)' }} />

      {/* L4: Dot grid */}
      <DotGrid dotColor="rgba(255,255,255,0.06)" />

      <Container className="relative z-10 py-32 md:py-40">
        <div className="flex flex-col items-center text-center max-w-5xl mx-auto">

          {/* PRIMARY MOMENT: Headline stagger */}
          <StaggerText
            text="Şehirde <em>ürünün</em> artık ulaşılabilir"
            className="text-hero font-bold text-gradient-hero"
            as="h1"
          />

          {/* Static subcopy */}
          <p className="mt-6 md:mt-8 text-body-lg text-text-secondary max-w-2xl">
            X+ yıllık tecrübemizle <em>anahtar kelime</em> hizmeti.
          </p>

          {/* SECONDARY MOMENT: CTA card (delayed reveal) */}
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.8, ease: [0.22, 1, 0.36, 1] }}
            className="mt-10 md:mt-12 w-full max-w-xl"
          >
            <div className="glass-surface rounded-3xl p-6 md:p-10">
              <p className="text-sm text-text-secondary text-center mb-6">
                <em>Ücretsiz</em> keşif için hemen iletişime geçin
              </p>
              <div className="flex flex-col sm:flex-row gap-3 justify-center">
                <Button variant="primary" size="lg">Primary CTA</Button>
                <Button variant="secondary" size="lg">Secondary CTA</Button>
              </div>
            </div>
          </motion.div>
        </div>
      </Container>
    </section>
  );
}
```

---

## Trust Metrics Recipe

```tsx
export function TrustStrip() {
  return (
    <section className="py-16 md:py-20 border-y border-border-subtle bg-bg-section">
      <Container>
        <div className="grid grid-cols-3 gap-8 max-[620px]:grid-cols-1 max-[620px]:gap-6">
          {metrics.map((metric, idx) => (
            <BlurReveal key={metric.label} delay={idx * 0.18}>
              <div className="flex flex-col items-center text-center p-4">
                <span className="text-h2 font-bold text-gradient-cyan">
                  {metric.value}
                </span>
                <span className="mt-1 text-sm text-text-secondary">
                  {metric.label}
                </span>
                {metric.suffix && (
                  <span className="text-xs text-text-muted mt-0.5">
                    {metric.suffix}
                  </span>
                )}
              </div>
            </BlurReveal>
          ))}
        </div>
      </Container>
    </section>
  );
}
```

---

## Service Card Grid Recipe

```tsx
export function Services() {
  return (
    <section id="hizmetler" className="py-section bg-bg-base relative overflow-hidden">
      <DotGrid className="opacity-50" />

      <Container className="relative z-10">
        <RevealSection>
          <SectionHeading
            eyebrow="Hizmetlerimiz"
            title="Başlıkta <em>Vurgulu</em> Kelime"
            description="İki cümlelik açıklama. İlk cümle ana fayda. İkinci cümle detay."
          />
        </RevealSection>

        <div className="mt-12 md:mt-16 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
          {services.map((service, idx) => (
            <RevealSection key={service.id} delay={idx * 0.18}>
              <Card variant="interactive" className="relative group overflow-hidden h-full">
                {/* Card-local glow — hover only */}
                <div className="absolute inset-0 rounded-3xl opacity-0 group-hover:opacity-100
                              transition-opacity duration-500 pointer-events-none"
                  style={{ background: 'radial-gradient(400px circle at center, rgba(ACCENT_R,ACCENT_G,ACCENT_B,0.08), transparent 60%)' }} />

                {/* Border beam — hover only */}
                <BorderBeam className="opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                {/* Content */}
                <div className="relative z-10">
                  <span className="text-3xl mb-4 block
                                transition-transform duration-200 ease-editorial
                                group-hover:translate-y-[-2px]">
                    {service.icon}
                  </span>
                  <h3 className="text-lg font-semibold text-text-primary mb-2">
                    {service.title}
                  </h3>
                  <p className="text-sm text-text-secondary leading-relaxed">
                    {service.description}
                  </p>
                </div>
              </Card>
            </RevealSection>
          ))}
        </div>
      </Container>
    </section>
  );
}
```

---

## Process Steps Recipe

```tsx
export function Process() {
  return (
    <section className="py-section bg-bg-section">
      <Container>
        <RevealSection>
          <SectionHeading
            eyebrow="Süreç"
            title="Nasıl <em>Çalışıyoruz?</em>"
            description="İlk temastan teslimata kadar şeffaf ve hızlı bir süreç."
          />
        </RevealSection>

        <div className="mt-12 md:mt-16 max-w-3xl mx-auto relative">
          {/* Connector line */}
          <div className="absolute left-[27px] top-0 bottom-0 w-px md:left-[35px]"
            style={{
              background: 'linear-gradient(180deg, var(--color-brand-accent) 0%, transparent 100%)',
              opacity: 0.15
            }} />

          <div className="flex flex-col gap-8 md:gap-10">
            {steps.map((step, idx) => (
              <RevealSection key={step.step} delay={idx * 0.18}>
                <div className="relative flex gap-5 md:gap-8">
                  {/* Step number — glass badge */}
                  <div className="relative z-10 flex-shrink-0 w-14 h-14 md:w-[70px] md:h-[70px]
                                rounded-2xl glass-surface flex items-center justify-center">
                    <span className="text-lg md:text-xl font-bold text-brand-accent font-mono">
                      {step.step}
                    </span>
                  </div>

                  {/* Content — glass card */}
                  <div className="flex-1 glass-surface rounded-2xl md:rounded-[18px] p-5 md:p-6">
                    <div className="flex items-center gap-3 mb-2">
                      <span className="text-xl">{step.icon}</span>
                      <h3 className="text-base md:text-lg font-semibold text-text-primary">
                        {step.title}
                      </h3>
                    </div>
                    <p className="text-sm text-text-secondary leading-relaxed">
                      {step.description}
                    </p>
                  </div>
                </div>
              </RevealSection>
            ))}
          </div>
        </div>
      </Container>
    </section>
  );
}
```

---

## FAQ Accordion Recipe

```tsx
export function FAQ() {
  const [openId, setOpenId] = useState<string | null>(null);

  return (
    <section className="py-20 md:py-24 bg-bg-base">
      <Container>
        <SectionHeading
          eyebrow="SSS"
          title="Sıkça Sorulan <em>Sorular</em>"
          description="Hizmetlerimiz hakkında en çok merak edilenler."
        />

        <div className="mt-12 md:mt-16 max-w-2xl mx-auto">
          {faqs.map((faq) => {
            const isOpen = openId === faq.id;
            return (
              <div key={faq.id} className="border-b border-border-subtle">
                <button
                  onClick={() => setOpenId(isOpen ? null : faq.id)}
                  className="w-full flex items-center justify-between py-[18px] text-left group"
                  aria-expanded={isOpen}
                >
                  <span className="text-base font-medium text-text-primary pr-4">
                    {faq.question}
                  </span>
                  <svg className={`flex-shrink-0 text-text-muted group-hover:text-brand-accent
                                 transition-all duration-200 ${isOpen ? 'rotate-45' : ''}`}
                    width="18" height="18" viewBox="0 0 24 24"
                    fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="12" y1="5" x2="12" y2="19" />
                    <line x1="5" y1="12" x2="19" y2="12" />
                  </svg>
                </button>

                {/* CSS-only animation — 0fr ⇄ 1fr */}
                <div className={`grid transition-[grid-template-rows] duration-300 ease-editorial
                               ${isOpen ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'}`}>
                  <div className="overflow-hidden">
                    <p className="pb-[18px] text-sm text-text-secondary leading-relaxed">
                      {faq.answer}
                    </p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </Container>
    </section>
  );
}
```

---

## CTA Panel Recipe

```tsx
export function FinalCTA() {
  return (
    <section className="py-24 md:py-32 bg-bg-base">
      <Container>
        <div className="relative overflow-hidden rounded-[22px] bg-bg-card border border-border-subtle">
          {/* Dot grid with radial mask */}
          <DotGrid
            dotColor="rgba(255,255,255,0.08)"
            maskRadius="ellipse 70% 70% at 50% 50%"
            className="opacity-50"
          />

          <div className="relative z-10 px-6 py-12 md:px-11 md:py-16
                        flex flex-col items-center text-center">
            <h2 className="text-h2 font-bold text-text-primary max-w-2xl">
              Projenize <em>Hemen</em> Başlayalım
            </h2>
            <p className="mt-4 text-body-lg text-text-secondary max-w-xl">
              Ücretsiz keşif ve fiyat teklifi için hemen ulaşın.
            </p>

            <div className="mt-8 flex flex-col sm:flex-row gap-3 w-full max-w-md justify-center">
              <Button variant="primary" size="lg" className="w-full sm:w-auto">
                Primary CTA
              </Button>
              <Button variant="secondary" size="lg" className="w-full sm:w-auto">
                Secondary CTA
              </Button>
            </div>

            <p className="mt-6 text-xs text-text-muted">
              📍 Konum • 7/24 hizmet
            </p>
          </div>
        </div>
      </Container>
    </section>
  );
}
```

---

## Glass Card Recipe

```tsx
// Glass surface — for overlay cards, CTA panels, process cards
<div className="
  bg-[rgba(10,10,10,0.7)]
  backdrop-blur-[20px]
  border border-[rgba(255,255,255,0.08)]
  rounded-3xl
  p-6 md:p-8
">
  {children}
</div>

// CSS fallback (globals.css)
@supports not (backdrop-filter: blur(20px)) {
  .glass-surface {
    background: #0A0A0A;
    backdrop-filter: none;
  }
}

// prefers-reduced-transparency
@media (prefers-reduced-transparency: reduce) {
  .glass-surface {
    background: #0A0A0A;
    backdrop-filter: none;
  }
}
```

---

## Interactive Card Recipe

```tsx
<Card variant="interactive" className="relative group overflow-hidden">
  {/* Card-local glow */}
  <div className="absolute inset-0 rounded-3xl opacity-0 group-hover:opacity-100
                transition-opacity duration-500 pointer-events-none"
    style={{ background: 'radial-gradient(400px circle at center, rgba(ACCENT_R,ACCENT_G,ACCENT_B,0.08), transparent 60%)' }} />

  {/* Border beam */}
  <BorderBeam className="opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

  {/* Content wrapper */}
  <div className="relative z-10">
    {/* Icon */}
    <span className="text-3xl mb-4 block
                  transition-transform duration-200 ease-editorial
                  group-hover:translate-y-[-2px]">
      {icon}
    </span>

    {/* Title */}
    <h3 className="text-lg font-semibold text-text-primary mb-2">
      {title}
    </h3>

    {/* Description */}
    <p className="text-sm text-text-secondary leading-relaxed">
      {description}
    </p>
  </div>
</Card>
```
