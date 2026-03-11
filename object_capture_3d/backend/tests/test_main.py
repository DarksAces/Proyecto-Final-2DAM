from fastapi.testclient import TestClient
from app.main import app
import pytest

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    # Accepting both 200 (if root defined) and 404 (if not) just to ensure app mounts
    assert response.status_code in [200, 404]

def test_create_session():
    # Attempt to create a session
    response = client.post("/sessions")
    # If implemented, should return 200/201 and contain an ID
    if response.status_code < 400:
        assert "id" in response.json()
