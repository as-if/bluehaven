import base64
import json
import os
import re
import email
import datetime
import functions_framework
from bs4 import BeautifulSoup
from google.cloud import firestore
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from parsers.yanolja_direct_parser import parse_yanolja_direct_booking

# --- CONFIGURATION ---
db = firestore.Client()
COLLECTION_NAME = 'bookings'

CLIENT_ID = os.environ.get('CLIENT_ID')
CLIENT_SECRET = os.environ.get('CLIENT_SECRET')
REFRESH_TOKEN = os.environ.get('REFRESH_TOKEN')

def get_gmail_creds():
    creds = Credentials(
        None, 
        refresh_token=REFRESH_TOKEN, 
        token_uri="https://oauth2.googleapis.com/token", 
        client_id=CLIENT_ID, 
        client_secret=CLIENT_SECRET
    )
    if not creds.valid:
        creds.refresh(Request())
    return creds

def clean_text(text):
    if not text: return "N/A"
    return " ".join(text.replace('\r', ' ').replace('\n', ' ').split())

def parse_int(text):
    if not text: return 1
    match = re.search(r'\d+', text)
    return int(match.group()) if match else 1

# --- NEW HELPER: Parse Dates to Firestore Timestamps ---
def parse_date(date_str, time_type='checkin'):
    """
    Parse date and set default times:
    - Check-in: 14:00 (2 PM)
    - Check-out: 12:00 (12 PM)
    Timezone: GMT+5
    """
    if not date_str or date_str == "N/A":
        return datetime.datetime.now()
    
    clean_str = date_str.strip()
    dt = None
    try:
        # Format 1: DD-MM-YYYY (Common in emails)
        dt = datetime.datetime.strptime(clean_str, "%d-%m-%Y")
    except ValueError:
        try:
            # Format 2: YYYY-MM-DD
            dt = datetime.datetime.strptime(clean_str, "%Y-%m-%d")
        except ValueError:
            print(f"⚠️ Date parse error: '{clean_str}', defaulting to NOW.")
            return datetime.datetime.now()
    
    # Set default time based on check-in or check-out
    if time_type == 'checkin':
        dt = dt.replace(hour=14, minute=0, second=0, microsecond=0)
    else:  # checkout
        dt = dt.replace(hour=12, minute=0, second=0, microsecond=0)
    
    # Apply GMT+5 timezone
    gmt_plus_5 = datetime.timezone(datetime.timedelta(hours=5))
    dt = dt.replace(tzinfo=gmt_plus_5)
    
    return dt

# --- NEW HELPER: Parse Price Strings to Float ---
def parse_price(price_str):
    if not price_str or price_str == "N/A": 
        return 0.0
    # Remove all non-numeric chars except the decimal point
    clean_str = re.sub(r'[^\d.]', '', str(price_str))
    try:
        return float(clean_str)
    except ValueError:
        return 0.0

