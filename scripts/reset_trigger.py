from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
import os

# --- CONFIGURATION ---
TOPIC = 'projects/bluehaven-automation/topics/gmail-incoming'
LABEL_NAME = 'API_Yanolja_Bookings'
SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.labels',
    'https://www.googleapis.com/auth/gmail.settings.basic'
]

def get_creds():
    # Helper to handle the token loading automatically
    if os.path.exists('../token.json'):
        return Credentials.from_authorized_user_file('../token.json', SCOPES)
    elif os.path.exists('../token.pickle'):
        # Handle legacy pickle files if they exist
        import pickle
        with open('../token.pickle', 'rb') as token:
            return pickle.load(token)
    else:
        print("CRITICAL: No token found. Please run get_token.py first!")
        exit()

def main():
    creds = get_creds()
    if not creds.valid:
        creds.refresh(Request())
    
    service = build('gmail', 'v1', credentials=creds)

    print("1. Stopping old (noisy) trigger...")
    try:
        service.users().stop(userId='me').execute()
        print("   > Old trigger STOPPED. Gmail is now silent.")
    except Exception as e:
        print(f"   > Warning (can ignore): {e}")

    print(f"2. Finding Label ID for '{LABEL_NAME}'...")
    results = service.users().labels().list(userId='me').execute()
    labels = results.get('labels', [])
    
    label_id = None
    for l in labels:
        if l['name'] == LABEL_NAME:
            label_id = l['id']
            break
    
    if not label_id:
        print(f"ERROR: Label '{LABEL_NAME}' not found in your Gmail!")
        return

    print(f"   > Found Label ID: {label_id}")

    print("3. Starting NEW strict trigger...")
    request_body = {
        'topicName': TOPIC,
        'labelIds': [label_id],       # <--- THIS IS THE KEY FILTER
        'labelFilterAction': 'include' # <--- ONLY send if this label matches
    }

    response = service.users().watch(userId='me', body=request_body).execute()
    
    print("\nSUCCESS! New trigger is live.")
    print(f"Expiration: {response['expiration']}")
    print("Your Cloud Function will now ONLY wake up for 'API_Yanolja_Bookings' emails.")

if __name__ == '__main__':
    main()