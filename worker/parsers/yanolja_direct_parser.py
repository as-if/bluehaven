"""
Parser for Direct/Walk-in booking confirmation emails from Yanolja Channel Manager.

These emails arrive from reservations@yanoljacloudsolution.com and use an HTML
template that is structurally different from the standard OTA booking emails.
This parser uses BeautifulSoup to extract data from the HTML body, then applies
regex where needed to pull specific values from the extracted text.
"""

import re
import datetime
from bs4 import BeautifulSoup


def parse_yanolja_direct_booking(html_body, subject):
    """
    Parse a Direct/Walk-in booking confirmation email from Yanolja.

    Args:
        html_body: The raw HTML body of the email.
        subject: The email subject line (used as fallback for reference).

    Returns:
        dict: Parsed booking data ready for Firestore.
    """
    soup = BeautifulSoup(html_body, 'html.parser')
    full_text = soup.get_text(separator='\n')

    # Determine status from subject or html body text
    body_text_lower = full_text.lower()
    subject_lower = subject.lower()

    if "cancel" in subject_lower:
        status = "cancelled"
    elif any(kw in subject_lower for kw in ["modify", "change", "update", "amend"]):
        status = "modified"
    elif "confirm" in subject_lower:
        status = "confirmed"
    else:
        # Stricter fallback for body text to avoid false positives (e.g., 'cancellation policy')
        if "booking cancelled" in body_text_lower or "reservation cancelled" in body_text_lower or "has been cancelled" in body_text_lower:
            status = "cancelled"
        elif "booking modified" in body_text_lower or "reservation modified" in body_text_lower or "has been modified" in body_text_lower:
            status = "modified"
        else:
            status = "confirmed"

    booking_data = {
        "channel": "Direct/Walk-in",
        "status": status,
        "is_parsed": True,
        "source_email": "reservations@yanoljacloudsolution.com",
        "meta": {},
    }

    # --- Reference Number ---
    # Template: "BOOKING REFERENCE NO :R1C5169F0832C"
    try:
        ref_match = re.search(r'BOOKING\s+REFERENCE\s+NO\s*:\s*([A-Z0-9]+)', full_text)
        if ref_match:
            booking_data["booking_ref"] = ref_match.group(1).strip()
        else:
            # Fallback: subject line "Booking Reference Number R1C5169F0832C - CONFIRMED"
            ref_subject = re.search(r'Booking\s+Reference\s+Number\s+([A-Z0-9]+)', subject, re.IGNORECASE)
            if ref_subject:
                booking_data["booking_ref"] = ref_subject.group(1).strip()
            else:
                # Last fallback: bracket format "[ REF ]"
                ref_bracket = re.search(r'\[\s*([A-Z0-9-]+)\s*\]', subject)
                booking_data["booking_ref"] = ref_bracket.group(1).strip() if ref_bracket else "UNKNOWN"
                if booking_data["booking_ref"] == "UNKNOWN":
                    print("⚠️ Yanolja Direct: Could not extract reference number.")
    except Exception as e:
        print(f"⚠️ Yanolja Direct: Reference extraction error: {e}")
        booking_data["booking_ref"] = "UNKNOWN"

    # --- Guest Name ---
    # Supports full names and multi-word company/association names (e.g., "Multi Youth Association of Thulusdhoo")
    try:
        guest_name = "N/A"

        # Strategy 1: DOM search for "Your Details"
        yd_tag = soup.find(lambda tag: tag.name in ['td', 'th', 'div', 'p', 'b', 'strong'] and 'Your Details' in tag.get_text(strip=True))
        if yd_tag:
            cell = yd_tag.find_parent(['td', 'th'])
            text_after = ''
            if cell:
                next_cell = cell.find_next_sibling(['td', 'th'])
                if next_cell:
                    text_after = next_cell.get_text(strip=True)
                else:
                    tr = cell.find_parent('tr')
                    if tr:
                        next_tr = tr.find_next_sibling('tr')
                        if next_tr:
                            text_after = next_tr.get_text(strip=True)
            else:
                next_sib = yd_tag.find_next_sibling(['div', 'p', 'span', 'tr', 'td', 'br'])
                if next_sib:
                    text_after = next_sib.get_text(strip=True)

            clean_cand = ' '.join(text_after.split())
            if clean_cand:
                first_line = re.split(r'Email|Phone|Mobile|Address', clean_cand, flags=re.IGNORECASE)[0].strip()
                if first_line and not any(first_line.lower().startswith(kw) for kw in ['email', 'phone', 'mobile', 'address']):
                    guest_name = first_line

        # Strategy 2: Regex search for "Your Details"
        yd_match = re.search(r'Your\s+Details\s*:?\s*(?:[\r\n]+\s*)*([^\r\n]+)', full_text, re.IGNORECASE)
        if yd_match:
            cand = yd_match.group(1).strip()
            cand = re.split(r'Email|Phone|Mobile|Address', cand, flags=re.IGNORECASE)[0].strip()
            if cand and not any(cand.lower().startswith(kw) for kw in ['email', 'phone', 'mobile', 'address']):
                if guest_name == "N/A" or len(cand) > len(guest_name):
                    guest_name = cand

        # Strategy 3: Regex search for "Dear <Name>," (handles newlines inside greeting)
        dear_match = re.search(
            r'Dear\s+([\s\S]+?)(?=,|\n\s*Thank|\n\s*We\s+are|\n\s*Email|\n\s*Booking|\n\s*Check|\n\s*Rooms|\n\s*Rates)',
            full_text,
            re.IGNORECASE,
        )
        if dear_match:
            cand_dear = " ".join(dear_match.group(1).split()).strip()
            cand_dear = re.sub(r'[\s,]+$', '', cand_dear)
            if cand_dear:
                if guest_name == "N/A" or len(cand_dear) > len(guest_name):
                    guest_name = cand_dear

        booking_data["guest_name"] = guest_name if guest_name else "N/A"
    except Exception as e:
        print(f"⚠️ Yanolja Direct: Guest name extraction error: {e}")
        booking_data["guest_name"] = "N/A"

    # --- Guest Email ---
    # Template: "Email ID : bluehavenretreat7@gmail.com"
    try:
        email_match = re.search(
            r'Email\s+ID\s*:\s*([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
            full_text,
        )
        if email_match:
            booking_data["guest_email"] = email_match.group(1).strip()
        else:
            booking_data["guest_email"] = "N/A"
    except Exception as e:
        print(f"⚠️ Yanolja Direct: Guest email extraction error: {e}")
        booking_data["guest_email"] = "N/A"

    # --- Check-In Date ---
    # Templates: "Check In Date : 30-04-2026", "Check-In: 30/04/2026", "Arrival: 30-04-2026"
    try:
        checkin_match = re.search(
            r'(?:Check[-\s]*In(?:\s+Date)?|Arrival(?:\s+Date)?)\s*[:\-]\s*(\d{2}[-/]\d{2}[-/]\d{4})',
            full_text,
            re.IGNORECASE
        )
        if checkin_match:
            raw_date = checkin_match.group(1).strip().replace('/', '-')
            dt = datetime.datetime.strptime(raw_date, "%d-%m-%Y")
            booking_data["check_in"] = dt.strftime("%Y-%m-%d")
        else:
            booking_data["check_in"] = "N/A"
    except Exception as e:
        print(f"⚠️ Yanolja Direct: Check-in date parse error: {e}")
        booking_data["check_in"] = "N/A"

    # --- Check-Out Date ---
    try:
        checkout_match = re.search(
            r'(?:Check[-\s]*Out(?:\s+Date)?|Departure(?:\s+Date)?)\s*[:\-]\s*(\d{2}[-/]\d{2}[-/]\d{4})',
            full_text,
            re.IGNORECASE
        )
        if checkout_match:
            raw_date = checkout_match.group(1).strip().replace('/', '-')
            dt = datetime.datetime.strptime(raw_date, "%d-%m-%Y")
            booking_data["check_out"] = dt.strftime("%Y-%m-%d")
        else:
            booking_data["check_out"] = "N/A"
    except Exception as e:
        print(f"⚠️ Yanolja Direct: Check-out date parse error: {e}")
        booking_data["check_out"] = "N/A"

    # --- Nights ---
    try:
        nights_match = re.search(r'Nights\s*:\s*(\d+)', full_text)
        if nights_match:
            booking_data["meta"]["nights"] = int(nights_match.group(1))
        else:
            booking_data["meta"]["nights"] = 1
    except Exception as e:
        print(f"⚠️ Yanolja Direct: Nights extraction error: {e}")
        booking_data["meta"]["nights"] = 1

    # --- Total Price ---
    # Template: "BOOKING AMOUNT $ 515.16 (USD)" or "BOOKING AMOUNT$ 515.16"
    try:
        price_match = re.search(r'BOOKING\s+AMOUNT\s*\$\s*([\d,.]+)', full_text)
        if price_match:
            clean_price = price_match.group(1).replace(',', '')
            booking_data["total_price"] = float(clean_price)
        else:
            # Fallback: try Grand Total from the Rates Details table
            grand_match = re.search(r'Grand\s+Total\s+([\d,.]+)', full_text)
            if grand_match:
                clean_price = grand_match.group(1).replace(',', '')
                booking_data["total_price"] = float(clean_price)
            else:
                booking_data["total_price"] = 0.0
    except (ValueError, AttributeError) as e:
        print(f"⚠️ Yanolja Direct: Total price extraction error: {e}")
        booking_data["total_price"] = 0.0

    # --- Room Details from HTML Table ---
    # The "Rooms Details" table has columns: Room Type | Guest(s) | No of rooms | ...
    # Each room row has bold room type name + "Description : ..." on next line
    try:
        room_details = []
        total_adults = 0
        total_children = 0

        # Search ALL <tr> elements in the document to find rows matching the room pattern.
        # This handles cases where rooms are in separate nested tables.
        all_rows = soup.find_all('tr')
        
        for row in all_rows:
            # Use recursive=False to strictly only get cells for this specific row
            cells = row.find_all(['td', 'th'], recursive=False)
            if len(cells) >= 3:
                room_type_text = cells[0].get_text(separator=' ', strip=True)
                guest_text = cells[1].get_text(separator=' ', strip=True)
                room_count_text = cells[2].get_text(separator=' ', strip=True)

                # Skip header row
                if 'Room Type' in room_type_text or 'Guest' in guest_text:
                    continue

                # Skip Description sub-rows
                if room_type_text.startswith('Description'):
                    continue

                # Parse room type (remove "Description : ..." if inline)
                room_type_clean = re.sub(r'Description\s*:.*', '', room_type_text).strip()
                if not room_type_clean:
                    continue

                # Parse guests: "2 adult & 0 child"
                adult_match = re.search(r'(\d+)\s*adult', guest_text, re.IGNORECASE)
                child_match = re.search(r'(\d+)\s*child', guest_text, re.IGNORECASE)
                
                # Parse room count from column 3 (may be "1", "2", etc)
                # Look for a clean digit or a string containing a digit
                num_rooms_match = re.search(r'(\d+)', room_count_text)
                num_rooms = int(num_rooms_match.group(1)) if num_rooms_match else 0

                # Valid room row must have guest info AND a positive room count
                if (adult_match or child_match) and num_rooms > 0:
                    adults = int(adult_match.group(1)) if adult_match else 2
                    children = int(child_match.group(1)) if child_match else 0

                    # Derive rate type from room type name
                    type_lower = room_type_clean.lower()
                    if 'bed & breakfast' in type_lower or 'breakfast' in type_lower:
                        rate = 'Bed & Breakfast'
                    elif 'half board' in type_lower:
                        rate = 'Half Board'
                    elif 'full board' in type_lower:
                        rate = 'Full Board'
                    else:
                        rate = 'Room Only'

                    total_adults += adults * num_rooms
                    total_children += children * num_rooms

                    for _ in range(num_rooms):
                        room_details.append({
                            'type': room_type_clean,
                            'rate': rate,
                            'guests': f"{adults} adult & {children} child",
                        })

        room_count = len(room_details) if room_details else 1
        booking_data["meta"]["imported_room_count"] = room_count
        booking_data["meta"]["room_count"] = room_count
        booking_data["adults"] = total_adults if total_adults > 0 else room_count * 2
        booking_data["children"] = total_children
        booking_data["room_details"] = room_details

    except Exception as e:
        print(f"⚠️ Yanolja Direct: Room details extraction error: {e}")
        booking_data["meta"]["imported_room_count"] = 1
        booking_data["meta"]["room_count"] = 1
        booking_data["adults"] = 2
        booking_data["children"] = 0
        booking_data["room_details"] = []

    return booking_data