def parse_booking(raw_html):
    soup = BeautifulSoup(raw_html, 'html.parser')
    
    def get_val(label_pattern, stop_marker=None):
        for element in soup.find_all(['td', 'th', 'div', 'span']):
            cell_text = clean_text(element.get_text(strip=True))
            
            if re.search(label_pattern, cell_text, re.IGNORECASE):
                if ':' in cell_text:
                    parts = cell_text.split(':', 1)
                    if len(parts) > 1 and parts[1].strip():
                        val = clean_text(parts[1])
                        if stop_marker and stop_marker in val:
                            val = val.split(stop_marker)[0].strip()
                        return val
                
                if element.name in ['td', 'th']:
                    next_el = element.find_next_sibling(['td', 'th'])
                    if next_el:
                        return clean_text(next_el.get_text(strip=True))
        return "N/A"

    def get_all_vals(label_pattern):
        values = []
        for element in soup.find_all(['td', 'th']):
            cell_text = clean_text(element.get_text(strip=True))
            if re.search(label_pattern, cell_text, re.IGNORECASE):
                if ':' in cell_text:
                    parts = cell_text.split(':', 1)
                    if len(parts) > 1 and parts[1].strip():
                        values.append(clean_text(parts[1]))
                        continue
                next_el = element.find_next_sibling(['td', 'th'])
                if next_el:
                    values.append(clean_text(next_el.get_text(strip=True)))
        return values

    raw_rooms = get_val(r'No\.\s*Of\s*Rooms')
    num_rooms = parse_int(raw_rooms)
    
    room_types = get_all_vals(r'Room\s*Type')
    rate_types = get_all_vals(r'Rate\s*Type')
    
    if len(room_types) < num_rooms and room_types:
        room_types = room_types * num_rooms 
    if len(rate_types) < num_rooms and rate_types:
        rate_types = rate_types * num_rooms

    guest_name = get_val(r'Name')
    if guest_name == "N/A" or len(guest_name.split()) == 1:
        full_text = soup.get_text(separator='\n')
        your_details_match = re.search(
            r'Your\s+Details\s*[\r\n]+\s*([^\r\n]+)', full_text, re.IGNORECASE
        )
        if your_details_match:
            cand = your_details_match.group(1).strip()
            if cand and not any(cand.lower().startswith(kw) for kw in ['email', 'phone', 'mobile', 'address', 'special']):
                if guest_name == "N/A" or len(cand.split()) > len(guest_name.split()):
                    guest_name = cand

        dear_match = re.search(
            r'Dear\s+([\s\S]+?)(?=,|\n\s*Thank|\n\s*We\s+are|\n\s*Email|\n\s*Booking|\n\s*Check|\n\s*\r?\n)',
            full_text,
            re.IGNORECASE,
        )
        if dear_match:
            cand_dear = " ".join(dear_match.group(1).split()).strip()
            cand_dear = re.sub(r'[\s,]+$', '', cand_dear)
            if cand_dear:
                if guest_name == "N/A" or len(cand_dear.split()) > len(guest_name.split()):
                    guest_name = cand_dear

    return {
        'guest_name': guest_name,
        'booking_channel': get_val(r'(?:Booking\s*)?Channel', stop_marker='Booking DateTime'),
        'voucher_number': get_val(r'(?:Travel\s*Agent\s*)?Voucher\s*No'),
        'check_in': get_val(r'Check\s*In'),
        'check_out': get_val(r'Check\s*Out'),
        'total_price': get_val(r'Total\s*Amount'),
        'phone': get_val(r'Phone'),
        'nights': parse_int(get_val(r'No\.\s*Of\s*Nights')),
        'num_rooms': num_rooms,
        'adults': parse_int(get_val(r'Total\s*Adult')),
        'children': parse_int(get_val(r'Total\s*Child')),
        'room_details': [{'type': t, 'rate': r} for t, r in zip(room_types, rate_types)]
    }

def get_safe_next_status(existing_status, email_status):
    """
    Ensures booking status only moves forward. 
    Emails typically only send 'confirmed', 'modified', or 'cancelled'.
    """
    if not existing_status:
        return email_status
        
    if email_status == 'cancelled':
        if existing_status in ['checked_out', 'cancelled']:
            return existing_status
        return 'cancelled'
        
    if email_status == 'modified':
        if existing_status in ['confirmed', 'modified']:
            return 'modified'
        return existing_status
        
    # If email_status is 'confirmed' (or anything else)
    # Never downgrade modified, checked_in, checked_out, or cancelled to confirmed.
    if existing_status in ['modified', 'checked_in', 'checked_out', 'cancelled']:
        return existing_status
        
    return email_status

def update_firestore(booking_ref, data, status, internal_date):
    print(f"--- FIRESTORE WRITE: {booking_ref} [{status}] ---")
    
    doc_ref = db.collection(COLLECTION_NAME).document(booking_ref)
    
    # Check existing status to ensure safe forward-movement
    booking_snapshot = doc_ref.get()
    if booking_snapshot.exists:
        existing_status = booking_snapshot.get('status')
        status = get_safe_next_status(existing_status, status)
    
    # 1. Parse Internal Date (Email received time)
    try:
        email_time = datetime.datetime.fromtimestamp(int(internal_date)/1000, tz=datetime.timezone.utc)
    except:
        email_time = datetime.datetime.now(datetime.timezone.utc)
    
    if status == 'cancelled':
        # Just update status, keep other data intact
        doc_ref.set({'status': 'cancelled', 'updated_at': firestore.SERVER_TIMESTAMP}, merge=True)
        print("Updated status to cancelled.")
        return

    # 2. DATA TRANSFORMATION (Strings -> Typed Objects)
    check_in_dt = parse_date(data['check_in'], 'checkin')
    check_out_dt = parse_date(data['check_out'], 'checkout')
    total_price_float = parse_price(data['total_price'])

    # 3. Construct Payload
    booking_doc = {
        'booking_ref': booking_ref,
        'guest_name': data['guest_name'],
        'channel': data['booking_channel'],
        'voucher_no': data['voucher_number'],
        'phone': data['phone'],
        
        # --- NEW TYPED FIELDS ---
        'check_in': check_in_dt,         # Timestamp
        'check_out': check_out_dt,       # Timestamp
        'total_price': total_price_float,# Number
        'total_paid': 0.0,               # Default for new bookings
        'assigned_room_id': "Not Assigned",       # Explicit Not Assigned for "Unassigned"
        
        'status': status,
        'meta': {
            'nights': data['nights'],
            'adults': data['adults'],
            'children': data['children'],
            'room_count': data['num_rooms']
        },
        'rooms': data['room_details'], 
        'received_at': email_time,
        'updated_at': firestore.SERVER_TIMESTAMP
    }

    # Merge=True ensures we don't accidentally wipe fields if we update partial data later
    doc_ref.set(booking_doc, merge=True)
    print(f"Document written successfully. ({check_in_dt.date()} - {total_price_float})")


