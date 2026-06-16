"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserCreated = void 0;
const v1_1 = require("firebase-functions/v1");
const firestore_1 = require("firebase-admin/firestore");
const db = (0, firestore_1.getFirestore)();
/** When a new Firebase Auth user is created, write their profile to Firestore */
exports.onUserCreated = v1_1.auth.user().onCreate(async (user) => {
    const { uid, email, displayName, photoURL } = user;
    await db.collection("users").doc(uid).set({
        uid,
        email: email !== null && email !== void 0 ? email : null,
        displayName: displayName !== null && displayName !== void 0 ? displayName : null,
        photoURL: photoURL !== null && photoURL !== void 0 ? photoURL : null,
        role: "viewer",
        country: null,
        phone: null,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    console.log(`Created profile for user ${uid}`);
});
//# sourceMappingURL=on_user_created.js.map