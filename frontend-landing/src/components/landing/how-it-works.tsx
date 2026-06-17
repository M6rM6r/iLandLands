import { motion } from "framer-motion";
import { Brain, Search, CalendarCheck, Handshake } from "lucide-react";

const STEPS = [
  { icon: Brain, title: "AI Valuation", desc: "Get an instant estimated value powered by our valuation engine trained on regional comps." },
  { icon: Search, title: "Browse Verified Listings", desc: "Explore coastal and inland plots — every listing is independently verified before going live." },
  { icon: CalendarCheck, title: "Schedule a Site Visit", desc: "Book in-person or virtual tours with the owner directly through the platform." },
  { icon: Handshake, title: "Close Securely", desc: "Sign and settle through our escrow flow. Zero commission. Full transparency." },
];

export function HowItWorks() {
  return (
    <section id="how-it-works" className="relative py-24 lg:py-32 bg-background">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="max-w-2xl">
          <span className="text-xs font-semibold uppercase tracking-widest text-gold">How it works</span>
          <h2 className="mt-3 font-display text-4xl sm:text-5xl font-bold text-foreground text-balance">
            From valuation to deal — in four steps.
          </h2>
          <p className="mt-4 text-lg text-muted-foreground">
            A faster, cleaner path to owning land in the Gulf. No agents. No surprises.
          </p>
        </div>

        <div className="mt-16 relative">
          {/* Horizontal connector */}
          <div className="hidden lg:block absolute top-12 left-12 right-12 h-px bg-gradient-to-r from-transparent via-gold/40 to-transparent" />

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8 lg:gap-6 relative">
            {STEPS.map((s, i) => (
              <motion.div
                key={s.title}
                initial={{ opacity: 0, y: 24 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-50px" }}
                transition={{ duration: 0.5, delay: i * 0.1 }}
                className="relative"
              >
                <div className="relative inline-flex h-24 w-24 items-center justify-center rounded-2xl bg-card border border-border shadow-card">
                  <s.icon className="h-10 w-10 text-navy dark:text-gold" strokeWidth={1.6} />
                  <span className="absolute -top-2 -right-2 h-7 w-7 rounded-full bg-gold text-gold-foreground text-xs font-bold flex items-center justify-center shadow-md">
                    {i + 1}
                  </span>
                </div>
                <h3 className="mt-6 font-display text-xl font-semibold text-foreground">
                  {s.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{s.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
