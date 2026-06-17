import { motion } from "framer-motion";
import { ArrowRight, MapPin, Maximize2 } from "lucide-react";
import dubai from "@/assets/listing-dubai.jpg";
import jeddah from "@/assets/listing-jeddah.jpg";
import doha from "@/assets/listing-doha.jpg";
import manama from "@/assets/listing-manama.jpg";
import kuwait from "@/assets/listing-kuwait.jpg";
import muscat from "@/assets/listing-muscat.jpg";

const LISTINGS = [
  { img: dubai, location: "Dubai, UAE", title: "Palm Jumeirah Beachfront", price: "AED 12.4M", area: "2,400 m²", badge: "Coastal" },
  { img: jeddah, location: "Jeddah, KSA", title: "Red Sea Coastal Strip", price: "SAR 8.9M", area: "5,100 m²", badge: "Premium" },
  { img: doha, location: "Doha, Qatar", title: "Lusail Mixed-Use Plot", price: "QAR 6.7M", area: "1,850 m²", badge: "Urban" },
  { img: manama, location: "Manama, Bahrain", title: "Amwaj Islands Lot", price: "BHD 540K", area: "1,200 m²", badge: "Coastal" },
  { img: kuwait, location: "Kuwait City, KW", title: "Sabhan Industrial Zone", price: "KWD 320K", area: "3,800 m²", badge: "Industrial" },
  { img: muscat, location: "Muscat, Oman", title: "Yiti Coastal Reserve", price: "OMR 285K", area: "2,000 m²", badge: "Coastal" },
];

export function Listings() {
  return (
    <section id="listings" className="relative py-24 lg:py-32 bg-background">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-6">
          <div className="max-w-2xl">
            <span className="text-xs font-semibold uppercase tracking-widest text-gold">Live listings</span>
            <h2 className="mt-3 font-display text-4xl sm:text-5xl font-bold text-foreground text-balance">
              Verified plots, ready to claim.
            </h2>
          </div>
          <a href="#" className="inline-flex items-center gap-2 text-sm font-semibold text-navy dark:text-gold hover:gap-3 transition-all">
            View all listings <ArrowRight className="h-4 w-4" />
          </a>
        </div>
      </div>

      <div className="mt-12 relative">
        <div className="overflow-x-auto scroll-smooth [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden">
          <div className="flex gap-6 px-4 sm:px-6 lg:px-8 pb-6 snap-x snap-mandatory">
            {LISTINGS.map((l, i) => (
              <motion.article
                key={l.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: i * 0.06 }}
                className="snap-start shrink-0 w-[320px] sm:w-[360px] rounded-2xl bg-card border border-border shadow-card overflow-hidden hover:shadow-elegant hover:-translate-y-1 transition-all duration-300 group"
              >
                <div className="relative h-56 overflow-hidden">
                  <img
                    src={l.img}
                    alt={l.title}
                    className="h-full w-full object-cover group-hover:scale-105 transition-transform duration-500"
                    loading="lazy"
                    width={800}
                    height={600}
                  />
                  <span className="absolute top-3 left-3 inline-flex items-center gap-1 rounded-full bg-background/95 backdrop-blur px-3 py-1 text-xs font-semibold text-foreground shadow-sm">
                    <MapPin className="h-3 w-3 text-gold" /> {l.location}
                  </span>
                  <span className="absolute top-3 right-3 rounded-full bg-gold/95 px-3 py-1 text-xs font-bold text-gold-foreground shadow-sm">
                    {l.badge}
                  </span>
                </div>
                <div className="p-6">
                  <h3 className="font-display text-lg font-semibold text-foreground line-clamp-1">{l.title}</h3>
                  <div className="mt-4 flex items-end justify-between">
                    <div>
                      <p className="text-xs text-muted-foreground">Asking price</p>
                      <p className="font-display text-2xl font-bold text-navy dark:text-gold">{l.price}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-muted-foreground">Plot area</p>
                      <p className="inline-flex items-center gap-1 font-semibold text-foreground">
                        <Maximize2 className="h-3.5 w-3.5" /> {l.area}
                      </p>
                    </div>
                  </div>
                  <a
                    href="#"
                    className="mt-5 flex items-center justify-center gap-2 rounded-lg border border-border py-2.5 text-sm font-semibold text-foreground hover:bg-navy hover:text-navy-foreground hover:border-navy transition-colors"
                  >
                    View Details <ArrowRight className="h-4 w-4" />
                  </a>
                </div>
              </motion.article>
            ))}
            <div className="shrink-0 w-4" aria-hidden />
          </div>
        </div>
      </div>
    </section>
  );
}
