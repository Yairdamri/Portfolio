import os

# Optionally load environment variables from a local .env file (for local dev)
try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    pass

MONGO_URI = os.getenv("MONGO_URI", "mongodb://db:27017/")
MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "mydatabase")
APP_TITLE = os.getenv("APP_TITLE", "Workout Minimal API")
APP_VERSION = os.getenv("APP_VERSION", "0.0.1")
