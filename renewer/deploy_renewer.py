import json
import os
import subprocess
import sys

# --- CONFIGURATION ---
TOKEN_FILE = '../token.json'  # Path to your shared token file
FUNCTION_NAME = 'gmail-renewer'
REGION = 'us-central1'

# ⚠️ UPDATED TO YOUR EXACT CONFIG:
TOPIC = 'projects/bluehaven-automation/topics/gmail-reservation'
ENTRY_POINT = 'renew_gmail_watch'

MEMORY = '256MiB'

def main():
    # 1. Check if token file exists
    if not os.path.exists(TOKEN_FILE):
        print(f"❌ ERROR: Could not find {TOKEN_FILE}")
        print("   Please ensure 'token.json' exists in the parent folder.")
        return

    # 2. Extract Credentials
    print(f"Reading credentials from {TOKEN_FILE}...")
    try:
        with open(TOKEN_FILE, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"❌ ERROR: Failed to read {TOKEN_FILE}. Details: {e}")
        return
        
    client_id = data.get('client_id')
    client_secret = data.get('client_secret')
    refresh_token = data.get('refresh_token')

    # Validation
    if not all([client_id, client_secret, refresh_token]):
        print("❌ ERROR: Missing keys in token.json.")
        print("   Ensure your token file contains 'client_id', 'client_secret', and 'refresh_token'.")
        return

    # 3. Construct the Command
    deploy_cmd = [
        "gcloud", "functions", "deploy", FUNCTION_NAME,
        "--gen2",
        "--runtime", "python310",
        "--region", REGION,
        "--trigger-topic", TOPIC,
        "--entry-point", ENTRY_POINT,
        "--memory", MEMORY,
        "--set-env-vars", 
        f"CLIENT_ID={client_id},CLIENT_SECRET={client_secret},REFRESH_TOKEN={refresh_token}"
    ]

    print("\n🚀 Deploying Cloud Function...")
    print(f"   Target: {FUNCTION_NAME}")
    print(f"   Topic:  {TOPIC}")
    print(f"   Memory: {MEMORY}")
    
    try:
        # 4. Run the Command
        subprocess.run(deploy_cmd, check=True)
        print("\n✅ Deployment Successful!")
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Deployment Failed: {e}")

if __name__ == '__main__':
    main()