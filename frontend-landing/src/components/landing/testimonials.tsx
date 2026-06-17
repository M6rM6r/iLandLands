import { Star } from "lucide-react";

const QUOTES = [
  { name: "Khalid Al-Mansoori", role: "Property Developer, Dubai", deal: "AED 18.2M deal", quote: "Closed a beachfront acquisition in 11 days. The AI valuation was within 3% of the final price." },
  { name: "Sara Al-Otaibi", role: "Family Office, Riyadh", deal: "SAR 14M deal", quote: "Finally, a marketplace built for serious investors. Verified listings save us weeks of due diligence." },
  { name: "Ahmed Bin Rashid", role: "Fund Manager, Doha", deal: "QAR 9.6M deal", quote: "The analytics dashboard alone is worth the subscription. We track regional pricing trends in real time." },
  { name: "Layla Hassan", role: "Architect, Manama", deal: "BHD 720K deal", quote: "WhatsApp direct messaging with verified owners. No middlemen. This is how it should be." },
  { name: "Omar Al-Sabah", role: "Investor, Kuwait City", deal: "KWD 410K deal", quote: "Zero commission saved me more than the annual subscription on a single transaction." },
  { name: "Faisal Al-Harthy", role: "Developer, Muscat", deal: "OMR 320K deal", quote: "Gulf Lands turned a six-month process into a six-week one. Incredible product." },
];

function Card({ q }: { q: (typeof QUOTES)[number] }) {
  return (
    <figure className="w-[360px] shrink-0 rounded-2xl bg-card border border-border p-6 shadow-card">
      <div className="flex gap-0.5 text-gold">
        {Array.from({ length: 5 }).map((_, i) => (
          <Star key={i} className="h-4 w-4 fill-current" />
        ))}
      </div>
      <blockquote className="mt-4 text-base leading-relaxed text-foreground">
        "{q.quote}"
      </blockquote>
      <figcaption className="mt-6 flex items-center gap-3">
        <div className="h-10 w-10 rounded-full bg-gradient-to-br from-navy to-navy/70 text-white flex items-center justify-center font-semibold text-sm">
          {q.name.split(" ").map((n) => n[0]).slice(0, 2).join("")}
        </div>
        <div className="flex-1">
          <div className="text-sm font-semibold text-foreground">{q.name}</div>
          <div className="text-xs text-muted-foreground">{q.role}</div>
        </div>
        <span className="rounded-full bg-accent px-2.5 py-1 text-[10px] font-bold text-navy dark:text-gold">
          {q.deal}
        </span>
      </figcaption>
    </figure>
  );
}

export function Testimonials() {
  const loop = [...QUOTES, ...QUOTES];
  return (
    <section className="relative py-24 lg:py-32 bg-background overflow-hidden">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-2xl mx-auto">
          <span className="text-xs font-semibold uppercase tracking-widest text-gold">Testimonials</span>
          <h2 className="mt-3 font-display text-4xl sm:text-5xl font-bold text-foreground text-balance">
            Trusted by investors across the Gulf.
          </h2>
        </div>
      </div>

      <div className="mt-14 group relative">
        <div className="absolute inset-y-0 left-0 w-32 bg-gradient-to-r from-background to-transparent z-10 pointer-events-none" />
        <div className="absolute inset-y-0 right-0 w-32 bg-gradient-to-l from-background to-transparent z-10 pointer-events-none" />
        <div className="flex gap-6 animate-marquee group-hover:[animation-play-state:paused] w-max">
          {loop.map((q, i) => (
            <Card key={i} q={q} />
          ))}
        </div>
      </div>
    </section>
  );
}
