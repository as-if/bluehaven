"""
Parser for PMS Room Rate Update emails from Yanolja Cloud Solution (Hotel Code: 53568).

These emails arrive with subjects like:
"Update Log for Rates , Hotel Code : 53568"
and contain an HTML table logging date-by-date base rate modifications.
"""

import re
import datetime
from bs4 import BeautifulSoup


def parse_date_string(raw_date_str):
    """
    Parses dates like '14th September 2026', '1st Oct 2026', '2026-09-14', etc.
    Returns ISO date string 'YYYY-MM-DD' or None.
    """
    if not raw_date_str:
        return None

    cleaned = " ".join(raw_date_str.replace('\xa0', ' ').split()).strip()
    if not cleaned or cleaned.upper() == "N/A":
        return None

    # Remove ordinal suffixes: 1st -> 1, 2nd -> 2, 3rd -> 3, 14th -> 14
    cleaned = re.sub(r'(\d+)(st|nd|rd|th)', r'\1', cleaned, flags=re.IGNORECASE)

    date_formats = [
        "%d %B %Y",   # 14 September 2026
        "%d %b %Y",   # 14 Sep 2026
        "%Y-%m-%d",   # 2026-09-14
        "%d-%m-%Y",   # 14-09-2026
        "%d/%m/%Y",   # 14/09/2026
        "%B %d, %Y",  # September 14, 2026
    ]

    for fmt in date_formats:
        try:
            dt = datetime.datetime.strptime(cleaned, fmt)
            return dt.strftime("%Y-%m-%d")
        except ValueError:
            continue

    print(f"⚠️ Could not parse rate date: '{raw_date_str}' (cleaned: '{cleaned}')")
    return None


def parse_rate_float(rate_val):
    """
    Converts a rate string like '41.181' or '$ 65.00' to a float.
    Returns 0.0 on failure.
    """
    if rate_val is None:
        return 0.0
    clean_str = re.sub(r'[^\d.]', '', str(rate_val).strip())
    try:
        return float(clean_str)
    except (ValueError, TypeError):
        return 0.0


def map_rate_plan_to_room_category(rate_plan_str):
    """
    Maps rate plan names to Blue Haven room categories:
    - 'family' (Deluxe Family Room)
    - 'triple' (Deluxe Triple Room)
    - 'double' (Deluxe Double Room)
    """
    if not rate_plan_str:
        return None, "Unknown"

    name_lower = rate_plan_str.lower()

    # Note: PMS contains a known typo 'Falmily' in 'Deluxe Falmily Room - Bed & Breakfast'
    if 'falmily' in name_lower or 'family' in name_lower:
        return 'family', 'Deluxe Family Room'
    elif 'triple' in name_lower:
        return 'triple', 'Deluxe Triple Room'
    elif 'double' in name_lower:
        return 'double', 'Deluxe Double Room'

    return None, rate_plan_str.strip()