def save_direct_booking_to_firestore(parsed_booking, internal_date):
    """
    Save a Direct/Walk-in parsed booking to Firestore using the same
    document structure as the standard update_firestore flow.
    """
    booking_ref = parsed_booking.get("booking_ref", "UNKNOWN")
    guest_name_log = parsed_booking.get("guest_name", "N/A")
    print(f"--- FIRESTORE WRITE (Direct): {booking_ref} | Guest Name: '{guest_name_log}' ---")

    doc_ref = db.collection(COLLECTION_NAME).document(booking_ref)

    # Check if the booking already exists to preserve status
    booking_snapshot = doc_ref.get()
    exists = booking_snapshot.exists

    status = parsed_booking.get("status", "confirmed")
    if exists:
        existing_status = booking_snapshot.get("status")
        new_status = get_safe_next_status(existing_status, status)
        if new_status == existing_status and status != existing_status:
            print(f"Booking {booking_ref} already exists. Preserving status: '{existing_status}' to prevent backward movement.")
        elif new_status != existing_status:
            print(f"Booking {booking_ref} already exists. Updating status to: '{new_status}'.")
        status = new_status
    else:
        # If the booking is cancelled and does not exist, just write status as cancelled and return
        if status == 'cancelled':
            doc_ref.set({'status': 'cancelled', 'updated_at': firestore.SERVER_TIMESTAMP}, merge=True)
            print("New booking - status is cancelled (Direct). Written to Firestore.")
            return

    # Parse email received time
    try:
        email_time = datetime.datetime.fromtimestamp(
            int(internal_date) / 1000, tz=datetime.timezone.utc
        )
    except Exception:
        email_time = datetime.datetime.now(datetime.timezone.utc)

    # Convert date strings (YYYY-MM-DD) to Firestore timestamps via parse_date
    check_in_dt = parse_date(parsed_booking.get("check_in", "N/A"), "checkin")
    check_out_dt = parse_date(parsed_booking.get("check_out", "N/A"), "checkout")

    booking_doc = {
        "booking_ref": booking_ref,
        "guest_name": parsed_booking.get("guest_name", "N/A"),
        "guest_email": parsed_booking.get("guest_email", "N/A"),
        "channel": parsed_booking.get("channel", "Direct/Walk-in"),
        "voucher_no": "N/A",
        "phone": "N/A",
        # Typed fields
        "check_in": check_in_dt,
        "check_out": check_out_dt,
        "total_price": parsed_booking.get("total_price", 0.0),
        "total_paid": 0.0,
        "assigned_room_id": "Not Assigned",
        "status": status,
        "meta": parsed_booking.get("meta", {}),
        "rooms": parsed_booking.get("room_details", []),
        "received_at": email_time,
        "updated_at": firestore.SERVER_TIMESTAMP,
        "source_email": parsed_booking.get("source_email", ""),
        "last_updated_by": "System (Yanolja Direct)",
    }

    # Add adults/children to meta if present at top level
    if "adults" in parsed_booking:
        booking_doc["meta"]["adults"] = parsed_booking["adults"]
    if "children" in parsed_booking:
        booking_doc["meta"]["children"] = parsed_booking["children"]

    batch = db.batch()
    batch.set(doc_ref, booking_doc, merge=True)
    
    # --- Create/Update Room Charge ledger entry ---
    # We update or create the initial room charge in the ledger:
    total_price = parsed_booking.get("total_price", 0.0)
    if total_price > 0:
        ledger_id = "initial_room_charge"
        ledger_ref = doc_ref.collection("ledger").document(ledger_id)
        batch.set(ledger_ref, {
            "id": ledger_id,
            "description": "Room Charge",
            "amount": total_price,
            "type": "charge",
            "timestamp": firestore.SERVER_TIMESTAMP,
            "isVoided": False,
            "bookingId": booking_ref,
            "method": "Room Rate",
        }, merge=True)

    batch.commit()
    print(
        f"Direct booking written successfully for '{guest_name_log}'. "
        f"({check_in_dt.date()} - {parsed_booking.get('total_price', 0.0)})"
    )


