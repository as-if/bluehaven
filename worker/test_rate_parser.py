"""
Unit test for yanolja_rate_parser.py using the exact HTML table structure
from the Yanolja PMS email ('Update Log for Rates , Hotel Code : 53568').
"""

from parsers.yanolja_rate_parser import parse_yanolja_rate_update, parse_date_string, map_rate_plan_to_room_category

SAMPLE_HTML = """
<html>
<body>
<table border="1" cellpadding="5" cellspacing="0">
  <thead>
    <tr>
      <th>Updated By (User)</th>
      <th>Rate Plan</th>
      <th>Updated For Source</th>
      <th>Date</th>
      <th>Time</th>
      <th>Server Address</th>
      <th>Remote Address</th>
      <th>Updated for Date</th>
      <th colspan="2">Base Rate</th>
    </tr>
    <tr>
      <th colspan="8"></th>
      <th>OLD</th>
      <th>NEW</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>admin</td>
      <td>Deluxe Double Room Direct-Bed & Breakfast</td>
      <td><a href="https://bluehaven.mv">bluehaven.mv - WEB</a></td>
      <td>2026-09-14</td>
      <td>14:25:09</td>
      <td>10.0.4.187</td>
      <td>69.94.94.83</td>
      <td>14th September 2026</td>
      <td>65.00</td>
      <td>41.181</td>
    </tr>
    <tr>
      <td>admin</td>
      <td>Deluxe Double Room Direct-Bed & Breakfast</td>
      <td><a href="https://bluehaven.mv">bluehaven.mv - WEB</a></td>
      <td>2026-09-14</td>
      <td>14:25:09</td>
      <td>10.0.4.187</td>
      <td>69.94.94.83</td>
      <td>15th September 2026</td>
      <td>65.00</td>
      <td>41.181</td>
    </tr>
    <tr>
      <td>admin</td>
      <td>Deluxe Double Room Direct-Bed & Breakfast</td>
      <td><a href="https://bluehaven.mv">bluehaven.mv - WEB</a></td>
      <td>2026-09-14</td>
      <td>14:25:09</td>
      <td>10.0.4.187</td>
      <td>69.94.94.83</td>
      <td>16th September 2026</td>
      <td>65.00</td>
      <td>41.181</td>
    </tr>
    <!-- Repeating table header in email as shown in screenshot -->
    <tr>
      <th>Updated By (User)</th>
      <th>Rate Plan</th>
      <th>Updated For Source</th>
      <th>Date</th>
      <th>Time</th>
      <th>Server Address</th>
      <th>Remote Address</th>
      <th>Updated for Date</th>
      <th>OLD</th>
      <th>NEW</th>
    </tr>
    <tr>
      <td>admin</td>
      <td>Deluxe Falmily Room - Bed & Breakfast</td>
      <td><a href="https://bluehaven.mv">bluehaven.mv - WEB</a></td>
      <td>2026-09-14</td>
      <td>14:25:10</td>
      <td>10.0.4.187</td>
      <td>69.94.94.83</td>
      <td>14th September 2026</td>
      <td>75.00</td>
      <td>59.0521</td>
    </tr>
    <tr>
      <td>admin</td>
      <td>Deluxe Falmily Room - Bed & Breakfast</td>
      <td><a href="https://bluehaven.mv">bluehaven.mv - WEB</a></td>
      <td>2026-09-14</td>
      <td>14:25:10</td>
      <td>10.0.4.187</td>
      <td>69.94.94.83</td>
      <td>15th September 2026</td>
      <td>75.00</td>
      <td>59.0521</td>
    </tr>
  </tbody>
</table>
</body>
</html>
"""

def test_date_parser():
    assert parse_date_string("14th September 2026") == "2026-09-14"
    assert parse_date_string("1st October 2026") == "2026-10-01"
    assert parse_date_string("2nd May 2026") == "2026-05-02"
    assert parse_date_string("3rd June 2026") == "2026-06-03"
    assert parse_date_string("2026-09-14") == "2026-09-14"
    print("✅ Date parsing tests passed.")

def test_category_mapping():
    cat, name = map_rate_plan_to_room_category("Deluxe Double Room Direct-Bed & Breakfast")
    assert cat == "double" and name == "Deluxe Double Room"

    cat, name = map_rate_plan_to_room_category("Deluxe Falmily Room - Bed & Breakfast")
    assert cat == "family" and name == "Deluxe Family Room"

    cat, name = map_rate_plan_to_room_category("Deluxe Triple Room Direct-Bed & Breakfast")
    assert cat == "triple" and name == "Deluxe Triple Room"
    print("✅ Category mapping tests passed.")

def test_rate_parser():
    results = parse_yanolja_rate_update(SAMPLE_HTML, "Update Log for Rates , Hotel Code : 53568")
    print(f"Total parsed rates: {len(results)}")
    for r in results:
        print(f"  {r['room_category_id']} ({r['target_date']}): old={r['base_rate_old']}, new={r['base_rate_new']}, price={r['price']}, source={r['source']}")

    assert len(results) == 5, f"Expected 5 parsed rows, got {len(results)}"

    # Check first row (Double Room, 2026-09-14)
    r0 = results[0]
    assert r0['room_category_id'] == 'double'
    assert r0['target_date'] == '2026-09-14'
    assert r0['base_rate_old'] == 65.00
    assert r0['base_rate_new'] == 41.181
    assert r0['price'] == 41.18
    assert 'bluehaven.mv - WEB' in r0['source']

    # Check family room (Deluxe Falmily Room, 2026-09-14)
    r3 = results[3]
    assert r3['room_category_id'] == 'family'
    assert r3['target_date'] == '2026-09-14'
    assert r3['base_rate_old'] == 75.00
    assert r3['base_rate_new'] == 59.0521
    assert r3['price'] == 59.05
    assert 'bluehaven.mv - WEB' in r3['source']

    print("✅ Full email rate parsing tests passed successfully!")

def test_triple_and_custom_dates():
    html = """
    <table>
      <tr>
        <th>Updated By (User)</th><th>Rate Plan</th><th>Updated For Source</th>
        <th>Date</th><th>Time</th><th>Server Address</th><th>Remote Address</th>
        <th>Updated for Date</th><th>OLD</th><th>NEW</th>
      </tr>
      <tr>
        <td>admin</td><td>Deluxe Triple Room Direct-Bed & Breakfast</td><td>bluehaven.mv - WEB</td>
        <td>2026-09-14</td><td>14:30:00</td><td>10.0.4.187</td><td>69.94.94.83</td>
        <td>21st September 2026</td><td>80.00</td><td>68.50</td>
      </tr>
    </table>
    """
    res = parse_yanolja_rate_update(html, "Update Log for Rates")
    assert len(res) == 1
    assert res[0]['room_category_id'] == 'triple'
    assert res[0]['target_date'] == '2026-09-21'
    assert res[0]['price'] == 68.50
    print("✅ Triple room and custom date test passed.")

if __name__ == '__main__':
    test_date_parser()
    test_category_mapping()
    test_rate_parser()
    test_triple_and_custom_dates()
