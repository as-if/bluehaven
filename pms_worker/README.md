# Blue Haven PMS Browser Automation Worker

This worker automates the creation of direct website bookings inside the property PMS (eZee Absolute / iPMS / Yanolja Cloud Solution) using headless browser control (Selenium / Playwright).

---

## 1. Overview

When guests submit direct bookings on the Blue Haven website:
1. The web application verifies room availability in real time and writes the booking into Cloud Firestore with `pms_sync.status = "pending"`.
2. This worker discovers pending direct bookings.
3. The worker spins up a headless browser, navigates to the PMS interface, enters reservation and guest details, and confirms the booking.
4. The worker updates Firestore with `pms_sync.status = "synced"` and records the generated PMS reservation ID / voucher number.

---

## 2. Configuration (`.env`)

Create a `.env` file in this directory or export environment variables:

```env
# Firebase Project
FIREBASE_PROJECT_ID=bluehaven-automation
FIRESTORE_COLLECTION=bookings

# PMS Settings (eZee Absolute / iPMS)
PMS_HOTEL_CODE=bluehavenretreat
PMS_ENGINE_URL=https://live.ipms247.com/booking/book-rooms-bluehavenretreat

# Staff Backoffice Login (optional, for backoffice strategy)
PMS_PORTAL_URL=https://live.ipms247.com/pms
PMS_USERNAME=your_staff_username
PMS_PASSWORD=your_staff_password

# Automation Mode
AUTOMATION_STRATEGY=booking_engine   # "booking_engine" or "staff_backoffice"
BROWSER_HEADLESS=true
SYNC_INTERVAL_SECONDS=30
```

---

## 3. Running the Worker

### Single / Test Pass
Run a one-time check against pending bookings:
```bash
python3 pms_sync_worker.py --once
```

### Continuous Daemon Mode
Run continuously in the background:
```bash
python3 pms_sync_worker.py --interval 30
```

### Running the Test Script
To test browser control with a synthetic test booking payload without writing to Firestore:
```bash
python3 test_pms_sync.py
```
