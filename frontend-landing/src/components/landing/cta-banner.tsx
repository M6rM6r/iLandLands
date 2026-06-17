import { useState } from "react";
import { ArrowRight } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { z } from "zod";

const emailSchema = z.string().trim().email("Enter a valid email").max(255);

export function CTABanner({ onWaitlistClick }: { onWaitlistClick: () => void }) {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const parsed = emailSchema.safeParse(email);
    if (!parsed.success) {
      toast.error(parsed.error.issues[0]?.message ?? "Invalid email");
      return;
    }
    setLoading(true);
    try {
      const list = JSON.parse(localStorage.getItem("gulflands-waitlist") || "[]");
      list.push({ email: parsed.data, at: new Date().toISOString(), source: "cta-banner" });
      localStorage.setItem("gulflands-waitlist", JSON.stringify(list));
      toast.success("You're on the list — we'll be in touch.");
      setEmail("");
      onWaitlistClick();
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="relative py-24 lg:py-32 bg-background">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="relative isolate overflow-hidden rounded-3xl bg-gradient-to-br from-navy via-navy to-navy/85 px-8 py-16 sm:px-16 sm:py-20 shadow-elegant">
          {/* Animated gradient blobs */}
          <div className="absolute -top-24 -right-24 h-72 w-72 rounded-full bg-gold/30 blur-3xl animate-pulse" />
          <div className="absolute -bottom-24 -left-24 h-72 w-72 rounded-full bg-gold/20 blur-3xl animate-pulse [animation-delay:1s]" />
          <div className="absolute inset-0 bg-grid-navy opacity-20 [mask-image:radial-gradient(ellipse_at_center,black_40%,transparent_70%)]" />

          <div className="relative max-w-2xl">
            <h2 className="font-display text-4xl sm:text-5xl font-bold text-white text-balance leading-tight">
              Ready to invest in Gulf land?
            </h2>
            <p className="mt-4 text-lg text-white/80">
              Join 10,000+ investors getting early access to verified plots and AI-powered insights.
            </p>

            <form onSubmit={handleSubmit} className="mt-8 flex flex-col sm:flex-row gap-3">
              <Input
                type="email"
                placeholder="you@company.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="h-14 bg-white/10 border-white/20 text-white placeholder:text-white/50 focus-visible:ring-gold text-base px-5"
                aria-label="Email address"
                required
              />
              <Button
                type="submit"
                disabled={loading}
                className="h-14 px-7 bg-gold text-gold-foreground hover:bg-gold/90 font-semibold whitespace-nowrap"
              >
                Get Early Access <ArrowRight className="ml-2 h-5 w-5" />
              </Button>
            </form>

            <p className="mt-3 text-xs text-white/60">No spam. Unsubscribe anytime.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
