/** POST /submitInquiry — validate, score, store in Firestore */
export declare const submitInquiry: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    id: string;
    leadScore: number;
    leadBand: string;
}>, unknown>;
/** GET /listInquiries — admin only, returns paginated inquiries */
export declare const listInquiries: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    id: string;
}[]>, unknown>;
//# sourceMappingURL=inquiry_functions.d.ts.map