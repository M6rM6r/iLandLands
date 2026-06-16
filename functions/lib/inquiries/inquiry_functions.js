"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listInquiries = exports.submitInquiry = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
/** Simple lead score: 0–100 based on message length, phone presence, email domain */
function scoreLead(payload) {
    var _a;
    let score = 20;
    if (payload.message.length > 100)
        score += 30;
    else if (payload.message.length > 50)
        score += 15;
    if (payload.phone && payload.phone.length > 7)
        score += 20;
    const domain = (_a = payload.email.split("@")[1]) !== null && _a !== void 0 ? _a : "";
    if (!["gmail.com", "yahoo.com", "hotmail.com"].includes(domain))
        score += 30;
    return Math.min(score, 100);
}
function leadBand(score) {
    if (score >= 70)
        return "hot";
    if (score >= 40)
        return "warm";
    return "cold";
}
/** POST /submitInquiry — validate, score, store in Firestore */
exports.submitInquiry = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const payload = request.data;
    // Basic validation
    if (!((_a = payload.name) === null || _a === void 0 ? void 0 : _a.trim()))
        throw new https_1.HttpsError("invalid-argument", "name is required");
    if (!((_b = payload.email) === null || _b === void 0 ? void 0 : _b.includes("@")))
        throw new https_1.HttpsError("invalid-argument", "valid email is required");
    if (!payload.message || payload.message.length < 10)
        throw new https_1.HttpsError("invalid-argument", "message must be at least 10 characters");
    if (!((_c = payload.landId) === null || _c === void 0 ? void 0 : _c.trim()))
        throw new https_1.HttpsError("invalid-argument", "landId is required");
    const score = scoreLead(payload);
    const band = leadBand(score);
    const docRef = await db.collection("inquiries").add({
        name: payload.name.trim(),
        email: payload.email.toLowerCase().trim(),
        phone: (_e = (_d = payload.phone) === null || _d === void 0 ? void 0 : _d.trim()) !== null && _e !== void 0 ? _e : null,
        message: payload.message.trim(),
        landId: payload.landId,
        userId: (_h = (_f = payload.userId) !== null && _f !== void 0 ? _f : (_g = request.auth) === null || _g === void 0 ? void 0 : _g.uid) !== null && _h !== void 0 ? _h : null,
        status: "new",
        leadScore: score,
        leadBand: band,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { id: docRef.id, leadScore: score, leadBand: band };
});
/** GET /listInquiries — admin only, returns paginated inquiries */
exports.listInquiries = (0, https_1.onCall)(async (request) => {
    var _a;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Must be signed in");
    // Check admin role
    const userDoc = await db.collection("users").doc(request.auth.uid).get();
    const role = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.role;
    if (!["admin", "manager"].includes(role)) {
        throw new https_1.HttpsError("permission-denied", "Requires admin or manager role");
    }
    const { status, landId, limit = 20 } = request.data;
    let query = db.collection("inquiries").orderBy("createdAt", "desc").limit(limit);
    if (status)
        query = query.where("status", "==", status);
    if (landId)
        query = query.where("landId", "==", landId);
    const snapshot = await query.get();
    return snapshot.docs.map((d) => (Object.assign({ id: d.id }, d.data())));
});
//# sourceMappingURL=inquiry_functions.js.map