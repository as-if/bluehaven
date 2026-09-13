const admin = require("firebase-admin");

// 1. INITIALIZE ADMIN SDK
// Replace './service-account.json' with the actual path to your key file
const serviceAccount = require("./service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * Parses date string to Firestore Timestamp
 * @param {any} dateVal
 * @return {admin.firestore.Timestamp|admin.firestore.FieldValue}
 */
function parseToTimestamp(dateVal) {
  if (!dateVal) return admin.firestore.FieldValue.serverTimestamp();
  if (dateVal.toDate) return dateVal; // Already a Timestamp
  const d = new Date(dateVal);
  if (!isNaN(d.valueOf())) {
    return admin.firestore.Timestamp.fromDate(d);
  }
  return admin.firestore.FieldValue.serverTimestamp();
}

/**
 * Migrates ledger data from legacy arrays to sub-collections.
 * @return {Promise<void>}
 */
async function migrateLedgerData() {
  console.log("🚀 Starting ledger migration...");

  const bookingsRef = db.collection("bookings");
  const snapshot = await bookingsRef.get();

  if (snapshot.empty) {
    console.log("❌ No bookings found to migrate.");
    return;
  }

  let totalBookingsProcessed = 0;
  let totalItemsMigrated = 0;
  let currentBatch = db.batch();
  let operationCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const bookingId = doc.id;

    // Legacy inline arrays
    const legacyCharges = data.ledger_charges || [];
    const legacyPayments = data.ledger_payments || [];

    if (legacyCharges.length === 0 && legacyPayments.length === 0) {
      continue;
    }

    // CLEANUP: Find and delete bad entries from previous migration attempts
    const existingLedgerSnap = await bookingsRef.doc(bookingId)
        .collection("ledger").get();
    for (const existingDoc of existingLedgerSnap.docs) {
      const existingData = existingDoc.data();
      const needsCleanup =
        existingDoc.id !== existingData.id ||
        typeof existingData.timestamp === "string";

      if (needsCleanup) {
        currentBatch.delete(existingDoc.ref);
        operationCount++;
        if (operationCount >= 450) {
          await currentBatch.commit();
          currentBatch = db.batch();
          operationCount = 0;
          console.log("📦 Batch committed (batch limit reached)...");
        }
      }
    }

    // Process Charges
    for (const charge of legacyCharges) {
      const targetId = charge.id || Math.random()
          .toString(36).substring(2, 15);
      const itemRef = bookingsRef.doc(bookingId)
          .collection("ledger").doc(targetId);
      const amount = parseFloat(charge.amount);

      const newCharge = {
        id: itemRef.id,
        description: charge.note || charge.type || "Charge",
        amount: isNaN(amount) ? 0 : amount,
        type: "charge",
        timestamp: parseToTimestamp(charge.date),
        isVoided: false,
        bookingId: bookingId,
        method: charge.type || "Other",
        voidedBy: null,
        voidedAt: null,
      };

      currentBatch.set(itemRef, newCharge);
      operationCount++;
      totalItemsMigrated++;
      if (operationCount >= 450) {
        await currentBatch.commit();
        currentBatch = db.batch();
        operationCount = 0;
        console.log("📦 Batch committed (batch limit reached)...");
      }
    }

    // Process Payments
    for (const payment of legacyPayments) {
      const targetId = payment.id || Math.random()
          .toString(36).substring(2, 15);
      const itemRef = bookingsRef.doc(bookingId)
          .collection("ledger").doc(targetId);
      const amount = parseFloat(payment.amount);

      const newPayment = {
        id: itemRef.id,
        description: payment.method || "Payment",
        amount: isNaN(amount) ? 0 : amount,
        type: "payment",
        timestamp: parseToTimestamp(payment.date),
        isVoided: false,
        bookingId: bookingId,
        method: payment.method || "Other",
        appliedToName: payment.applied_to_name || null,
        voidedBy: null,
        voidedAt: null,
      };

      currentBatch.set(itemRef, newPayment);
      operationCount++;
      totalItemsMigrated++;
      if (operationCount >= 450) {
        await currentBatch.commit();
        currentBatch = db.batch();
        operationCount = 0;
        console.log("📦 Batch committed (batch limit reached)...");
      }
    }

    totalBookingsProcessed++;
    const totalItems = legacyCharges.length + legacyPayments.length;
    console.log(`✅ Processed booking: ${bookingId} (+${totalItems} items)`);
  }

  // Final check to commit any remaining operations
  if (operationCount > 0) {
    await currentBatch.commit();
  }

  console.log("\n--- MIGRATION COMPLETE ---");
  console.log(`Total Bookings processed: ${totalBookingsProcessed}`);
  console.log(`Total Ledger Items migrated: ${totalItemsMigrated}`);
  console.log("---------------------------\n");
}

migrateLedgerData().catch((err) => {
  console.error("🔥 Migration failed:", err);
});
