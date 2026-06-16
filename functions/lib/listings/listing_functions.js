"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateListingDescription = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
/** Generate an AI description for a listing — admin/manager only */
exports.generateListingDescription = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Must be signed in");
    const userDoc = await db.collection("users").doc(request.auth.uid).get();
    const role = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.role;
    if (!["admin", "manager", "agent"].includes(role)) {
        throw new https_1.HttpsError("permission-denied", "Requires agent role or higher");
    }
    const { listingId } = request.data;
    const listingDoc = await db.collection("land_listings").doc(listingId).get();
    if (!listingDoc.exists)
        throw new https_1.HttpsError("not-found", "Listing not found");
    const listing = listingDoc.data();
    const countryNames = {
        SA: "Saudi Arabia", UAE: "UAE", QA: "Qatar", BH: "Bahrain", OM: "Oman", KW: "Kuwait",
    };
    // Simple template-based description (replace with OpenAI call if key is set)
    const openAiKey = process.env.OPENAI_API_KEY;
    let description;
    if (openAiKey) {
        description = await callOpenAi(openAiKey, listing, countryNames);
    }
    else {
        description = `Premium land plot in ${listing.location}, ${(_b = countryNames[listing.country]) !== null && _b !== void 0 ? _b : listing.country}. ` +
            `Spanning ${listing.area} sqm, this property is priced at ${listing.price} ${(_c = listing.currency) !== null && _c !== void 0 ? _c : "USD"}. ` +
            `An exceptional investment opportunity in one of the Gulf's most sought-after real estate markets.`;
    }
    await db.collection("land_listings").doc(listingId).update({
        description,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { description };
});
async function callOpenAi(apiKey, listing, countryNames) {
    var _a;
    const https = await Promise.resolve().then(() => __importStar(require("https")));
    const prompt = `Write a compelling 2-sentence real estate listing description for a land plot:
Title: ${listing.title}
Location: ${listing.location}, ${(_a = countryNames[listing.country]) !== null && _a !== void 0 ? _a : listing.country}
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
                var _a, _b, _c, _d, _e;
                try {
                    const parsed = JSON.parse(data);
                    resolve((_e = (_d = (_c = (_b = (_a = parsed.choices) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.message) === null || _c === void 0 ? void 0 : _c.content) === null || _d === void 0 ? void 0 : _d.trim()) !== null && _e !== void 0 ? _e : "Description unavailable.");
                }
                catch (_f) {
                    reject(new Error("Invalid OpenAI response"));
                }
            });
        });
        req.on("error", reject);
        req.write(body);
        req.end();
    });
}
//# sourceMappingURL=listing_functions.js.map