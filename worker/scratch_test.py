from bs4 import BeautifulSoup
import re

def parse_rooms_robust(html_body):
    soup = BeautifulSoup(html_body, 'html.parser')
    
    # Let's find the header row
    header_th = soup.find(lambda tag: tag.name in ['th', 'td'] and 'Room Type' in tag.get_text(strip=True) and len(tag.get_text(strip=True)) < 30)
    
    if not header_th:
        return None
        
    real_tr = header_th.find_parent('tr')
    if not real_tr:
        return None
        
    real_table = real_tr.find_parent('table')
    if not real_table:
        return None
        
    tbody = real_table.find('tbody')
    rows = tbody.find_all('tr', recursive=False) if tbody else real_table.find_all('tr', recursive=False)
    
    room_details = []
    total_adults = 0
    total_children = 0
    
    for row in rows:
        cells = row.find_all(['td', 'th'], recursive=False)
        if len(cells) >= 3:
            room_type_text = cells[0].get_text(separator=' ', strip=True)
            guest_text = cells[1].get_text(separator=' ', strip=True)
            
            if 'Room Type' in room_type_text and 'Guest' in guest_text:
                continue
                
            if room_type_text.startswith('Description'):
                continue
                
            # If the room type is empty after stripping Description
            room_type_clean = re.sub(r'Description\s*:.*', '', room_type_text).strip()
            if not room_type_clean:
                continue
                
            adult_match = re.search(r'(\d+)\s*adult', guest_text, re.IGNORECASE)
            child_match = re.search(r'(\d+)\s*child', guest_text, re.IGNORECASE)
            
            # CRITICAL FIX: Only consider it a valid room row if we actually found "adult" or "child"
            # OR if it's clearly a room type (not a fallback of 2 adults for random rows)
            if adult_match or child_match:
                adults = int(adult_match.group(1)) if adult_match else 2
                children = int(child_match.group(1)) if child_match else 0
                
                total_adults += adults
                total_children += children
                
                room_details.append({
                    'type': room_type_clean,
                    'guests': f"{adults} adult & {children} child",
                })
            else:
                # If guest text has no "adult", it's probably NOT a room row, but if it is, maybe it's "2 Guests"?
                guest_match = re.search(r'(\d+)\s*guest', guest_text, re.IGNORECASE)
                if guest_match:
                    adults = int(guest_match.group(1))
                    total_adults += adults
                    room_details.append({
                        'type': room_type_clean,
                        'guests': f"{adults} adult & 0 child",
                    })

    return {
        'room_details': room_details,
        'adults': total_adults,
        'children': total_children,
        'room_count': len(room_details) if room_details else 1
    }
