# Object Capture 3D Backend

FastAPI backend for 3D object reconstruction.

## Setup

1. Create virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # or venv\Scripts\activate on Windows
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run server:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

## API Endpoints

- `POST /sessions`: Create a new capture session.
- `POST /sessions/{id}/images`: Upload images.
- `POST /sessions/{id}/process`: Start 3D reconstruction.
- `GET /sessions/{id}`: Get session status and model URL.
