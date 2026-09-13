import os
from pathlib import Path
try:
    from dotenv import load_dotenv
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        load_dotenv(dotenv_path=env_path)
    else:
        load_dotenv()
except ImportError:
    # Minimal fallback parser if python-dotenv is not installed
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip().strip("'\""))

BASE_DIR = Path(__file__).parent
LOGS_DIR = BASE_DIR / "logs"
SCREENSHOTS_DIR = LOGS_DIR / "screenshots"

LOGS_DIR.mkdir(exist_ok=True)
SCREENSHOTS_DIR.mkdir(exist_ok=True)

# Google Cloud / Firebase Settings
sa_candidate = BASE_DIR.parent / "functions" / "service-account.json"
if sa_candidate.exists() and "GOOGLE_APPLICATION_CREDENTIALS" not in os.environ:
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(sa_candidate.resolve())

FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "bluehaven-automation")
FIRESTORE_COLLECTION = os.getenv("FIRESTORE_COLLECTION", "bookings")

# PMS Configuration (eZee Absolute / iPMS 247)
PMS_HOTEL_CODE = os.getenv("PMS_HOTEL_CODE", "bluehavenretreat")
PMS_ENGINE_URL = os.getenv(
    "PMS_ENGINE_URL",
    f"https://live.ipms247.com/booking/book-rooms-{PMS_HOTEL_CODE}"
)
PMS_PORTAL_URL = os.getenv("PMS_PORTAL_URL", "https://live.ipms247.com/pms")
PMS_USERNAME = os.getenv("PMS_USERNAME", "")
PMS_PASSWORD = os.getenv("PMS_PASSWORD", "")

# Automation settings
AUTOMATION_STRATEGY = os.getenv("AUTOMATION_STRATEGY", "booking_engine")  # "booking_engine" or "staff_backoffice"
BROWSER_HEADLESS = os.getenv("BROWSER_HEADLESS", "true").lower() in ("true", "1", "yes")
BROWSER_TIMEOUT_MS = int(os.getenv("BROWSER_TIMEOUT_MS", "45000"))
MAX_RETRIES = int(os.getenv("MAX_RETRIES", "3"))
SYNC_INTERVAL_SECONDS = int(os.getenv("SYNC_INTERVAL_SECONDS", "30"))
PMS_DRY_RUN = os.getenv("PMS_DRY_RUN", "false").lower() in ("true", "1", "yes")
