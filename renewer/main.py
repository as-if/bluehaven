import os
import functions_framework
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# --- CONFIGURATION FROM ENV VARS ---
CLIENT_ID = os.environ.get('CLIENT_ID')
CLIENT_SECRET = os.environ.get('CLIENT_SECRET')
REFRESH_TOKEN = os.environ.get('REFRESH_TOKEN')
TOPIC_NAME = 'projects/bluehaven-automation/topics/gmail-reservation' # The new topic
LABEL_NAMES = ['API_Yanolja_Bookings', 'API_Yanolja_Rates']

def get_creds():
    """Generates credentials from Env Vars (No local files needed)."""
    creds = Credentials(
        None, # No access token needed initially
        refresh_token=REFRESH_TOKEN,
        token_uri="https://oauth2.googleapis.com/token",
        client_id=CLIENT_ID,
        client_secret=CLIENT_SECRET
    )
    # Force a refresh to get a valid access token
    if not creds.valid:
        creds.refresh(Request())
    return creds

@functions_framework.http
def renew_gmail_watch(request):
    print("--- STARTING WATCH RENEWAL ---")
    
    try:
        creds = get_creds()
        service = build('gmail', 'v1', credentials=creds)

        # 1. Find the Label IDs dynamically
        results = service.users().labels().list(userId='me').execute()
        labels = results.get('labels', [])
        all_labels = {l['name']: l['id'] for l in labels}

        watch_label_ids = [all_labels[name] for name in LABEL_NAMES if name in all_labels]

        if not watch_label_ids:
            return (f"Error: None of the labels {LABEL_NAMES} were found.", 500)

        print(f"Watching label IDs: {watch_label_ids} for labels: {[n for n in LABEL_NAMES if n in all_labels]}")

        # 2. Send the Watch Command
        request_body = {
            'topicName': TOPIC_NAME,
            'labelIds': watch_label_ids,
            'labelFilterAction': 'include'
        }
        
        response = service.users().watch(userId='me', body=request_body).execute()
        
        print(f"SUCCESS: Watch renewed. Expires: {response['expiration']}")
        return (f"Success. Expires: {response['expiration']}", 200)

    except Exception as e:
        print(f"CRITICAL ERROR: {e}")
        return (f"Internal Error: {e}", 500)