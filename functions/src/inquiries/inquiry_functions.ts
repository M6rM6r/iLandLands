import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = getFirestore();

interface InquiryPayload {
  name: string;
  email: string;
  phone: string;
  message: string;
  landId: string;
  userId?: string;
}

/** Simple lead score: 0–100 based on message length, phone presence, email domain */
function scoreLead(payload: InquiryPayload): number {
  let score = 20;
  if (payload.message.length > 100) score += 30;
  else if (payload.message.length > 50) score += 15;
  if (payload.phone && payload.phone.length > 7) score += 20;
  const domain = payload.email.split("@")[1] ?? "";
  if (!["gmail.com", "yahoo.com", "hotmail.com"].includes(domain)) score += 30;
  return Math.min(score, 100);
}

function leadBand(score: number): string {
  if (score >= 70) return "hot";
  if (score >= 40) return "warm";
  return "cold";
}

/** POST /submitInquiry — validate, score, store in Firestore */
export const submitInquiry = onCall(async (request) => {
  const payload = request.data as unknown as InquiryPayload;

  // Basic validation
  if (!payload.name?.trim()) throw new HttpsError("invalid-argument", "name is required");
  if (!payload.email?.includes("@")) throw new HttpsError("invalid-argument", "valid email is required");
  if (!payload.message || payload.message.length < 10) throw new HttpsError("invalid-argument", "message must be at least 10 characters");
  if (!payload.landId?.trim()) throw new HttpsError("invalid-argument", "landId is required");

  const score = scoreLead(payload);
  const band = leadBand(score);

  const docRef = await db.collection("inquiries").add({
    name: payload.name.trim(),
    email: payload.email.toLowerCase().trim(),
    phone: payload.phone?.trim() ?? null,
    message: payload.message.trim(),
    landId: payload.landId,
    userId: payload.userId ?? request.auth?.uid ?? null,
    status: "new",
    leadScore: score,
    leadBand: band,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { id: docRef.id, leadScore: score, leadBand: band };
});

/** GET /listInquiries — admin only, returns paginated inquiries */
export const listInquiries = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in");

  // Check admin role
  const userDoc = await db.collection("users").doc(request.auth.uid).get();
  const role = userDoc.data()?.role;
  if (!["admin", "manager"].includes(role)) {
    throw new HttpsError("permission-denied", "Requires admin or manager role");
  }

  const { status, landId, limit = 20 } = request.data as { status?: string; landId?: string; limit?: number };

  let query: FirebaseFirestore.Query = db.collection("inquiries").orderBy("createdAt", "desc").limit(limit);
  if (status) query = query.where("status", "==", status);
  if (landId) query = query.where("landId", "==", landId);

  const snapshot = await query.get();
  return snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
});
