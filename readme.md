# Blue Haven Retreat — Technical Ecosystem Documentation
Date: May 26, 2026 | Version: 1.2 | Author: Blue Haven Retreat Automation & Development Team

This document outlines the complete technical architecture and configuration of the Blue Haven Retreat booking, management, and guest interaction ecosystem.

---

## 1. System Overview

The Blue Haven Retreat software ecosystem comprises five main components designed to automate booking workflows, streamline internal resort operations, enhance guest interaction, and power the public website.

```mermaid
graph TD
    A[Gmail incoming booking email] -->|Pub/Sub Trigger| B[Cloud Function: gmail-worker]
    B -->|Parse & Store| C[(Cloud Firestore)]
    C <-->|Sync Bookings & Status| D[Blue Haven Ops App (Flutter)]
    C <-->|Sync Guest Data| E[Blue Haven Kiosk App (Flutter)]
    D <-->|WebRTC Video Support Calls| E
    F[Public Website (Static HTML)] -->|Information & Direct Booking| G[Guests]
```

### Components

1. **Booking Automation (Worker & Renewer)**:
   - **Trigger**: New booking emails (Agoda/Yanolja) arriving in Gmail.
   - **Filter**: Filtered via `API_Yanolja_Bookings` Gmail labels.
   - **Ingestion**: Dispatched to Cloud Pub/Sub (`gmail-reservation`).
   - **Processing**: The Cloud Function (`gmail-worker`) parses raw HTML/metadata and stores structured booking records in Firestore.
   - **Maintenance**: A Cloud Scheduler job hits `renew_gmail_watch` weekly to maintain the Gmail push token subscription.

2. **Blue Haven Operations App (`blue_haven_ops`)**:
   - **Platform**: Cross-platform Flutter (Android, iOS, macOS, Web, Windows).
   - **Target Users**: Resort managers, front-desk agents, kitchen, housekeeping, and maintenance teams.
   - **Capabilities**: Real-time calendar dashboard, booking updates, housekeeping checklists, kitchen queue management, finance tracking, and support call receiver.

3. **Blue Haven Guest Kiosk (`blue_haven_kiosk`)**:
   - **Platform**: Flutter application running on guest-facing tablet devices.
   - **Target Users**: Checked-in guests.
   - **Capabilities**: Interactive home screen, automated check-in details, AI Chatbot assistant (configured to answer guest questions like Wi-Fi credentials), and WebRTC direct calling to operations.

4. **Public Website (`bluehaven-web`)**:
   - **Platform**: High-performance static HTML/CSS site.
   - **Target Users**: Prospective guests.
   - **Capabilities**: Showcases resort details, room options, amenities, and guest reviews. Optimized using standard Google Fonts (Playfair Display & DM Sans) and HSL variables.

---

## 2. Project Structure

Ensure your local development folders are organized as follows:

```plaintext
developments/
├── blue-haven/                 # MAIN MONOREPO / BACKEND & MOBILE CODE
│   ├── blue_haven_ops/         # Flutter application for internal operations
│   ├── blue_haven_kiosk/       # Flutter tablet application for guest interaction
│   ├── functions/              # Firebase Cloud Functions (index.js, firestore.rules)
│   ├── worker/                 # Python worker that parses emails & writes to Firestore
│   │   ├── main.py             # Parser Cloud Function
│   │   ├── requirements.txt    # Python package dependencies
│   │   └── deploy_worker.py    # Deployment utility script
│   ├── renewer/                # Python helper to renew Gmail push subscriptions
│   │   ├── main.py             # Watch renewer HTTP Cloud Function
│   │   ├── requirements.txt    # Python package dependencies
│   │   └── deploy_renewer.py   # Deployment utility script
│   ├── scripts/                # Helper seeding & automation scripts
│   │   ├── get_token.py        # Authenticate with Gmail API
│   │   ├── activate_watch.py   # Set up first watch trigger
│   │   ├── force_strict_trigger.py # Force strict label filters
│   │   ├── reset_trigger.py    # Clean stop and restart watch
│   │   ├── setup_filter.py     # Create label & filter rules in Gmail
│   │   ├── switch_to_reservations.py # Transition watch to reservation topic
│   │   ├── seed_bookings.py    # Populate bookings collection
│   │   ├── seed_overlapping.py # Populate overlapping booking scenarios
│   │   └── seed_rooms.py       # Seed resort room configurations
│   ├── .firebaserc             # Firebase target environment file
│   ├── firebase.json           # Firebase CLI deployment config
│   └── readme.md               # (This document) Master Ecosystem Guide
│
└── bluehaven-web/              # SIBLING REPOSITORY
    └── index.html              # Static public website
```

---

## 3. Component Details & Setup

### A. Blue Haven Operations App (`blue_haven_ops`)
- **Main Technologies**: Flutter SDK `>=3.10.8 <4.0.0`, Dart, Riverpod (State Management), GoRouter (Navigation), Firebase Suite (Core, Auth, Firestore, Cloud Messaging).
- **Core Features**:
  - **Dashboard**: Real-time summary of check-ins, check-outs, and pending tasks.
  - **Calendar**: Syncfusion Calendar integration showing booking timelines and room assignments.
  - **Finance**: Visual charts (via `fl_chart`) representing revenue analytics and room occupancy rates.
  - **Housekeeping & Maintenance**: Interactive checklists synced to Firestore for staff.
  - **Support Calls**: WebRTC implementation (via `flutter_webrtc`) acting as the receiver for calls made from the guest kiosk.
  - **Reporting**: PDF generation (via `pdf` and `printing`) for invoices, check-in summaries, and reports.

