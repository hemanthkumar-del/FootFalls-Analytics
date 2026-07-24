import pymongo
from database.connection import db_connection

def setup_indexes():
    """Creates indexes on collections to optimize queries."""
    if db_connection.db is None:
        return
        
    try:
        events_coll = db_connection.get_collection("events")
        if events_coll is not None:
            # Ascending timestamp index
            events_coll.create_index([("timestamp", pymongo.DESCENDING)])
            # Unique event_id index to prevent duplicates
            events_coll.create_index([("event_id", pymongo.ASCENDING)], unique=True)
            events_coll.create_index([("track_id", pymongo.ASCENDING)])
            events_coll.create_index([("camera_id", pymongo.ASCENDING)])
            
        print("Database indexes ensured successfully.")
    except Exception as e:
        print(f"Failed to create indexes: {e}")
