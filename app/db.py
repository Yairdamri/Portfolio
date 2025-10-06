import os
from .config import MONGO_URI, MONGO_DB_NAME

USE_MOCK_DB = os.getenv("USE_MOCK_DB") == "1"
if USE_MOCK_DB:
    try:
        from mongomock import MongoClient  # type: ignore
    except Exception:
        # Fallback to real client if mongomock not installed
        from pymongo import MongoClient  # type: ignore
else:
    from pymongo import MongoClient  # type: ignore

client = MongoClient(MONGO_URI)
db = client[MONGO_DB_NAME]

plans_col = db["plans"]
completions_col = db["workout_completions"]
users_col = db["users"]
sessions_col = db["sessions"]