### B. Blue Haven Guest Kiosk App (`blue_haven_kiosk`)
- **Main Technologies**: Flutter SDK `^3.10.8`, Dart, Riverpod, Firebase Core, Cloud Firestore, WebRTC.
- **Core Features**:
  - **Attract Loop Screen**: Welcoming screen that prompts guests to tap and interact.
  - **Guest Portal**: Displays basic guest information, room configuration, and check-out instructions.
  - **AI Guest Assistant**: Chat interface answering common queries such as:
    - *Wi-Fi Name*: `BlueHaven_Guest`
    - *Wi-Fi Password*: `escape2paradise`
  - **WebRTC Emergency Caller**: One-touch video/audio call trigger allowing guests to connect instantly with staff carrying the Operations app.

### C. Public Website (`bluehaven-web`)
- **Main Technologies**: Semantic HTML5, Vanilla CSS3 (Custom design system/variables).
- **Core Features**:
  - Responsive layouts utilizing CSS flexbox/grid.
  - Luxury styling variables (Teal, Navy, Sand, Gold) and custom fonts (Playfair Display & DM Sans).
  - Static optimization requiring no heavy build pipelines or runtime servers.

---

## 4. Python Automation & Management Scripts

These utilities reside in the `scripts/` directory and manage API access, Gmail push subscriptions, and Firestore seeding.

### Authentication & Token Generation
- **`scripts/get_token.py`**: Interactively opens a local server to complete the Gmail API OAuth flow. Saves the generated refresh token locally to `token.json` in the root directory (so it can be shared by the deployment scripts).
  - *Usage*: `python3 scripts/get_token.py`

### Gmail Watch & Trigger Management
- **`scripts/setup_filter.py`**: Dynamically creates the `API_Yanolja_Bookings` label in Gmail, creates filter rules to automatically label inbound emails from `notifications@yanoljacloudsolution.com`, and begins watch subscriptions.
  - *Usage*: `python3 scripts/setup_filter.py`
- **`scripts/activate_watch.py`**: Initializes the Gmail API Watch trigger on the topic `projects/bluehaven-automation/topics/gmail-incoming`.
  - *Usage*: `python3 scripts/activate_watch.py`
- **`scripts/force_strict_trigger.py`**: Restarts the Gmail API Watch subscription, ensuring the strict filtering parameters (`labelIds` and `labelFilterAction: include`) are active.
  - *Usage*: `python3 scripts/force_strict_trigger.py`
- **`scripts/reset_trigger.py`**: Silences existing watch subscriptions and initiates a fresh start.
  - *Usage*: `python3 scripts/reset_trigger.py`
- **`scripts/switch_to_reservations.py`**: Transitions watch subscriptions to point to the production topic `projects/bluehaven-automation/topics/gmail-reservation`.
  - *Usage*: `python3 scripts/switch_to_reservations.py`

### Database Seeding
- **`scripts/seed_rooms.py`**: Seeds Firestore with the physical room details (Room numbers, categories).
  - *Usage*: `python3 scripts/seed_rooms.py`
- **`scripts/seed_bookings.py`**: Seeds Firestore with synthetic test bookings to verify front-desk layouts.
  - *Usage*: `python3 scripts/seed_bookings.py`
- **`scripts/seed_overlapping.py`**: Seeds overlapping bookings to test double-booking warnings or UI collision checks.
  - *Usage*: `python3 scripts/seed_overlapping.py`

---

## 5. Data Schema (Firestore)

Documents inside the `bookings` collection follow the format below:

**Document ID**: `[Booking Ref]`

```json
{
  "booking_ref": "X96C96986F27A",
  "guest_name": "Maisy Bennett-Day",
  "channel": "Booking.com (10658103)",
  "voucher_no": "5500404280",
  "status": "Confirmed",
  "check_in": "08-02-2026",
  "check_out": "11-02-2026",
  "total_price": "$ 235.22",
  "received_at": "2026-02-07T13:06:19Z",
  "rooms": [
    {
      "type": "Deluxe Triple Room (1065810304)",
      "rate": "Room Only (61098091)"
    }
  ],
  "meta": {
    "adults": 2,
    "children": 0,
    "nights": 3,
    "room_count": 1
  }
}
```

---

## 6. Operational Commands

### Deploying Updates
To update the Worker (parsing logic):
```bash
cd ~/developments/blue-haven/worker
python3 deploy_worker.py
```

To update the Renewer (subscription renewal):
```bash
cd ~/developments/blue-haven/renewer
python3 deploy_renewer.py
```

### Monitoring
- **Logs**: Google Cloud Console > Functions > Logs
- **Database**: Google Cloud Console > Firestore
- **Web App**: Run the Flutter apps in debug mode:
  ```bash
  flutter run
  ```