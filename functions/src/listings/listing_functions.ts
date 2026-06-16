import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = getFirestore();

/** Generate an AI description for a listing — admin/manager only */
export const generateListingDescription = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in");

  const userDoc = await db.collection("users").doc(request.auth.uid).get();
  const role = userDoc.data()?.role;
  if (!["admin", "manager", "agent"].includes(role)) {
    throw new HttpsError("permission-denied", "Requires agent role or higher");
  }

  const { listingId } = request.data as { listingId: string };
  const listingDoc = await db.collection("land_listings").doc(listingId).get();
  if (!listingDoc.exists) throw new HttpsError("not-found", "Listing not found");

  const listing = listingDoc.data()!;
  const countryNames: Record<string, string> = {
    SA: "Saudi Arabia", UAE: "UAE", QA: "Qatar", BH: "Bahrain", OM: "Oman", KW: "Kuwait",
  };

  // Simple template-based description (replace with OpenAI call if key is set)
  const openAiKey = process.env.OPENAI_API_KEY;
  let description: string;

  if (openAiKey) {
    description = await callOpenAi(openAiKey, listing, countryNames);
  } else {
    description = `Premium land plot in ${listing.location}, ${countryNames[listing.country] ?? listing.country}. ` +
      `Spanning ${listing.area} sqm, this property is priced at ${listing.price} ${listing.currency ?? "USD"}. ` +
      `An exceptional investment opportunity in one of the Gulf's most sought-after real estate markets.`;
  }

  await db.collection("land_listings").doc(listingId).update({
    description,
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { description };
});

async function callOpenAi(apiKey: string, listing: FirebaseFirestore.DocumentData, countryNames: Record<string, string>): Promise<string> {
  const https = await import("https");
  const prompt = `Write a compelling 2-sentence real estate listing description for a land plot:
Title: ${listing.title}
Location: ${listing.location}, ${countryNames[listing.country] ?? listing.country}
Area: ${listing.area} sqm
Price: ${listing.price}
Keep it professional and persuasive.`;

  const body = JSON.stringify({
    model: "gpt-3.5-turbo",
    messages: [{ role: "user", content: prompt }],
    max_tokens: 150,
  });

  return new Promise((resolve, reject) => {
    const options = {
      hostname: "api.openai.com",
      path: "/v1/chat/completions",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
        "Content-Length": Buffer.byteLength(body),
      },
    };
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          const parsed = JSON.parse(data);
          resolve(parsed.choices?.[0]?.message?.content?.trim() ?? "Description unavailable.");
        } catch {
          reject(new Error("Invalid OpenAI response"));
        }
      });
    });
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}
