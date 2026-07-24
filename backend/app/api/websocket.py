from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.websocket.connection_manager import manager
from typing import Dict, List
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

class VideoConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, camera_id: str):
        await websocket.accept()
        if camera_id not in self.active_connections:
            self.active_connections[camera_id] = []
        self.active_connections[camera_id].append(websocket)
        logger.info(f"Client connected to video stream for {camera_id}")

    def disconnect(self, websocket: WebSocket, camera_id: str):
        if camera_id in self.active_connections and websocket in self.active_connections[camera_id]:
            self.active_connections[camera_id].remove(websocket)
            logger.info(f"Client disconnected from video stream for {camera_id}")

    async def broadcast_video(self, camera_id: str, data: bytes):
        if camera_id in self.active_connections:
            for connection in list(self.active_connections[camera_id]):
                try:
                    await connection.send_bytes(data)
                except Exception as e:
                    logger.error(f"Error sending video to client: {e}")
                    self.disconnect(connection, camera_id)

video_manager = VideoConnectionManager()

@router.websocket("/ws/live")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # We don't expect data from client, just keep connection open
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)

@router.websocket("/ws/video/{camera_id}")
async def video_websocket_endpoint(websocket: WebSocket, camera_id: str):
    await video_manager.connect(websocket, camera_id)
    try:
        while True:
            # Keep connection alive
            await websocket.receive_bytes()
    except WebSocketDisconnect:
        video_manager.disconnect(websocket, camera_id)
