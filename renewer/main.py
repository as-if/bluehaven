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
LABEL_NAME = 'API_Yanolja_Bookings'

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

        # 1. Find the Label ID dynamically
        results = service.users().labels().list(userId='me').execute()
        labels = results.get('labels', [])
        label_id = next((l['id'] for l in labels if l['name'] == LABEL_NAME), None)

        if not label_id:
            return (f"Error: Label '{LABEL_NAME}' not found.", 500)

        # 2. Send the Watch Command
        request_body = {
            'topicName': TOPIC_NAME,
            'labelIds': [label_id],
            'labelFilterAction': 'include'
        }
        
        response = service.users().watch(userId='me', body=request_body).execute()
        
        print(f"SUCCESS: Watch renewed. Expires: {response['expiration']}")
        return (f"Success. Expires: {response['expiration']}", 200)

    except Exception as e:
        print(f"CRITICAL ERROR: {e}")
        return (f"Internal Error: {e}", 500)