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
exports.getPaymentStatus = exports.paymentCallback = exports.initiatePayment = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const https = __importStar(require("https"));
const db = (0, firestore_1.getFirestore)();
function callTelr(body) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: "secure.telr.com",
            path: "/gateway/order.json",
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(body),
            },
        };
        const req = https.request(options, (res) => {
            let data = "";
            res.on("data", (chunk) => (data += chunk));
            res.on("end", () => {
                try {
                    resolve(JSON.parse(data));
                }
                catch (_a) {
                    reject(new Error("Invalid Telr response"));
                }
            });
        });
        req.on("error", reject);
        req.write(body);
        req.end();
    });
}
/** Initiate a Telr payment */
exports.initiatePayment = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Must be signed in");
    const { amount, currency, description, listingId } = request.data;
    if (!amount || amount <= 0)
        throw new https_1.HttpsError("invalid-argument", "Invalid amount");
    if (!["AED", "SAR", "QAR"].includes(currency))
        throw new https_1.HttpsError("invalid-argument", "Invalid currency");
    const storeId = (_a = process.env.TELR_STORE_ID) !== null && _a !== void 0 ? _a : "";
    const authKey = (_b = process.env.TELR_AUTH_KEY) !== null && _b !== void 0 ? _b : "";
    if (!storeId || !authKey)
        throw new https_1.HttpsError("internal", "Payment gateway not configured");
    const orderId = `ILND-${Date.now()}-${request.auth.uid.slice(0, 6)}`;
    const returnBase = "https://ilandlands.web.app";
    const requestBody = JSON.stringify({
        ivp_method: "create",
        ivp_store: storeId,
        ivp_authkey: authKey,
        ivp_amount: amount.toFixed(2),
        ivp_currency: currency,
        ivp_test: "1", // set "0" in production
        ivp_cart: orderId,
        ivp_desc: description,
        return_auth: `${returnBase}/?payment=success`,
        return_can: `${returnBase}/?payment=cancelled`,
        return_err: `${returnBase}/?payment=error`,
    });
    const telrResp = await callTelr(requestBody);
    if (telrResp.error || !telrResp.order) {
        throw new https_1.HttpsError("internal", (_d = (_c = telrResp.error) === null || _c === void 0 ? void 0 : _c.message) !== null && _d !== void 0 ? _d : "Payment initiation failed");
    }
    // Store pending payment record
    await db.collection("payments").doc(orderId).set({
        orderId,
        userId: request.auth.uid,
        listingId,
        amount,
        currency,
        status: "pending",
        telrRef: telrResp.order.ref,
        paymentUrl: telrResp.order.url,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { orderId, paymentUrl: telrResp.order.url };
});
/** Telr callback webhook — updates payment status */
exports.paymentCallback = (0, https_1.onRequest)(async (req, res) => {
    const { cart_id, status } = req.body;
    if (!cart_id) {
        res.status(400).send("Missing cart_id");
        return;
    }
    const statusCode = parseInt(status !== null && status !== void 0 ? status : "0", 10);
    let paymentStatus = "pending";
    if (statusCode === 3)
        paymentStatus = "completed";
    else if ([2, 6].includes(statusCode))
        paymentStatus = "failed";
    await db.collection("payments").doc(cart_id).update({
        status: paymentStatus,
        telrStatusCode: statusCode,
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    res.status(200).send("OK");
});
/** Get payment status by order ID */
exports.getPaymentStatus = (0, https_1.onCall)(async (request) => {
    var _a;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Must be signed in");
    const { orderId } = request.data;
    const doc = await db.collection("payments").doc(orderId).get();
    if (!doc.exists)
        throw new https_1.HttpsError("not-found", "Payment not found");
    const payment = doc.data();
    // Only the payment owner or admin can see it
    const userDoc = await db.collection("users").doc(request.auth.uid).get();
    const role = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.role;
    if (payment.userId !== request.auth.uid && !["admin", "manager"].includes(role)) {
        throw new https_1.HttpsError("permission-denied", "Access denied");
    }
    return Object.assign({ id: doc.id }, payment);
});
//# sourceMappingURL=payment_functions.js.map