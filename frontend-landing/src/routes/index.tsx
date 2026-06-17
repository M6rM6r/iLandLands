import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { Navbar } from "@/components/landing/navbar";
import { Hero } from "@/components/landing/hero";
import { HowItWorks } from "@/components/landing/how-it-works";
import { Features } from "@/components/landing/features";
import { Listings } from "@/components/landing/listings";
import { Pricing } from "@/components/landing/pricing";
import { Testimonials } from "@/components/landing/testimonials";
import { FAQ } from "@/components/landing/faq";
import { CTABanner } from "@/components/landing/cta-banner";
import { Footer } from "@/components/landing/footer";
import { WaitlistModal } from "@/components/landing/waitlist-modal";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Gulf Lands — Prime Land. Direct Access. Zero Commission." },
      {
        name: "description",
        content:
          "The premium land marketplace for the Gulf region. AI valuations, verified plots, and zero-commission deals across UAE, Saudi Arabia, Qatar, Bahrain, Kuwait, and Oman.",
      },
      { property: "og:title", content: "Gulf Lands — Prime Land. Direct Access." },
      {
        property: "og:description",
        content:
          "AI-powered marketplace for verified land plots across the GCC. Browse coastal and inland opportunities, get instant valuations, close securely.",
      },
      { property: "og:url", content: "/" },
    ],
    links: [{ rel: "canonical", href: "/" }],
    scripts: [
      {
        type: "application/ld+json",
        children: JSON.stringify({
          "@context": "https://schema.org",
          "@type": "Organization",
          name: "Gulf Lands",
          url: "https://gulflands.com",
          description: "Premium land marketplace for the Gulf region",
          areaServed: ["AE", "SA", "QA", "BH", "KW", "OM"],
        }),
      },
    ],
  }),
  component: LandingPage,
});

function LandingPage() {
  const [open, setOpen] = useState(false);
  const openModal = () => setOpen(true);

  return (
    <div className="min-h-screen bg-background">
      <Navbar onWaitlistClick={openModal} />
      <main>
        <Hero onWaitlistClick={openModal} />
        <HowItWorks />
        <Features />
        <Listings />
        <Pricing />
        <Testimonials />
        <FAQ />
        <CTABanner onWaitlistClick={openModal} />
      </main>
      <Footer />
      <WaitlistModal open={open} onOpenChange={setOpen} />
    </div>
  );
}
