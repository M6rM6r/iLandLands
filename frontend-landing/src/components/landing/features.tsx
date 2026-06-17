import { motion } from "framer-motion";
import { Brain, Map, Sparkles, ShieldCheck, MessageCircle, BarChart3 } from "lucide-react";
import { cn } from "@/lib/utils";

const FEATURES = [
  {
    icon: Brain,
    title: "AI Valuation Engine",
    desc: "Trained on 50k+ regional transactions. Get instant estimates with confidence intervals and comparable plots.",
    span: "md:col-span-2 md:row-span-2",
    highlight: true,
  },
  { icon: Map, title: "Coastal & Inland Listings", desc: "From Red Sea beachfront to Doha industrial zones — all verified.", span: "" },
  { icon: Sparkles, title: "Smart Recommendations", desc: "Match plots to your investment criteria automatically.", span: "" },
  { icon: ShieldCheck, title: "Secure Payments", desc: "Escrow-backed settlement with full legal documentation.", span: "" },
  { icon: MessageCircle, title: "WhatsApp Integration", desc: "Talk directly to verified owners in your preferred language.", span: "" },
  { icon: BarChart3, title: "Analytics Dashboard", desc: "Track inquiries, pricing trends, and portfolio performance.", span: "md:col-span-2" },
];

export function Features() {
  return (
    <section id="features" className="relative py-24 lg:py-32 bg-secondary/40">
      <div className="absolute inset-0 bg-grid-navy opacity-40 [mask-image:radial-gradient(ellipse_at_center,black_30%,transparent_75%)]" />
      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="max-w-2xl">
          <span className="text-xs font-semibold uppercase tracking-widest text-gold">Why Gulf Lands</span>
          <h2 className="mt-3 font-display text-4xl sm:text-5xl font-bold text-foreground text-balance">
            Built for serious investors.
          </h2>
          <p className="mt-4 text-lg text-muted-foreground">
            Everything you need to discover, evaluate, and acquire land — in one platform.
          </p>
        </div>

        <div className="mt-14 grid grid-cols-1 md:grid-cols-4 auto-rows-[200px] gap-5">
          {FEATURES.map((f, i) => (
            <motion.div
              key={f.title}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ duration: 0.5, delay: i * 0.05 }}
              className={cn(
                "group relative rounded-2xl border border-border bg-card p-6 lg:p-8 overflow-hidden transition-all duration-300 hover:-translate-y-1 hover:shadow-elegant",
                f.span,
                f.highlight && "bg-gradient-to-br from-navy to-navy/85 text-white border-navy",
              )}
            >
              {/* Gradient border on hover */}
              <div className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                style={{
                  background: "linear-gradient(135deg, color-mix(in oklab, var(--gold) 30%, transparent), transparent 60%)",
                  WebkitMaskImage: "linear-gradient(white,white) content-box, linear-gradient(white,white)",
                  WebkitMaskComposite: "xor",
                  maskComposite: "exclude",
                  padding: "1px",
                }} />

              <div className={cn(
                "inline-flex h-12 w-12 items-center justify-center rounded-xl",
                f.highlight ? "bg-gold/20 text-gold" : "bg-accent text-navy dark:text-gold",
              )}>
                <f.icon className="h-6 w-6" strokeWidth={1.8} />
              </div>

              <h3 className={cn(
                "mt-5 font-display text-xl lg:text-2xl font-semibold",
                f.highlight ? "text-white" : "text-foreground",
              )}>
                {f.title}
              </h3>
              <p className={cn(
                "mt-2 text-sm leading-relaxed",
                f.highlight ? "text-white/80" : "text-muted-foreground",
              )}>
                {f.desc}
              </p>

              {f.highlight && (
                <div className="absolute -bottom-12 -right-12 h-48 w-48 rounded-full bg-gold/20 blur-3xl" />
              )}
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
