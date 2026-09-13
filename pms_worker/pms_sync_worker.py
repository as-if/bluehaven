import time
import sys
import argparse
import logging
try:
    from google.cloud import firestore
except ImportError:
    firestore = None

from config import (
    FIREBASE_PROJECT_ID,
    FIRESTORE_COLLECTION,
    MAX_RETRIES,
    SYNC_INTERVAL_SECONDS
)
from pms_browser_bot import PMSBrowserBot

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("PMSSyncWorker")


def get_firestore_client():
    if firestore is None:
        logger.warning(
            "⚠️ google-cloud-firestore package is not installed in the active environment. "
            "To connect to production Firestore, install with: pip install google-cloud-firestore"
        )
        return None
    try:
        return firestore.Client(project=FIREBASE_PROJECT_ID)
    except Exception as e:
        logger.warning(f"Could not connect to Firestore project '{FIREBASE_PROJECT_ID}': {e}")
        return None


def sync_pending_bookings(db=None):
    """
    Finds bookings with pms_sync.status == 'pending' or 'retry' and syncs them to the PMS.
    """
    if db is None:
        db = get_firestore_client()
        if db is None:
            logger.error("Firestore database client unavailable. Skipping sync pass.")
            return 0

    try:
        bookings_ref = db.collection(FIRESTORE_COLLECTION)

        # Query for pending bookings
        pending_docs = list(
            bookings_ref.where("pms_sync.status", "in", ["pending", "retry"]).limit(10).stream()
        )

        if not pending_docs:
            logger.info("No pending direct bookings to sync.")
            return 0

        logger.info(f"Found {len(pending_docs)} booking(s) pending PMS synchronization.")

        bot = PMSBrowserBot()
        synced_count = 0

        for doc_snap in pending_docs:
            data = doc_snap.to_dict()
            doc_id = doc_snap.id
            booking_ref = data.get("booking_ref", doc_id)
            current_attempts = data.get("pms_sync", {}).get("attempts", 0)

            logger.info(f"Processing booking: {booking_ref} (Attempt {current_attempts + 1})")

            result = bot.create_booking(data)

            if result.get("success"):
                pms_id = result.get("pms_reservation_id", f"PMS-{booking_ref}")
                
                # Update the original Firestore booking document with the official PMS Reference
                doc_snap.reference.update({
                    "booking_ref": pms_id,
                    "voucher_no": pms_id,
                    "pms_order_number": pms_id,
                    "pms_sync.status": "synced",
                    "pms_sync.synced_at": firestore.SERVER_TIMESTAMP,
                    "pms_sync.pms_reservation_id": pms_id,
                    "updated_at": firestore.SERVER_TIMESTAMP
                })

                # Create an alias document under doc(pms_id) so queries, staff lookups,
                # and email processors using the PMS Order Number resolve immediately.
                if doc_id != pms_id:
                    alias_data = doc_snap.to_dict()
                    alias_data["booking_ref"] = pms_id
                    alias_data["voucher_no"] = pms_id
                    alias_data["pms_order_number"] = pms_id
                    if "pms_sync" not in alias_data:
                        alias_data["pms_sync"] = {}
                    alias_data["pms_sync"]["status"] = "synced"
                    alias_data["pms_sync"]["pms_reservation_id"] = pms_id
                    alias_data["original_web_ref"] = doc_id
                    alias_data["updated_at"] = firestore.SERVER_TIMESTAMP
                    bookings_ref.document(pms_id).set(alias_data, merge=True)
                    logger.info(f"🔗 Created alias doc bookings/{pms_id} for web ref {doc_id}")

                logger.info(f"✅ Successfully synced booking {booking_ref} -> PMS Ref: {pms_id}")
                synced_count += 1
            else:
                new_attempts = current_attempts + 1
                new_status = "failed" if new_attempts >= MAX_RETRIES else "retry"
                doc_snap.reference.update({
                    "pms_sync.status": new_status,
                    "pms_sync.attempts": new_attempts,
                    "pms_sync.last_error": result.get("error", "Unknown error"),
                    "pms_sync.last_attempt_at": firestore.SERVER_TIMESTAMP,
                    "pms_sync.screenshot": result.get("screenshot")
                })
                logger.error(f"❌ Failed to sync {booking_ref} (status: {new_status}): {result.get('error')}")

        return synced_count

    except Exception as e:
        logger.error(f"Error during pending bookings sync: {e}", exc_info=True)
        return 0


def main():
    parser = argparse.ArgumentParser(description="Blue Haven PMS Browser Automation Sync Worker")
    parser.add_argument("--once", action="store_true", help="Run once and exit (for cron/testing)")
    parser.add_argument("--interval", type=int, default=SYNC_INTERVAL_SECONDS, help="Loop interval in seconds")
    args = parser.parse_args()

    logger.info("🏨 Starting Blue Haven PMS Browser Sync Worker...")
    db = get_firestore_client()

    if args.once:
        logger.info("Executing single sync run...")
        count = sync_pending_bookings(db)
        logger.info(f"Single sync run complete. Processed {count} bookings.")
        sys.exit(0)

    logger.info(f"Worker running in continuous mode. Polling interval: {args.interval}s")
    try:
        while True:
            sync_pending_bookings(db)
            time.sleep(args.interval)
    except KeyboardInterrupt:
        logger.info("Worker stopped by user.")


if __name__ == "__main__":
    main()
