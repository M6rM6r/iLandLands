import { auth } from "firebase-functions/v1";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = getFirestore();

/** When a new Firebase Auth user is created, write their profile to Firestore */
export const onUserCreated = auth.user().onCreate(async (user) => {
  const { uid, email, displayName, photoURL } = user;

  await db.collection("users").doc(uid).set({
    uid,
    email: email ?? null,
    displayName: displayName ?? null,
    photoURL: photoURL ?? null,
    role: "viewer",
    country: null,
    phone: null,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  console.log(`Created profile for user ${uid}`);
});
