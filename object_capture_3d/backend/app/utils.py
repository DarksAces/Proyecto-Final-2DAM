import os
import uuid
from datetime import datetime
import shutil

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMP_DIR = os.path.join(BASE_DIR, "temp_captures")

def get_session_dir(session_id: str) -> str:
    return os.path.join(TEMP_DIR, session_id)

def create_session_dir(session_id: str):
    path = get_session_dir(session_id)
    os.makedirs(path, exist_ok=True)
    os.makedirs(os.path.join(path, "images"), exist_ok=True)
    return path

def generate_session_id() -> str:
    return str(uuid.uuid4())

def cleanup_session(session_id: str):
    path = get_session_dir(session_id)
    if os.path.exists(path):
        shutil.rmtree(path)
