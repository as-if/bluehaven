import os
import pickle
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

# --- CONFIGURATION ---
# Check your Google Cloud Console if you aren't sure about the topic name!
TOPIC = 'projects/bluehaven-automation/topics/gmail-incoming'
LABEL_NAME = 'API_Yanolja_Bookings'

# We include the 'spreadsheets' scope just to reuse your existing token easily
SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.labels',
    'https://www.googleapis.com/auth/gmail.settings.basic',
    'https://www.googleapis.com/auth/spreadsheets'
]

def get_creds():
    creds = None
    # 1. Try loading from token.json (standard)
    if os.path.exists('../token.json'):
        creds = Credentials.from_authorized_user_file('../token.json', SCOPES)
    # 2. Try loading from token.pickle (legacy)
    elif os.path.exists('../token.pickle'):
        with open('../token.pickle', 'rb') as token:
            creds = pickle.load(token)
    
    # 3. If invalid, log in again
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
            except Exception:
                print("Token expired and refresh failed. Please delete token.json and login again.")
                return None
        else:
            if not os.path.exists('../credentials.json'):
                print("CRITICAL: 'credentials.json' missing. Download it from Cloud Console.")
                return None
            flow = InstalledAppFlow.from_client_secrets_file('../credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
            
            # Save the new token
            with open('../token.json', 'w') as token:
                token.write(creds.to_json())
    return creds

def main():
    print("--- GMAIL TRIGGER CONFIGURATOR ---")
    creds = get_creds()
    if not creds: return

    service = build('gmail', 'v1', credentials=creds)

    # 1. STOP EVERYTHING (The "Nuclear" Option)
    print("\n[1/3] Stopping ALL existing notifications...")
    try:
        service.users().stop(userId='me').execute()
        print("   >>> SUCCESS: Gmail is now silent. No triggers exist.")
    except Exception as e:
        print(f"   >>> Note: Stop command ignored (maybe none existed): {e}")

    # 2. FIND LABEL ID
    print(f"\n[2/3] Finding strict ID for label: '{LABEL_NAME}'...")
    results = service.users().labels().list(userId='me').execute()
    labels = results.get('labels', [])
    
    label_id = None
    for l in labels:
        if l['name'] == LABEL_NAME:
            label_id = l['id']
            break
    
    if not label_id:
        print(f"   >>> CRITICAL ERROR: Label '{LABEL_NAME}' not found in your Gmail.")
        print("   >>> Please create the label in Gmail and run this again.")
        return
    print(f"   >>> Found Label ID: {label_id}")

    # 3. START STRICT WATCH
    print("\n[3/3] Sending STRICT 'Include-Only' command to Gmail...")
    request_body = {
        'topicName': TOPIC,
        'labelIds': [label_id],        # The specific label ID
        'labelFilterAction': 'include' # Crucial: ONLY send if label matches
    }

    try:
        response = service.users().watch(userId='me', body=request_body).execute()
        print("\n------------------------------------------------")
        print("✅ SUCCESS! FILTER IS ACTIVE.")
        print(f"   - History ID: {response['historyId']}")
        print(f"   - Expiration: {response['expiration']}")
        print("------------------------------------------------")
        print("Gmail will now ONLY notify Pub/Sub for emails with this specific label.")
        print("Unlabeled emails will NOT trigger the Cloud Function anymore.")
        
    except Exception as e:
        print(f"\n❌ FAILED: {e}")
        print("Check if 'projects/bluehaven-automation/topics/gmail-incoming' actually exists in Cloud Console.")

if __name__ == '__main__':
    main()