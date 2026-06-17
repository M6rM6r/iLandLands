import { useState } from "react";
import { motion } from "framer-motion";
import { Check, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const TIERS = [
  {
    name: "Free",
    desc: "Browse and explore the marketplace.",
    monthly: 0,
    annual: 0,
    features: ["Unlimited browsing", "Saved searches (5)", "Email alerts", "Basic AI valuation"],
    cta: "Start free",
  },
  {
    name: "Pro",
    desc: "For active investors and serious buyers.",
    monthly: 29,
    annual: 24,
    features: [
      "Everything in Free",
      "Unlimited inquiries",
      "Priority owner response",
      "Full AI valuation history",
      "Comparable property reports",
      "WhatsApp direct connect",
    ],
    cta: "Start 14-day trial",
    highlight: true,
  },
  {
    name: "Enterprise",
    desc: "For brokerages, funds, and developers.",
    monthly: null,
    annual: null,
    features: ["Everything in Pro", "Custom API access", "White-label portal", "Dedicated account manager", "Bulk valuations", "SLA & onboarding"],
    cta: "Contact sales",
  },
];

export function Pricing() {
  const [annual, setAnnual] = useState(true);
  return (
    <section id="pricing" className="relative py-24 lg:py-32 bg-secondary/40">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto">
          <span className="text-xs font-semibold uppercase tracking-widest text-gold">Pricing</span>
          <h2 className="mt-3 font-display text-4xl sm:text-5xl font-bold text-foreground text-balance">
            Simple plans. Zero commission, always.
          </h2>
          <p className="mt-4 text-lg text-muted-foreground">
            Pay for tools, not transactions. Cancel anytime.
          </p>

          <div className="mt-8 inline-flex items-center gap-2 rounded-full border border-border bg-card p-1 shadow-card">
            <button
              type="button"
              onClick={() => setAnnual(false)}
              className={cn("rounded-full px-5 py-2 text-sm font-semibold transition", !annual ? "bg-navy text-navy-foreground" : "text-muted-foreground")}
            >
              Monthly
            </button>
            <button
              type="button"
              onClick={() => setAnnual(true)}
              className={cn("rounded-full px-5 py-2 text-sm font-semibold transition flex items-center gap-2", annual ? "bg-navy text-navy-foreground" : "text-muted-foreground")}
            >
              Annual <span className="rounded-full bg-gold/20 px-2 py-0.5 text-[10px] font-bold text-gold">−18%</span>
            </button>
          </div>
        </div>

        <div className="mt-14 grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8 max-w-6xl mx-auto">
          {TIERS.map((t, i) => (
            <motion.div
              key={t.name}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: i * 0.1 }}
              className={cn(
                "relative rounded-3xl border p-8 flex flex-col",
                t.highlight
                  ? "bg-navy text-white border-navy shadow-elegant md:-translate-y-4 md:scale-[1.03]"
                  : "bg-card border-border shadow-card",
              )}
            >
              {t.highlight && (
                <span className="absolute -top-3 left-1/2 -translate-x-1/2 inline-flex items-center gap-1.5 rounded-full bg-gradient-to-r from-gold to-gold/80 px-4 py-1 text-xs font-bold text-gold-foreground shadow-lg">
                  <Sparkles className="h-3 w-3" /> Recommended
                </span>
              )}

              <h3 className={cn("font-display text-2xl font-bold", t.highlight ? "text-white" : "text-foreground")}>
                {t.name}
              </h3>
              <p className={cn("mt-2 text-sm", t.highlight ? "text-white/70" : "text-muted-foreground")}>{t.desc}</p>

              <div className="mt-6 flex items-baseline gap-1">
                {t.monthly === null ? (
                  <span className={cn("font-display text-4xl font-bold", t.highlight ? "text-white" : "text-foreground")}>
                    Custom
                  </span>
                ) : (
                  <>
                    <span className={cn("font-display text-5xl font-bold", t.highlight ? "text-white" : "text-foreground")}>
                      ${annual ? t.annual : t.monthly}
                    </span>
                    <span className={cn("text-sm", t.highlight ? "text-white/70" : "text-muted-foreground")}>
                      /mo
                    </span>
                  </>
                )}
              </div>

              <ul className="mt-8 space-y-3 flex-1">
                {t.features.map((f) => (
                  <li key={f} className="flex items-start gap-3 text-sm">
                    <span className={cn(
                      "mt-0.5 inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full",
                      t.highlight ? "bg-gold/20 text-gold" : "bg-accent text-navy dark:text-gold",
                    )}>
                      <Check className="h-3 w-3" strokeWidth={3} />
                    </span>
                    <span className={t.highlight ? "text-white/90" : "text-foreground"}>{f}</span>
                  </li>
                ))}
              </ul>

              <Button
                className={cn(
                  "mt-8 h-12 font-semibold",
                  t.highlight
                    ? "bg-gold text-gold-foreground hover:bg-gold/90"
                    : "bg-foreground text-background hover:bg-foreground/90",
                )}
              >
                {t.cta}
              </Button>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
