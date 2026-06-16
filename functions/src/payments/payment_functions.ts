import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as https from "https";

const db = getFirestore();

interface PaymentInitPayload {
  amount: number;
  currency: "AED" | "SAR" | "QAR";
  description: string;
  listingId: string;
}

interface TelrResponse {
  order?: {
    ref: string;
    url: string;
  };
  error?: {
    message: string;
  };
}

function callTelr(body: string): Promise<TelrResponse> {
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
        } catch {
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
export const initiatePayment = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in");

  const { amount, currency, description, listingId } = request.data as unknown as PaymentInitPayload;
  if (!amount || amount <= 0) throw new HttpsError("invalid-argument", "Invalid amount");
  if (!["AED", "SAR", "QAR"].includes(currency)) throw new HttpsError("invalid-argument", "Invalid currency");

  const storeId = process.env.TELR_STORE_ID ?? "";
  const authKey = process.env.TELR_AUTH_KEY ?? "";

  if (!storeId || !authKey) throw new HttpsError("internal", "Payment gateway not configured");

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
    throw new HttpsError("internal", telrResp.error?.message ?? "Payment initiation failed");
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
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { orderId, paymentUrl: telrResp.order.url };
});

/** Telr callback webhook — updates payment status */
export const paymentCallback = onRequest(async (req, res) => {
  const { cart_id, status } = req.body as { cart_id: string; status: string };

  if (!cart_id) {
    res.status(400).send("Missing cart_id");
    return;
  }

  const statusCode = parseInt(status ?? "0", 10);
  let paymentStatus = "pending";
  if (statusCode === 3) paymentStatus = "completed";
  else if ([2, 6].includes(statusCode)) paymentStatus = "failed";

  await db.collection("payments").doc(cart_id).update({
    status: paymentStatus,
    telrStatusCode: statusCode,
    updatedAt: FieldValue.serverTimestamp(),
  });

  res.status(200).send("OK");
});

/** Get payment status by order ID */
export const getPaymentStatus = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Must be signed in");

  const { orderId } = request.data as { orderId: string };
  const doc = await db.collection("payments").doc(orderId).get();
  if (!doc.exists) throw new HttpsError("not-found", "Payment not found");

  const payment = doc.data()!;
  // Only the payment owner or admin can see it
  const userDoc = await db.collection("users").doc(request.auth.uid).get();
  const role = userDoc.data()?.role;
  if (payment.userId !== request.auth.uid && !["admin", "manager"].includes(role)) {
    throw new HttpsError("permission-denied", "Access denied");
  }

  return { id: doc.id, ...payment };
});
