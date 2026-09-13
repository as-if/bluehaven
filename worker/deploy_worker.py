import json
import os
import subprocess
import sys

# --- CONFIGURATION ---
TOKEN_FILE = '../token.json'  # Path to your token file
FUNCTION_NAME = 'gmail-worker'
REGION = 'us-central1'
TOPIC = 'gmail-reservation'
ENTRY_POINT = 'gmail_pubsub_handler'
MEMORY = '512MiB'

def main():
    # 1. Check if token file exists
    if not os.path.exists(TOKEN_FILE):
        print(f"❌ ERROR: Could not find {TOKEN_FILE}")
        print("   Please run 'get_token.py' in the parent folder first.")
        return

    # 2. Extract Credentials
    print(f"Reading credentials from {TOKEN_FILE}...")
    with open(TOKEN_FILE, 'r') as f:
        data = json.load(f)
        
    client_id = data.get('client_id')
    client_secret = data.get('client_secret')
    refresh_token = data.get('refresh_token')

    # Validation
    if not all([client_id, client_secret, refresh_token]):
        print("❌ ERROR: Missing keys in token.json.")
        print("   Ensure your token file contains 'client_id', 'client_secret', and 'refresh_token'.")
        return

    # 3. Construct the Command
    # We use a list format for security (avoids shell injection)
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
    
    try:
        # 4. Run the Command
        subprocess.run(deploy_cmd, check=True)
        print("\n✅ Deployment Successful!")
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Deployment Failed: {e}")

if __name__ == '__main__':
    main()