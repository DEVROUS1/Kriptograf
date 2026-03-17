import asyncio
from typing import Dict, Set
from collections import defaultdict
from fastapi import WebSocket
from fastapi.websockets import WebSocketState
import time
import logging

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        self.active_rooms: Dict[str, Set[WebSocket]] = defaultdict(set)
        self.rate_limits: Dict[WebSocket, list] = defaultdict(list)

    async def connect(self, websocket: WebSocket, room: str):
        await websocket.accept()
        self.active_rooms[room].add(websocket)

    def disconnect(self, websocket: WebSocket, room: str):
        self.active_rooms[room].discard(websocket)
        if hasattr(self, 'rate_limits') and websocket in self.rate_limits:
            del self.rate_limits[websocket]

    def is_first_connection_in_room(self, room: str) -> bool:
        return len(self.active_rooms.get(room, set())) == 1

    async def send_personal(self, message: str, websocket: WebSocket):
        if websocket.client_state == WebSocketState.CONNECTED:
            await websocket.send_text(message)

    async def broadcast(self, message: str, room: str):
        dead_connections = set()
        for connection in self.active_rooms.get(room, set()):
            try:
                if connection.client_state == WebSocketState.CONNECTED:
                    await connection.send_text(message)
                else:
                    dead_connections.add(connection)
            except Exception as e:
                logger.error(f"Error broadcasting to connection: {e}")
                dead_connections.add(connection)
        
        for dead_conn in dead_connections:
            self.disconnect(dead_conn, room)

    def check_rate_limit(self, websocket: WebSocket) -> bool:
        now = time.time()
        # Keep only timestamps from the last second
        self.rate_limits[websocket] = [ts for ts in self.rate_limits[websocket] if now - ts < 1.0]

        if len(self.rate_limits[websocket]) >= 20: # 20 messages per second limit
            return False
        
        self.rate_limits[websocket].append(now)
        return True

    async def start_heartbeat(self):
        while True:
            await asyncio.sleep(30)
            rooms_to_check = list(self.active_rooms.keys())
            for room in rooms_to_check:
                dead_connections = set()
                for connection in self.active_rooms.get(room, set()):
                    try:
                        if connection.client_state == WebSocketState.CONNECTED:
                            await connection.send_text("ping")
                        else:
                            dead_connections.add(connection)
                    except Exception as e:
                        logger.error(f"Heartbeat failed: {e}")
                        dead_connections.add(connection)
                
                for dead_conn in dead_connections:
                    self.disconnect(dead_conn, room)
                
                # Cleanup empty rooms
                if len(self.active_rooms.get(room, set())) == 0:
                    try:
                        del self.active_rooms[room]
                    except KeyError:
                        pass

    def total_connections(self) -> int:
        return sum(len(conns) for conns in self.active_rooms.values())

ws_manager = ConnectionManager()
connection_manager = ws_manager
