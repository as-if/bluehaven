from google_auth_oauthlib.flow import InstalledAppFlow
import os

SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/gmail.labels',
    'https://www.googleapis.com/auth/gmail.settings.basic',
    'https://www.googleapis.com/auth/spreadsheets'
]

def main():
    flow = InstalledAppFlow.from_client_secrets_file('../credentials.json', SCOPES)
    creds = flow.run_local_server(port=0)
    
    # 1. SAVE the token to a file (This fixes the error)
    with open('../token.json', 'w') as token:
        token.write(creds.to_json())
    
    print("\n--- SUCCESS! ---")
    print("token.json has been saved.")
    print(f"REFRESH_TOKEN: {creds.refresh_token}")

if __name__ == '__main__':
    main()