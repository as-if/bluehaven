from bs4 import BeautifulSoup
import re

def parse_yanolja_direct_booking_logic_v2(html_body):
    soup = BeautifulSoup(html_body, 'html.parser')
    room_details = []
    total_adults = 0
    total_children = 0

    # Strategy: Find all <tr> tags in the whole document and see if they match the room row pattern
    # The pattern is: [Room Type, Guests (X adult & Y child), Room Count (Z)]
    all_rows = soup.find_all('tr')
    print(f"Total <tr> found: {len(all_rows)}")
    
    for i, row in enumerate(all_rows):
        # We don't use recursive=False here because we are looking at all <tr> tags already
        cells = row.find_all(['td', 'th'], recursive=False)
        if len(cells) < 3:
            continue
            
        room_type_text = cells[0].get_text(separator=' ', strip=True)
        guest_text = cells[1].get_text(separator=' ', strip=True)
        room_count_text = cells[2].get_text(separator=' ', strip=True)
        
        # Skip headers
        if 'Room Type' in room_type_text or 'Guest' in guest_text:
            continue
            
        # Skip descriptions
        if room_type_text.startswith('Description'):
            continue

        # Look for guest pattern
        adult_match = re.search(r'(\d+)\s*adult', guest_text, re.IGNORECASE)
        child_match = re.search(r'(\d+)\s*child', guest_text, re.IGNORECASE)
        
        # Look for room count digit
        num_rooms_match = re.search(r'^(\d+)$', room_count_text.strip())
        num_rooms = int(num_rooms_match.group(1)) if num_rooms_match else 0
        
        if (adult_match or child_match) and num_rooms > 0:
            print(f"Match found in row {i}: {room_type_text}")
            room_type_clean = re.sub(r'Description\s*:.*', '', room_type_text).strip()
            
            adults = int(adult_match.group(1)) if adult_match else 0
            children = int(child_match.group(1)) if child_match else 0
            
            # Identify rate
            type_lower = room_type_clean.lower()
            if 'bed & breakfast' in type_lower or 'breakfast' in type_lower:
                rate = 'Bed & Breakfast'
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

    return room_details, total_adults

# Nested table structure simulation
html = """
<table> <!-- Outer table -->
  <tr>
    <td>
      <table> <!-- Header table -->
        <tr><th>Room Type</th><th>Guest(s)</th><th>No of rooms</th></tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table> <!-- Room 1 table -->
        <tr><td>Deluxe Room</td><td>3 adult</td><td>1</td></tr>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table> <!-- Room 2 table -->
        <tr><td>Deluxe Room</td><td>3 adult</td><td>1</td></tr>
      </table>
    </td>
  </tr>
</table>
"""

details, adults = parse_yanolja_direct_booking_logic_v2(html)
print("\nFINAL RESULT:")
print(f"Room details count: {len(details)}")
print(f"Total adults: {adults}")
