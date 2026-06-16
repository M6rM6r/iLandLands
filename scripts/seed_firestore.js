#!/usr/bin/env node
/**
 * Firestore Seed Script
 * Seeds land_listings and system_settings collections with sample data.
 *
 * Usage:
 *   node scripts/seed_firestore.js
 *
 * Requirements:
 *   - GOOGLE_APPLICATION_CREDENTIALS env var pointing to a service account key JSON
 *   - Or run with: firebase emulators:exec "node scripts/seed_firestore.js"
 */

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

// Initialize
const app = initializeApp({
  credential: process.env.GOOGLE_APPLICATION_CREDENTIALS
    ? cert(require(process.env.GOOGLE_APPLICATION_CREDENTIALS))
    : undefined,
  projectId: process.env.GCLOUD_PROJECT || "ilandlands",
});

const db = getFirestore(app);

const listings = [
  {
    title: "Premium Land in Al-Malqa District",
    description: "Spacious corner plot in the prestigious Al-Malqa district of Riyadh. Excellent investment with high appreciation potential.",
    price: 2500000,
    area: 800,
    country: "SA",
    location: "Riyadh, Al-Malqa District",
    imageUrls: [
      "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800",
    ],
    isFeatured: true,
    status: "active",
    currency: "SAR",
  },
  {
    title: "Seafront Plot in Dubai Marina",
    description: "Rare seafront land opportunity in Dubai Marina with stunning views of the Arabian Gulf.",
    price: 8500000,
    area: 500,
    country: "UAE",
    location: "Dubai, Marina District",
    imageUrls: [
      "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800",
    ],
    isFeatured: true,
    status: "active",
    currency: "AED",
  },
  {
    title: "Commercial Land in West Bay Doha",
    description: "Prime commercial plot in the heart of Doha's business district. Perfect for mixed-use development.",
    price: 6200000,
    area: 1200,
    country: "QA",
    location: "Doha, West Bay",
    imageUrls: [
      "https://images.unsplash.com/photo-1582407947304-fd86f28f3e36?w=800",
    ],
    isFeatured: false,
    status: "active",
    currency: "QAR",
  },
  {
    title: "Residential Plot in Seef District",
    description: "Well-located residential plot in Bahrain's Seef district, close to major shopping centers.",
    price: 320000,
    area: 450,
    country: "BH",
    location: "Manama, Seef District",
    imageUrls: [
      "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800",
    ],
    isFeatured: false,
    status: "active",
    currency: "BHD",
  },
  {
    title: "Coastal Land in Muscat Hills",
    description: "Beautiful coastal land with panoramic sea views in the exclusive Muscat Hills development.",
    price: 480000,
    area: 600,
    country: "OM",
    location: "Muscat, Muscat Hills",
    imageUrls: [
      "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
    ],
    isFeatured: true,
    status: "active",
    currency: "OMR",
  },
  {
    title: "Investment Plot in Salmiya",
    description: "High-value investment plot in Kuwait's most sought-after commercial and residential area.",
    price: 950000,
    area: 350,
    country: "KW",
    location: "Kuwait City, Salmiya",
    imageUrls: [
      "https://images.unsplash.com/photo-1486325212027-8081e485255e?w=800",
    ],
    isFeatured: false,
    status: "active",
    currency: "KWD",
  },
  {
    title: "Villa Plot in Al Barsha",
    description: "Corner villa plot in the family-friendly Al Barsha neighbourhood, close to Mall of the Emirates.",
    price: 4100000,
    area: 900,
    country: "UAE",
    location: "Dubai, Al Barsha",
    imageUrls: [
      "https://images.unsplash.com/photo-1571055107559-3e67626fa8be?w=800",
    ],
    isFeatured: false,
    status: "active",
    currency: "AED",
  },
  {
    title: "Industrial Land in Jeddah Industrial City",
    description: "Large industrial plot with direct road access in King Abdullah Economic City adjacent area.",
    price: 3800000,
    area: 5000,
    country: "SA",
    location: "Jeddah, Industrial City",
    imageUrls: [
      "https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800",
    ],
    isFeatured: false,
    status: "active",
    currency: "SAR",
  },
  {
    title: "Beachfront Land in The Pearl",
    description: "Exclusive beachfront land in The Pearl-Qatar island. Freehold ownership for all nationalities.",
    price: 12000000,
    area: 700,
    country: "QA",
    location: "Doha, The Pearl Island",
    imageUrls: [
      "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800",
    ],
    isFeatured: true,
    status: "active",
    currency: "QAR",
  },
  {
    title: "Agricultural Land in Al Kharj",
    description: "Fertile agricultural land near Al Kharj with water rights and road access. Ideal for farming or eco-development.",
    price: 750000,
    area: 10000,
    country: "SA",
    location: "Al Kharj, Eastern Riyadh Region",
    imageUrls: [
      "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800",
    ],
    isFeatured: false,
    status: "active",
    currency: "SAR",
  },
];

const systemSettings = {
  site_name: "iLandLands",
  site_description: "Premium Gulf Real Estate Land Marketplace",
  contact_email: "admin@ilandlands.com",
  max_upload_size: "10485760",
  featured_listings_count: "6",
  analytics_retention_days: "365",
  enable_search_tracking: "true",
  default_country: "UAE",
};

async function seed() {
  console.log("🌱 Seeding Firestore...");

  // Seed land_listings
  const batch = db.batch();
  const now = Timestamp.now();

  for (const listing of listings) {
    const ref = db.collection("land_listings").doc();
    batch.set(ref, { ...listing, createdAt: now, updatedAt: now });
  }

  // Seed system_settings
  for (const [key, value] of Object.entries(systemSettings)) {
    const ref = db.collection("system_settings").doc(key);
    batch.set(ref, { key, value, updatedAt: now });
  }

  await batch.commit();
  console.log(`✅ Seeded ${listings.length} listings and ${Object.keys(systemSettings).length} settings.`);
  process.exit(0);
}

seed().catch((err) => {
  console.error("❌ Seed failed:", err);
  process.exit(1);
});
