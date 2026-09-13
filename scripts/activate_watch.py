from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
import os

# 1. Setup specific to your project
TOPIC = 'projects/bluehaven-automation/topics/gmail-incoming'
LABEL_NAME = 'API_Yanolja_Bookings'

def main():
    # 2. Authenticate
    # We use the same credentials.json you used before
    creds = InstalledAppFlow.from_client_secrets_file(
        '../credentials.json', 
        ['https://www.googleapis.com/auth/gmail.readonly', 'https://www.googleapis.com/auth/gmail.labels']
    ).run_local_server(port=0)
    
    service = build('gmail', 'v1', credentials=creds)

    # 3. Find the Label ID dynamically
    # (We do this search to be 100% sure we get the right ID)
    results = service.users().labels().list(userId='me').execute()
    labels = results.get('labels', [])
    
    label_id = None
    for l in labels:
        if l['name'] == LABEL_NAME:
            label_id = l['id']
            break
    
    if not label_id:
        print(f"ERROR: Could not find label '{LABEL_NAME}' in your Gmail.")
        print("Please create it manually in Gmail first!")
        return

    print(f"Found Label ID: {label_id}")
    print("This ID is required for your 'Renewer' function. Save it!")

    # 4. Activate the Watch (The Push Connection)
    print(f"\nActivating watch on topic: {TOPIC}...")
    try:
        response = service.users().watch(userId='me', body={
            'topicName': TOPIC,
            'labelIds': [label_id],
            'labelFilterAction': 'include'
        }).execute()
        
        print("\nSUCCESS! Gmail is now connected to Google Cloud.")
        print(f"Expiration: {response['expiration']}")
        print("Now, deploy your Worker function if you haven't already.")
        
    except Exception as e:
        print(f"\nFAILED: {e}")

if __name__ == '__main__':
    main()