def parse_yanolja_rate_update(html_body, subject=""):
    """
    Parses the HTML email body from Yanolja 'Update Log for Rates'.

    Returns a list of dicts:
    [
        {
            "rate_plan": str,
            "room_category_id": str ("double"|"triple"|"family"),
            "room_name": str,
            "source": str,
            "target_date": str ("YYYY-MM-DD"),
            "base_rate_old": float,
            "base_rate_new": float,
            "price": float (rounded to 2 decimal places),
            "updated_by": str,
            "log_date": str,
            "log_time": str,
            "server_address": str,
            "remote_address": str,
        },
        ...
    ]
    """
    if not html_body:
        return []

    soup = BeautifulSoup(html_body, 'html.parser')
    tables = soup.find_all('table')

    parsed_rates = []

    for table in tables:
        rows = table.find_all('tr')
        if not rows:
            continue

        # Check if this table is the rate update log table
        table_text = table.get_text(separator=' ', strip=True).lower()
        if not ('rate plan' in table_text and ('updated for date' in table_text or 'base rate' in table_text)):
            continue

        col_indices = {
            'updated_by': None,
            'rate_plan': None,
            'source': None,
            'log_date': None,
            'log_time': None,
            'server_address': None,
            'remote_address': None,
            'target_date': None,
            'base_rate_old': None,
            'base_rate_new': None,
        }

        for row in rows:
            cells = row.find_all(['th', 'td'], recursive=False)
            cell_texts = [" ".join(c.get_text().split()).strip() for c in cells]
            lower_texts = [t.lower() for t in cell_texts]

            # Detect main header row with full columns
            if any('rate plan' in t for t in lower_texts):
                for idx, t in enumerate(lower_texts):
                    if 'updated by' in t or 'user' in t:
                        col_indices['updated_by'] = idx
                    elif 'rate plan' in t:
                        col_indices['rate_plan'] = idx
                    elif 'updated for source' in t or 'source' in t:
                        col_indices['source'] = idx
                    elif t == 'date' or ('date' in t and 'updated for date' not in t):
                        col_indices['log_date'] = idx
                    elif 'time' in t:
                        col_indices['log_time'] = idx
                    elif 'server' in t:
                        col_indices['server_address'] = idx
                    elif 'remote' in t:
                        col_indices['remote_address'] = idx
                    elif 'updated for date' in t:
                        col_indices['target_date'] = idx
                    elif 'old' in t:
                        col_indices['base_rate_old'] = idx
                    elif 'new' in t:
                        col_indices['base_rate_new'] = idx
                continue

            # Detect standalone sub-header row (e.g. OLD and NEW under Base Rate with colspan)
            if any(t == 'old' for t in lower_texts) and any(t == 'new' for t in lower_texts):
                # If this row is a short sub-header row (e.g. 2 or 3 cells due to colspan),
                # don't assign low index numbers to OLD/NEW. They belong at the end of the full row.
                if len(cells) >= 8:
                    for idx, t in enumerate(lower_texts):
                        if t == 'old':
                            col_indices['base_rate_old'] = idx
                        elif t == 'new':
                            col_indices['base_rate_new'] = idx
                continue

            # Skip repeating header rows or empty rows
            if not cell_texts or any(kw in lower_texts[0] for kw in ['updated by', 'rate plan', 'base rate']):
                continue

            # Skip row if it looks like a header or divider
            if any('rate plan' in t for t in lower_texts):
                continue

            # Must have at least 8 cells to be a rate data row
            num_cells = len(cells)
            if num_cells < 8:
                continue

            # Helper to get cell text by detected column index or positional fallback
            def get_cell(key, fallback_idx):
                idx = col_indices.get(key)
                if idx is not None and idx < num_cells:
                    return cell_texts[idx]
                if fallback_idx < num_cells:
                    return cell_texts[fallback_idx]
                return ""

            # Dynamic extraction based on row structure:
            # When row has 10 cells (standard Yanolja layout):
            # 0: User, 1: Rate Plan, 2: Source, 3: Date, 4: Time, 5: Server, 6: Remote, 7: Target Date, 8: OLD, 9: NEW
            # The target date is reliably at index 7 (or detected index).
            # The rates are reliably the last two cells (OLD at -2, NEW at -1).
            updated_by = get_cell('updated_by', 0)
            rate_plan = get_cell('rate_plan', 1)
            source = get_cell('source', 2)
            log_date = get_cell('log_date', 3)
            log_time = get_cell('log_time', 4)
            server_addr = get_cell('server_address', 5)
            remote_addr = get_cell('remote_address', 6)

            # Target date is at detected index or index 7
            target_date_idx = col_indices.get('target_date') if (col_indices.get('target_date') is not None and col_indices['target_date'] < num_cells - 1) else (num_cells - 3 if num_cells >= 10 else num_cells - 2)
            target_date_raw = cell_texts[target_date_idx]

            # OLD & NEW are the trailing columns
            rate_old_raw = cell_texts[num_cells - 2]
            rate_new_raw = cell_texts[num_cells - 1]

            target_date = parse_date_string(target_date_raw)
            if not target_date:
                # If target date failed, try checking cell before it or after
                for offset in [-1, 1]:
                    cand_idx = target_date_idx + offset
                    if 0 <= cand_idx < num_cells - 2:
                        cand_date = parse_date_string(cell_texts[cand_idx])
                        if cand_date:
                            target_date = cand_date
                            break

            if not target_date:
                continue

            base_rate_new = parse_rate_float(rate_new_raw)
            base_rate_old = parse_rate_float(rate_old_raw)

            category_id, room_name = map_rate_plan_to_room_category(rate_plan)
            if not category_id:
                print(f"⚠️ Unrecognized room category for rate plan '{rate_plan}'")

            parsed_rates.append({
                "rate_plan": rate_plan,
                "room_category_id": category_id,
                "room_name": room_name,
                "source": source,
                "target_date": target_date,
                "base_rate_old": base_rate_old,
                "base_rate_new": base_rate_new,
                "price": round(base_rate_new, 2),
                "updated_by": updated_by,
                "log_date": log_date,
                "log_time": log_time,
                "server_address": server_addr,
                "remote_address": remote_addr,
            })

    return parsed_rates
