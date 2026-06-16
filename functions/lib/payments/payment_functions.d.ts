/** Initiate a Telr payment */
export declare const initiatePayment: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    orderId: string;
    paymentUrl: string;
}>, unknown>;
/** Telr callback webhook — updates payment status */
export declare const paymentCallback: import("firebase-functions/v2/https").HttpsFunction;
/** Get payment status by order ID */
export declare const getPaymentStatus: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    id: string;
}>, unknown>;
//# sourceMappingURL=payment_functions.d.ts.map