import { MapPin, Twitter, Linkedin, Instagram, Facebook } from "lucide-react";

const COLS = [
  { title: "Product", links: ["Features", "Pricing", "Listings", "API", "Changelog"] },
  { title: "Company", links: ["About", "Careers", "Blog", "Press", "Contact"] },
  { title: "Legal", links: ["Privacy", "Terms", "Cookies", "Compliance", "Licenses"] },
];

const SOCIAL = [Twitter, Linkedin, Instagram, Facebook];

export function Footer() {
  return (
    <footer className="bg-navy text-white/85">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-10">
          <div className="col-span-2">
            <div className="flex items-center gap-2">
              <span className="inline-flex h-9 w-9 items-center justify-center rounded-lg bg-gold text-navy">
                <MapPin className="h-5 w-5" strokeWidth={2.5} />
              </span>
              <span className="font-display text-xl font-bold text-white">
                Gulf<span className="text-gold">Lands</span>
              </span>
            </div>
            <p className="mt-4 max-w-sm text-sm text-white/65 leading-relaxed">
              The premium land marketplace for the Gulf region. Verified plots, AI-powered pricing,
              zero commission.
            </p>
            <div className="mt-6 flex gap-3">
              {SOCIAL.map((Icon, i) => (
                <a
                  key={i}
                  href="#"
                  aria-label="Social link"
                  className="inline-flex h-9 w-9 items-center justify-center rounded-md border border-white/15 text-white/70 hover:bg-gold hover:text-navy hover:border-gold transition-colors"
                >
                  <Icon className="h-4 w-4" />
                </a>
              ))}
            </div>

            <div className="mt-8 flex gap-3">
              <div className="rounded-lg border border-white/15 px-4 py-2.5 text-left">
                <div className="text-[10px] uppercase tracking-wider text-white/50">Coming soon</div>
                <div className="text-sm font-semibold">App Store</div>
              </div>
              <div className="rounded-lg border border-white/15 px-4 py-2.5 text-left">
                <div className="text-[10px] uppercase tracking-wider text-white/50">Coming soon</div>
                <div className="text-sm font-semibold">Google Play</div>
              </div>
            </div>
          </div>

          {COLS.map((c) => (
            <div key={c.title}>
              <h4 className="font-display text-sm font-bold uppercase tracking-wider text-gold">
                {c.title}
              </h4>
              <ul className="mt-4 space-y-2.5">
                {c.links.map((l) => (
                  <li key={l}>
                    <a href="#" className="text-sm text-white/70 hover:text-white transition-colors">
                      {l}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-14 pt-8 border-t border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-xs text-white/55">
            © {new Date().getFullYear()} Gulf Lands FZ-LLC. All rights reserved.
          </p>
          <p className="text-xs text-white/55">
            Made with care across Dubai · Riyadh · Doha · Manama · Kuwait City · Muscat
          </p>
        </div>
      </div>
    </footer>
  );
}
