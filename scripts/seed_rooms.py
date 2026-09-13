import datetime
from google.cloud import firestore

# --- CONFIGURATION ---
PROJECT_ID = 'bluehaven-automation'
COLLECTION_NAME = 'rooms'

def seed_rooms():
    print(f"🚀 Connecting to Firestore ({PROJECT_ID})...")
    db = firestore.Client(project=PROJECT_ID)
    batch = db.batch()

    # Define Room IDs
    standard_rooms = [f'10{i}' for i in range(1, 7)]  # 101-106
    deluxe_rooms = [f'A10{i}' for i in range(1, 5)]   # A101-A104
    all_rooms = standard_rooms + deluxe_rooms

    print(f"📦 Preparing to seed {len(all_rooms)} rooms...")

    for room_id in all_rooms:
        doc_ref = db.collection(COLLECTION_NAME).document(room_id)
        
        # Determine Type
        room_type = 'Deluxe Ocean View' if room_id.startswith('A') else 'Standard Room'
        
        # Data Schema
        room_data = {
            'id': room_id,
            'type': room_type,
            'status': 'available',
            'currentBookingId': None,
            'currentGuestName': None,
            # Timestamp: 10 days ago
            'lastDeepClean': datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=10)
        }
        
        batch.set(doc_ref, room_data)
        print(f"   - Queueing Room {room_id}")

    print("💾 Committing to Firestore...")
    batch.commit()
    print("✅ Success! Rooms seeded.")

if __name__ == '__main__':
    seed_rooms()