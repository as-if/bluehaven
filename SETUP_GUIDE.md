# Blue Haven Retreat — Guest Web Portal Setup Guide

This guide details how to configure, test, and deploy the Guest Web Portal (the main website + guest portal) for Blue Haven Retreat.

---

## 1. Local Testing (Zero-Config / Simulation Mode)

To make development and testing fast and self-contained, the application includes an **auto-fallback Simulation Mode**. 

If Firebase environment variables are missing, the app will run with a **local database** seeded directly inside your browser's `localStorage` and process natural language AI requests using a client-side NLP processor.

To test locally immediately:
```bash
cd blue_haven_web
npm run dev
```
Open `http://localhost:5173` in your browser. 
To log in to the Guest Portal, click the **Guest Portal** link in the navbar, and enter:
- **Booking ID**: `X96C-ALICE`
- **Last Name**: `Johnson`

*(You can now change breakfast options, log room cleanings, and chat with the AI widget—everything updates in real-time on your screen!)*

---

## 2. Setting Up Your Firebase Project

To connect the application to your production Firebase project, complete the following:

### Step A: Create Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project named **bluehaven-automation**.
2. Enable **Firestore Database** in production mode.
3. Enable **Firebase Authentication** and turn on the **Custom Token** provider (generated automatically by our cloud function).

### Step B: Database Collections Schema
Ensure the following collections exist in your Firestore Database:

1. **`bookings`** (Document ID should be the Booking ID, e.g., `B12345` or `X96C-ALICE`):
   ```json
   {
     "bookingId": "X96C-ALICE",
     "lastName": "Johnson",
     "guestName": "Alice Johnson",
     "roomNumber": "101",
     "checkIn": "2026-05-25",
     "checkOut": "2026-05-30",
     "status": "checked_in",
     "breakfastChoices": {
       "2026-05-26": "Continental",
       "2026-05-27": "Maldivian"
     }
   }
   ```
2. **`serviceRequests`** (Auto-generated Document IDs):
   ```json
   {
     "bookingId": "X96C-ALICE",
     "requestType": "cleaning", // "cleaning" | "towels" | "maintenance" | "activity"
     "description": "Please sweep sandy balcony floor",
     "status": "pending", // "pending" | "completed"
     "createdAt": "2026-05-26T18:00:00.000Z"
   }
   ```
3. **`tasks`** (Housekeeping schedule, Auto-generated Document IDs):
   ```json
   {
     "roomId": "101",
     "taskType": "Daily Cleaning",
     "status": "pending", // "pending" | "in_progress" | "completed"
     "created_at": "2026-05-26T08:00:00.000Z"
   }
   ```

---

## 3. Configuring Environment Variables

In the `blue_haven_web` directory, create a `.env` file:
```env
VITE_FIREBASE_API_KEY=your_firebase_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
VITE_FIREBASE_APP_ID=your_firebase_app_id

# Production API Endpoint (pointing to your deployed Cloud Functions)
VITE_API_BASE_URL=https://your-cloud-functions-region-your-project.cloudfunctions.net
```

---

## 4. Configuring AI Assistant API Keys & Deploying Functions

The AI assistant can call either **Google Gemini** (primary) or **DeepSeek** (alternative).

### Step A: Configure API Keys in Cloud Functions
To set up the API key, run these commands in the terminal using the Firebase CLI:

**For Gemini (Default):**
```bash
firebase functions:secrets:set GEMINI_API_KEY="your_google_gemini_api_key"
```

**For DeepSeek (Alternative):**
```bash
firebase functions:secrets:set DEEPSEEK_API_KEY="your_deepseek_api_key"
```
*(If the function detects the `DEEPSEEK_API_KEY` secret, it will automatically route all chat requests to DeepSeek's Open-AI compatible chat completion model instead of Gemini.)*

### Step B: Deploy Firebase Cloud Functions & Rules
From the main `blue-haven` directory, run:
```bash
# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy Cloud Functions
firebase deploy --only functions
```

---

## 5. Frontend Deployment

### Option A: Firebase Hosting (Recommended)
1. Initialize hosting:
   ```bash
   cd blue_haven_web
   npx firebase init hosting
   ```
   - Select your project.
   - Set public directory to `dist`.
   - Configure as single-page app (write `yes`).
2. Build and Deploy:
   ```bash
   npm run build
   firebase deploy --only hosting
   ```

### Option B: Vercel / Netlify
Simply import the repository, configure the Build Command to `npm run build` and the Publish Directory to `dist`. Remember to configure the Environment Variables in the provider's dashboard.
