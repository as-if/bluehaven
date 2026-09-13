from bs4 import BeautifulSoup
import re

def parse_yanolja_direct_booking_logic(html_body):
    soup = BeautifulSoup(html_body, 'html.parser')
    room_details = []
    total_adults = 0
    total_children = 0

    header_th = soup.find(lambda tag: tag.name in ['th', 'td'] and 'Room Type' in tag.get_text(strip=True) and len(tag.get_text(strip=True)) < 30)
    
    rooms_table = None
    if header_th:
        real_tr = header_th.find_parent('tr')
        if real_tr:
            rooms_table = real_tr.find_parent('table')

    if rooms_table:
        tbody = rooms_table.find('tbody')
        rows = tbody.find_all('tr', recursive=False) if tbody else rooms_table.find_all('tr', recursive=False)
        
        print(f"Found {len(rows)} rows in table")
        
        for i, row in enumerate(rows):
            cells = row.find_all(['td', 'th'], recursive=False)
            print(f"Row {i}: {len(cells)} cells")
            if len(cells) >= 3:
                room_type_text = cells[0].get_text(separator=' ', strip=True)
                guest_text = cells[1].get_text(separator=' ', strip=True)
                room_count_text = cells[2].get_text(separator=' ', strip=True)
                
                print(f"  Room Type Text: '{room_type_text}'")
                print(f"  Guest Text: '{guest_text}'")
                print(f"  Room Count Text: '{room_count_text}'")

                if 'Room Type' in room_type_text and 'Guest' in guest_text:
                    print("  Skipping header row")
                    continue

                if room_type_text.startswith('Description'):
                    print("  Skipping description row")
                    continue

                room_type_clean = re.sub(r'Description\s*:.*', '', room_type_text).strip()
                if not room_type_clean:
                    print("  Empty room type clean, skipping")
                    continue

                adult_match = re.search(r'(\d+)\s*adult', guest_text, re.IGNORECASE)
                child_match = re.search(r'(\d+)\s*child', guest_text, re.IGNORECASE)
                
                num_rooms = int(room_count_text) if room_count_text.isdigit() else 1
                print(f"  Num Rooms parsed: {num_rooms}")

                if adult_match or child_match or num_rooms > 0:
                    adults = int(adult_match.group(1)) if adult_match else 2
                    children = int(child_match.group(1)) if child_match else 0

                    total_adults += adults * num_rooms
                    total_children += children * num_rooms

                    for _ in range(num_rooms):
                        room_details.append({
                            'type': room_type_clean,
                            'guests': f"{adults} adult & {children} child",
                        })
                    print(f"  Added {num_rooms} room(s). Total rooms so far: {len(room_details)}")

    return room_details, total_adults

# Simulated HTML based on the PDF screenshot
html = """
<table>
    <thead>
        <tr>
            <th>Room Type</th>
            <th>Guest(s)</th>
            <th>No of rooms</th>
            <th>Package</th>
            <th>Promotion</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Deluxe Double Room - Bed & Breakfast</td>
            <td>3 adult & 0 child</td>
            <td>1</td>
            <td>None</td>
            <td>None</td>
        </tr>
        <tr>
            <td>Description : Deluxe Double Room - Bed & Breakfast</td>
            <td colspan="4"></td>
        </tr>
        <tr>
            <td>Deluxe Double Room - Bed & Breakfast</td>
            <td>3 adult & 0 child</td>
            <td>1</td>
            <td>None</td>
            <td>None</td>
        </tr>
        <tr>
            <td>Description : Deluxe Double Room - Bed & Breakfast</td>
            <td colspan="4"></td>
        </tr>
    </tbody>
</table>
"""

details, adults = parse_yanolja_direct_booking_logic(html)
print("\nFINAL RESULT:")
print(f"Room details count: {len(details)}")
print(f"Total adults: {adults}")
