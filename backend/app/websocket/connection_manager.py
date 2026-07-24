import asyncio
from typing import Dict, Any

class ConnectionManager:
    def __init__(self):
        # We will use asyncio.Queue for broadcasting if using plain websockets,
        # but since FastAPI provides WebSocket class, we store active connections.
        self.active_connections: list = []

    async def connect(self, websocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        dead_connections = []
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                # Connection might be closed ungracefully
                dead_connections.append(connection)
                
        # Clean up memory leaks
        for dead in dead_connections:
            self.disconnect(dead)

manager = ConnectionManager()
