import os
import pickle
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

# --- CONFIGURATION ---
# NEW TOPIC NAME
NEW_TOPIC = 'projects/bluehaven-automation/topics/gmail-reservation'
LABEL_NAME = 'API_Yanolja_Bookings'

SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.labels',
    'https://www.googleapis.com/auth/gmail.settings.basic',
    'https://www.googleapis.com/auth/spreadsheets'
]

def get_creds():
    creds = None
    if os.path.exists('../token.json'):
        creds = Credentials.from_authorized_user_file('../token.json', SCOPES)
    elif os.path.exists('../token.pickle'):
        with open('../token.pickle', 'rb') as token:
            creds = pickle.load(token)
    
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file('../credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
            with open('../token.json', 'w') as token:
                token.write(creds.to_json())
    return creds

def main():
    print("--- SWITCHING TO TOPIC: GMAIL-RESERVATION ---")
    creds = get_creds()
    service = build('gmail', 'v1', credentials=creds)

    # 1. STOP OLD TRIGGERS
    print("\n[1/3] Stopping old triggers...")
    try:
        service.users().stop(userId='me').execute()
        print("   >>> Old triggers stopped.")
    except Exception as e:
        print(f"   >>> (Ignored): {e}")

    # 2. FIND LABEL ID
    print(f"\n[2/3] Finding ID for label: '{LABEL_NAME}'...")
    results = service.users().labels().list(userId='me').execute()
    labels = results.get('labels', [])
    
    label_id = None
    for l in labels:
        if l['name'] == LABEL_NAME:
            label_id = l['id']
            break
    
    if not label_id:
        print(f"   >>> ERROR: Label '{LABEL_NAME}' not found.")
        return
    print(f"   >>> Label ID: {label_id}")

    # 3. START NEW WATCH
    print(f"\n[3/3] Connecting to {NEW_TOPIC}...")
    request_body = {
        'topicName': NEW_TOPIC,
        'labelIds': [label_id],
        'labelFilterAction': 'include'
    }

    try:
        response = service.users().watch(userId='me', body=request_body).execute()
        print("\n✅ SUCCESS! CONNECTED TO GMAIL-RESERVATION.")
        print(f"   - History ID: {response['historyId']}")
        print(f"   - Expiration: {response['expiration']}")
        print("   - Filter: STRICT (Label Only)")
    except Exception as e:
        print(f"\n❌ FAILED: {e}")
        print("Did you run the 'gcloud pubsub topics add-iam-policy-binding' command?")

if __name__ == '__main__':
    main()