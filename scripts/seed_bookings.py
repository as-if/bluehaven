import datetime
import random
from google.cloud import firestore

# --- CONFIGURATION ---
PROJECT_ID = 'bluehaven-automation'  # Replace with your actual Project ID
COLLECTION_NAME = 'bookings'

def seed_bookings():
    print(f"🚀 Connecting to Firestore ({PROJECT_ID})...")
    db = firestore.Client(project=PROJECT_ID)
    batch = db.batch()

    # Helper to get a timezone-aware datetime (UTC)
    def get_date(offset_days):
        return datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=offset_days)

    # --- THE DATA ---
    # We create a mix of statuses to test the dashboard colors
    bookings_data = [
        {
            'booking_ref': 'X96C-ALICE',
            'guest_name': 'Alice Johnson',
            'channel': 'Agoda',
            'status': 'checked_in',         # Green on Calendar
            'check_in': get_date(-1),       # Arrived yesterday
            'check_out': get_date(2),       # Leaving in 2 days
            'total_price': 450.00,          # Store as Number, not String
            'assigned_room_id': '101',
            'meta': {'adults': 2, 'children': 0, 'nights': 3}
        },
        {
            'booking_ref': 'X96C-BOB',
            'guest_name': 'Bob Smith',
            'channel': 'Walk-in',
            'status': 'checked_out',        # Grey on Calendar
            'check_in': get_date(-5),
            'check_out': get_date(0),       # Left today
            'total_price': 400.50,
            'assigned_room_id': '102',
            'meta': {'adults': 1, 'children': 0, 'nights': 5}
        },
        {
            'booking_ref': 'X96C-CHARLIE',
            'guest_name': 'Charlie Davis',
            'channel': 'Booking.com',
            'status': 'confirmed',          # Blue on Calendar
            'check_in': get_date(3),        # Arriving in 3 days
            'check_out': get_date(8),
            'total_price': 1200.00,
            'assigned_room_id': '105',
            'meta': {'adults': 2, 'children': 2, 'nights': 5}
        },
        {
            'booking_ref': 'X96C-DIANA',
            'guest_name': 'Diana Prince',
            'channel': 'Direct',
            'status': 'confirmed',
            'check_in': get_date(1),        # Arriving tomorrow
            'check_out': get_date(7),
            'total_price': 2500.00,
            'assigned_room_id': 'A101',     # Deluxe Room
            'meta': {'adults': 1, 'children': 0, 'nights': 6}
        },
        {
            'booking_ref': 'X96C-EVAN',     # Unassigned Booking (No Room yet)
            'guest_name': 'Evan Wright',
            'channel': 'Airbnb',
            'status': 'confirmed',
            'check_in': get_date(10),
            'check_out': get_date(15),
            'total_price': 850.00,
            'assigned_room_id': None,       # Should not crash the app
            'meta': {'adults': 2, 'children': 0, 'nights': 5}
        }
    ]

    print(f"📦 Preparing to seed {len(bookings_data)} bookings...")

    for data in bookings_data:
        # Use booking_ref as the Document ID
        doc_ref = db.collection(COLLECTION_NAME).document(data['booking_ref'])
        
        # Firestore automatically converts Python datetime -> Timestamp
        batch.set(doc_ref, data)
        print(f"   - Queueing {data['guest_name']} ({data['status']})")

    # Commit
    print("💾 Committing to Firestore...")
    batch.commit()
    print("✅ Success! Bookings seeded with Timestamps.")

if __name__ == '__main__':
    seed_bookings()