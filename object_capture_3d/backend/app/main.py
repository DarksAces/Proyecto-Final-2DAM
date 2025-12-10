from fastapi import FastAPI, UploadFile, File, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import os
import shutil
from typing import List
from .models import SessionCreate, SessionResponse, ProcessingStatus
from .utils import create_session_dir, get_session_dir, generate_session_id, TEMP_DIR
from .reconstructor import Reconstructor

app = FastAPI(title="Object Capture 3D API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files for accessing generated models
if not os.path.exists(TEMP_DIR):
    os.makedirs(TEMP_DIR)
app.mount("/static", StaticFiles(directory=TEMP_DIR), name="static")

# Mount Web Client
WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "web")
if not os.path.exists(WEB_DIR):
    os.makedirs(WEB_DIR)
app.mount("/web", StaticFiles(directory=WEB_DIR, html=True), name="web")

@app.get("/client")
async def client():
    return FileResponse(os.path.join(WEB_DIR, "index.html"))

# In-memory storage for session status (use a DB in production)
session_store = {}

@app.post("/sessions", response_model=SessionResponse)
async def create_session(session: SessionCreate):
    session_id = generate_session_id()
    create_session_dir(session_id)
    
    session_data = {
        "session_id": session_id,
        "name": session.name,
        "created_at": str(os.path.getctime(get_session_dir(session_id))),
        "image_count": 0,
        "status": "created",
        "model_url": None
    }
    session_store[session_id] = session_data
    return session_data

@app.post("/sessions/{session_id}/images")
async def upload_images(session_id: str, files: List[UploadFile] = File(...)):
    if session_id not in session_store:
        raise HTTPException(status_code=404, detail="Session not found")
        
    session_dir = get_session_dir(session_id)
    images_dir = os.path.join(session_dir, "images")
    
    count = 0
    for file in files:
        file_path = os.path.join(images_dir, file.filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        count += 1
        
    session_store[session_id]["image_count"] += count
    return {"message": f"Uploaded {count} images", "total_images": session_store[session_id]["image_count"]}

def process_3d_task(session_id: str):
    try:
        session_store[session_id]["status"] = "processing"
        reconstructor = Reconstructor(get_session_dir(session_id))
        glb_path = reconstructor.process()
        
        # Update session with result URL
        # Assuming the server is accessible at the base URL, we construct the static path
        # In a real app, use the actual domain/IP
        relative_path = os.path.relpath(glb_path, TEMP_DIR).replace("\\", "/")
        session_store[session_id]["model_url"] = f"/static/{relative_path}"
        session_store[session_id]["status"] = "completed"
        print(f"Session {session_id} processing complete.")
    except Exception as e:
        print(f"Error processing session {session_id}: {e}")
        session_store[session_id]["status"] = "failed"

@app.post("/sessions/{session_id}/process")
async def start_processing(session_id: str, background_tasks: BackgroundTasks):
    if session_id not in session_store:
        raise HTTPException(status_code=404, detail="Session not found")
        
    if session_store[session_id]["image_count"] == 0:
        raise HTTPException(status_code=400, detail="No images uploaded")
        
    background_tasks.add_task(process_3d_task, session_id)
    return {"message": "Processing started", "status": "processing"}

@app.get("/sessions/{session_id}", response_model=SessionResponse)
async def get_session(session_id: str):
    if session_id not in session_store:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Mock datetime for response compatibility if needed, or convert stored string back
    # For simplicity, we just return the dict as is, Pydantic will handle basic types, 
    # but datetime might need parsing if we were strict.
    # We'll just return the dict and let Pydantic coerce.
    return session_store[session_id]

@app.get("/")
async def root():
    return {"message": "Object Capture 3D API is running"}