@functions_framework.cloud_event
def gmail_pubsub_handler(cloud_event):
    print("--- WORKER WAKE UP ---")

    msg_id = None
    service = None
    try:
        creds = get_gmail_creds()
        service = build('gmail', 'v1', credentials=creds)

        # Limit to 1 message per run to prevent timeout/overflow during testing
        results = service.users().messages().list(
            userId='me', q="label:API_Yanolja_Bookings", maxResults=1
        ).execute()
        messages = results.get('messages', [])

        if not messages:
            print("No messages found.")
            return

        msg_id = messages[0]['id']
        msg = service.users().messages().get(
            userId='me', id=msg_id, format='raw'
        ).execute()

        raw = base64.urlsafe_b64decode(msg['raw'])
        email_msg = email.message_from_bytes(raw)
        subject_raw = email_msg.get('Subject', '')
        subject = subject_raw.lower()
        sender = email_msg.get('From', '')

        if 'yanoljacloudsolution.com' in sender or 'booking ref' in subject:

            # ── Route 1: Direct/Walk-in bookings ──────────────────────
            if "reservations@yanoljacloudsolution.com" in sender:
                print("📌 Routing to Direct/Walk-in parser...")

                # Extract HTML body — these emails use an HTML template
                body_html = ""
                if email_msg.is_multipart():
                    for part in email_msg.walk():
                        if part.get_content_type() == 'text/html':
                            body_html = part.get_payload(decode=True).decode()
                            break
                else:
                    body_html = email_msg.get_payload(decode=True).decode()

                if body_html:
                    parsed = parse_yanolja_direct_booking(body_html, subject_raw)
                    save_direct_booking_to_firestore(parsed, msg['internalDate'])
                else:
                    print("Error: No HTML body found for Direct booking email.")

            # ── Route 2: Standard HTML booking emails ─────────────────
            else:
                # Extract Reference from Subject "[ REFERENCE ]"
                ref_match = re.search(r'\[\s*(.*?)\s*\]', subject_raw)
                booking_ref = ref_match.group(1).strip() if ref_match else "UNKNOWN"

                # Determine Status
                status = 'confirmed'
                if "cancel" in subject:
                    status = 'cancelled'
                elif "modify" in subject or "change" in subject or "update" in subject:
                    status = 'modified'

                # Extract HTML Body
                body_html = ""
                if email_msg.is_multipart():
                    for part in email_msg.walk():
                        if part.get_content_type() == 'text/html':
                            body_html = part.get_payload(decode=True).decode()
                            break
                else:
                    body_html = email_msg.get_payload(decode=True).decode()

                if body_html:
                    extracted = parse_booking(body_html)
                    update_firestore(booking_ref, extracted, status, msg['internalDate'])
                else:
                    print("Error: No HTML body.")
        else:
            print(f"Skipping email as it does not match criteria: {subject_raw} from {sender}")

    except Exception as e:
        print(f"CRITICAL ERROR: {e}")

    finally:
        # Remove label 'API_Yanolja_Bookings' from the retrieved message so we don't process it again
        if msg_id and service:
            try:
                # Find label ID for API_Yanolja_Bookings
                labels_results = service.users().labels().list(userId='me').execute()
                label_id = next((l['id'] for l in labels_results.get('labels', []) if l['name'] == 'API_Yanolja_Bookings'), None)
                if label_id:
                    service.users().messages().modify(
                        userId='me',
                        id=msg_id,
                        body={'removeLabelIds': [label_id]}
                    ).execute()
                    print(f"Successfully removed label 'API_Yanolja_Bookings' (ID: {label_id}) from message {msg_id}")
                else:
                    print("Warning: label 'API_Yanolja_Bookings' not found to remove.")
            except Exception as le:
                print(f"Failed to remove label from message {msg_id}: {le}")