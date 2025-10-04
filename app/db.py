from pymongo import MongoClient
from .config import MONGO_URI, MONGO_DB_NAME

client = MongoClient(MONGO_URI)
db = client[MONGO_DB_NAME]

plans_col = db["plans"]
completions_col = db["workout_completions"]
users_col = db["users"]
sessions_col = db["sessions"]
