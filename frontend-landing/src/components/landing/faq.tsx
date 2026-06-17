import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion";

const FAQS = [
  { q: "How does the AI valuation work?", a: "Our engine analyzes 50,000+ verified GCC land transactions, zoning data, coastal proximity, infrastructure scores, and market trends to produce an estimated value plus a confidence interval. Estimates are updated weekly." },
  { q: "Is my payment secure?", a: "All transactions are settled through licensed escrow partners in each jurisdiction. Funds are only released once title transfer is verified by registered authorities." },
  { q: "Can I list my own land?", a: "Yes. Pro and Enterprise members can submit listings. Every plot undergoes verification — title, zoning, and ownership — before going live (typically 48–72 hours)." },
  { q: "What countries are supported?", a: "We currently operate in the UAE, Saudi Arabia, Qatar, Bahrain, Kuwait, and Oman. Egypt and Jordan are launching in 2025." },
  { q: "How is commission calculated?", a: "There is none. Gulf Lands earns from subscriptions and value-added services like valuation reports and escrow processing. Sellers and buyers transact directly." },
  { q: "Are listings really verified?", a: "Yes. Our local verification teams independently confirm title deeds, zoning permissions, and seller identity for every plot. Listings without verification are not published." },
  { q: "Do you support Arabic?", a: "The platform is fully bilingual (English / Arabic) with RTL support. All listings include translated descriptions." },
  { q: "Can I get help from an advisor?", a: "Pro and Enterprise members get priority advisor access. Free users can book paid 30-minute sessions with regional specialists." },
];

export function FAQ() {
  return (
    <section id="faq" className="relative py-24 lg:py-32 bg-secondary/40">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto">
          <span className="text-xs font-semibold uppercase tracking-widest text-gold">FAQ</span>
          <h2 className="mt-3 font-display text-4xl sm:text-5xl font-bold text-foreground text-balance">
            Questions, answered.
          </h2>
        </div>

        <Accordion type="single" collapsible className="mt-12 space-y-3">
          {FAQS.map((f, i) => (
            <AccordionItem
              key={i}
              value={`item-${i}`}
              className="rounded-xl border border-border bg-card px-5 shadow-sm data-[state=open]:shadow-card"
            >
              <AccordionTrigger className="text-left font-semibold text-foreground hover:no-underline py-5">
                {f.q}
              </AccordionTrigger>
              <AccordionContent className="text-muted-foreground leading-relaxed pb-5">
                {f.a}
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </section>
  );
}
