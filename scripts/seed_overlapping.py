import datetime
from google.cloud import firestore

# --- CONFIGURATION ---
PROJECT_ID = 'bluehaven-automation'  # Replace if different
COLLECTION_NAME = 'bookings'

def seed_overlapping_bookings():
    print(f"🚀 Connecting to Firestore ({PROJECT_ID})...")
    db = firestore.Client(project=PROJECT_ID)
    batch = db.batch()

    # Helper: Get a Date relative to TODAY
    # We set strict times to ensure data purity, though Flutter overrides the visual time.
    def get_dt(offset_days, hour=12):
        now = datetime.datetime.now(datetime.timezone.utc)
        target = now + datetime.timedelta(days=offset_days)
        return target.replace(hour=hour, minute=0, second=0, microsecond=0)

    print("🧹 Clearing old booking data for clean test...")
    # Optional: Delete all existing to avoid confusion (Comment out if you want to keep them)
    docs = db.collection(COLLECTION_NAME).limit(50).stream()
    for doc in docs:
        doc.reference.delete()

    # --- THE TEST SCENARIOS ---
    
    bookings = [
        # --- SCENARIO 1: The "Perfect Turnover" (Room 101) ---
        # Guest A leaves TODAY morning. Guest B arrives TODAY afternoon.
        {
            'booking_ref': 'TEST-101-A',
            'guest_name': 'Sarah LEAVING',
            'status': 'checked_out',      # Should be GREY
            'assigned_room_id': '101',
            'check_in': get_dt(-3),       # Arrived 3 days ago
            'check_out': get_dt(0),       # Leaves TODAY
            'total_price': 300.0,
            'channel': 'Booking.com'
        },
        {
            'booking_ref': 'TEST-101-B',
            'guest_name': 'John ARRIVING',
            'status': 'checked_in',       # Should be GREEN
            'assigned_room_id': '101',
            'check_in': get_dt(0),        # Arrives TODAY
            'check_out': get_dt(4),       # Leaves in 4 days
            'total_price': 450.0,
            'channel': 'Agoda'
        },

        # --- SCENARIO 2: The "Gap" (Room 102) ---
        # Guest C leaves TOMORROW. Room sits empty for 1 day. Guest D arrives Day After.
        {
            'booking_ref': 'TEST-102-C',
            'guest_name': 'Mike Gap-Start',
            'status': 'checked_in',
            'assigned_room_id': '102',
            'check_in': get_dt(-2),
            'check_out': get_dt(1),       # Leaves TOMORROW
            'total_price': 200.0,
            'channel': 'Walk-in'
        },
        {
            'booking_ref': 'TEST-102-D',
            'guest_name': 'Lisa Gap-End',
            'status': 'confirmed',        # Should be BLUE
            'assigned_room_id': '102',
            'check_in': get_dt(3),        # Arrives in 3 days (Gap of 2 days)
            'check_out': get_dt(6),
            'total_price': 350.0,
            'channel': 'Airbnb'
        },

        # --- SCENARIO 3: The "Long Termer" (Room 103) ---
        # Stays for 2 weeks, covering the whole view.
        {
            'booking_ref': 'TEST-103-E',
            'guest_name': 'Tom Longstay',
            'status': 'checked_in',
            'assigned_room_id': '103',
            'check_in': get_dt(-5),
            'check_out': get_dt(10),
            'total_price': 1500.0,
            'channel': 'Direct'
        }
    ]

    print(f"📦 Seeding {len(bookings)} test scenarios...")

    for data in bookings:
        doc_ref = db.collection(COLLECTION_NAME).document(data['booking_ref'])
        
        # Add required metadata structure
        payload = {
            'booking_ref': data['booking_ref'],
            'guest_name': data['guest_name'],
            'assigned_room_id': data['assigned_room_id'],
            'status': data['status'],
            'check_in': data['check_in'],
            'check_out': data['check_out'],
            'total_price': data['total_price'],
            'channel': data['channel'],
            'total_paid': 0.0,
            'meta': {'adults': 2, 'children': 0, 'nights': 3},
            'updated_at': firestore.SERVER_TIMESTAMP
        }
        
        batch.set(doc_ref, payload)
        print(f"   - {data['guest_name']} (Room {data['assigned_room_id']})")

    batch.commit()
    print("✅ Overlap Test Data Seeded!")

if __name__ == '__main__':
    seed_overlapping_bookings()