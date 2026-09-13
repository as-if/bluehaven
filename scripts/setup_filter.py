from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
import pickle, os

# Reuse credentials.json
creds = InstalledAppFlow.from_client_secrets_file('../credentials.json', ['https://www.googleapis.com/auth/gmail.settings.basic', 'https://www.googleapis.com/auth/gmail.labels', 'https://www.googleapis.com/auth/gmail.readonly']).run_local_server(port=0)
service = build('gmail', 'v1', credentials=creds)

# 1. Create Label
LABEL_NAME = 'API_Yanolja_Bookings'
existing = [l for l in service.users().labels().list(userId='me').execute().get('labels', []) if l['name'] == LABEL_NAME]
label_id = existing[0]['id'] if existing else service.users().labels().create(userId='me', body={'name': LABEL_NAME}).execute()['id']
print(f"Label ID: {label_id}")

# 2. Create Filter
service.users().settings().filters().create(userId='me', body={
    'criteria': {'from': 'notifications@yanoljacloudsolution.com'},
    'action': {'addLabelIds': [label_id]}
}).execute()

# 3. Start Watch
service.users().watch(userId='me', body={
    'topicName': 'projects/bluehaven-automation/topics/gmail-incoming', 
    'labelIds': [label_id],
    'labelFilterAction': 'include'
}).execute()
print("System is LIVE.")