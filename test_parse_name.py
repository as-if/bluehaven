import sys
import os
import base64
import email
from bs4 import BeautifulSoup
import re
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

def get_creds():
    creds = None
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', ['https://www.googleapis.com/auth/gmail.readonly', 'https://www.googleapis.com/auth/gmail.labels', 'https://www.googleapis.com/auth/gmail.settings.basic', 'https://www.googleapis.com/auth/spreadsheets'])
    return creds

def test():
    creds = get_creds()
    service = build('gmail', 'v1', credentials=creds)
    results = service.users().messages().list(userId='me', q="label:API_Yanolja_Bookings", maxResults=5).execute()
    messages = results.get('messages', [])
    for m in messages:
        msg = service.users().messages().get(userId='me', id=m['id'], format='raw').execute()
        raw = base64.urlsafe_b64decode(msg['raw'])
        email_msg = email.message_from_bytes(raw)
        
        body_html = ""
        if email_msg.is_multipart():
            for part in email_msg.walk():
                if part.get_content_type() == 'text/html':
                    body_html = part.get_payload(decode=True).decode()
                    break
        else:
            body_html = email_msg.get_payload(decode=True).decode()
            
        print("Message ID:", m['id'])
        subject = email_msg.get('Subject', '')
        print("Subject:", subject)
        
        soup = BeautifulSoup(body_html, 'html.parser')
        full_text = soup.get_text(separator='\n')
        
        dear_match = re.search(r'Dear\s+([\s\S]+?)(?=,|\n\s*Thank|\n\s*We\s+are|\n\s*Email|\n\s*Booking|\n\s*Check|\n\s*Rooms|\n\s*Rates)', full_text, re.IGNORECASE)
        print("Dear Match:", repr(dear_match.group(1).strip()) if dear_match else None)
        
        yd_match = re.search(r'Your\s+Details\s*:?\s*(?:[\r\n]+\s*)*([^\r\n]+)', full_text, re.IGNORECASE)
        print("Your Details Match:", repr(yd_match.group(1).strip()) if yd_match else None)
        print("---")

test()
