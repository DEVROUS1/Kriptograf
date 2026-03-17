from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from fastapi.websockets import WebSocketState
from app.api.websocket.manager import ws_manager
import asyncio
import logging
from app.services.binance import stream_kline, stream_markets

router = APIRouter()
logger = logging.getLogger(__name__)

@router.websocket("/kline/{symbol}/{interval}")
async def websocket_kline(websocket: WebSocket, symbol: str, interval: str):
    room = f"kline_{symbol}_{interval}"
    await ws_manager.connect(websocket, room)
    
    is_first = ws_manager.is_first_connection_in_room(room)
    streaming_task = None
    
    if is_first:
        streaming_task = asyncio.create_task(stream_kline(symbol, interval, room))

    try:
        while True:
            data = await websocket.receive_text()
            if not ws_manager.check_rate_limit(websocket):
                await ws_manager.send_personal("Rate limit exceeded", websocket)
                continue
                
            if data == "pong":
                pass # Respond to heartbeat
                
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, room)
    except Exception as e:
        logger.error(f"WebSocket error in {room}: {e}")
        ws_manager.disconnect(websocket, room)
    finally:
        # If no one is listening anymore, task will eventually stop or we could cancel it explicitly.
        pass

@router.websocket("/markets")
async def websocket_markets(websocket: WebSocket):
    room = "markets"
    await ws_manager.connect(websocket, room)
    
    is_first = ws_manager.is_first_connection_in_room(room)
    streaming_task = None
    
    if is_first:
        streaming_task = asyncio.create_task(stream_markets(room))

    try:
        while True:
            data = await websocket.receive_text()
            if not ws_manager.check_rate_limit(websocket):
                await ws_manager.send_personal("Rate limit exceeded", websocket)
                continue
                
            if data == "pong":
                pass
                
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, room)
    except Exception as e:
        logger.error(f"WebSocket error in {room}: {e}")
        ws_manager.disconnect(websocket, room)
