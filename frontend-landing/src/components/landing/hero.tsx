import { motion } from "framer-motion";
import { ArrowRight, ShieldCheck, Sparkles, Users } from "lucide-react";
import { Button } from "@/components/ui/button";
import heroImage from "@/assets/hero-coastline.jpg";

const TRUST = [
  { icon: ShieldCheck, label: "Verified Plots Only" },
  { icon: Sparkles, label: "AI-Powered Pricing" },
  { icon: Users, label: "10,000+ Happy Investors" },
];

export function Hero({ onWaitlistClick }: { onWaitlistClick: () => void }) {
  return (
    <section className="relative isolate min-h-screen flex items-center overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 -z-10">
        <img
          src={heroImage}
          alt="Aerial view of Gulf coastline"
          className="h-full w-full object-cover"
          width={1920}
          height={1280}
        />
        <div className="absolute inset-0 bg-gradient-to-br from-navy/85 via-navy/75 to-navy/40" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,transparent_0%,rgba(10,37,64,0.6)_100%)]" />
      </div>

      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8 pt-32 pb-20">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, ease: "easeOut" }}
          className="max-w-3xl"
        >
          <span className="inline-flex items-center gap-2 rounded-full border border-gold/40 bg-gold/10 px-4 py-1.5 text-xs font-semibold uppercase tracking-widest text-gold backdrop-blur">
            <span className="h-1.5 w-1.5 rounded-full bg-gold animate-pulse" />
            Now live across the GCC
          </span>

          <h1 className="mt-6 font-display text-5xl sm:text-6xl lg:text-7xl font-bold leading-[1.05] tracking-tight text-white text-balance">
            Prime Land.{" "}
            <span className="gradient-text-gold">Direct Access.</span>{" "}
            Zero Commission.
          </h1>

          <p className="mt-6 max-w-2xl text-lg sm:text-xl leading-relaxed text-white/80">
            The first AI-powered marketplace for verified land plots across the Gulf.
            Discover coastal and inland opportunities, get instant valuations, and close
            deals directly with owners — no middlemen, no hidden fees.
          </p>

          <div className="mt-10 flex flex-col sm:flex-row gap-4">
            <Button
              size="lg"
              className="bg-gold text-gold-foreground hover:bg-gold/90 font-semibold text-base h-14 px-8 shadow-gold"
              asChild
            >
              <a href="#listings">
                Browse Listings <ArrowRight className="ml-2 h-5 w-5" />
              </a>
            </Button>
            <Button
              size="lg"
              variant="outline"
              onClick={onWaitlistClick}
              className="bg-transparent text-white border-white/30 hover:bg-white/10 hover:text-white font-semibold text-base h-14 px-8"
            >
              Get Valuation
            </Button>
          </div>

          <div className="mt-14 flex flex-wrap gap-x-8 gap-y-4">
            {TRUST.map((t) => (
              <div key={t.label} className="flex items-center gap-2 text-white/85">
                <t.icon className="h-5 w-5 text-gold" strokeWidth={2} />
                <span className="text-sm font-medium">{t.label}</span>
              </div>
            ))}
          </div>
        </motion.div>
      </div>

      {/* Scroll indicator */}
      <div className="absolute bottom-8 left-1/2 -translate-x-1/2 hidden md:block">
        <div className="h-12 w-7 rounded-full border-2 border-white/30 flex justify-center pt-2">
          <motion.div
            animate={{ y: [0, 12, 0] }}
            transition={{ duration: 1.8, repeat: Infinity }}
            className="h-2 w-1 rounded-full bg-white/70"
          />
        </div>
      </div>
    </section>
  );
}
