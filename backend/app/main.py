import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.websocket.router import router as ws_router
from app.api.rest.market import router as market_router
from app.api.rest.whale import router as whale_router
from app.api.rest.orderbook import router as orderbook_router
from app.api.rest.cvd import router as cvd_router
from app.api.rest.spread import router as spread_router
from app.api.rest.ai import router as ai_router
from app.api.rest.signals import router as signals_router
from app.api.rest.anomaly import router as anomaly_router
from app.api.rest.news_sentiment import router as news_sentiment_router
from app.api.rest.global_markets import router as global_router
from app.api.rest.support_resistance import router as sr_router
from app.api.rest.smc import router as smc_router
from app.api.rest.ai_scenarios import router as scenarios_router
from app.api.rest.alarmlar import router as alarmlar_router
from app.api.rest.portfoy import router as portfoy_router
from app.api.websocket.manager import connection_manager
from app.core.config import settings
from app.core.database import init_db, close_db

logging.basicConfig(
    level=getattr(logging, settings.log_level.upper()),
    format="%(asctime)s  %(levelname)-8s  %(name)s — %(message)s",
)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Uygulama başlangıç ve kapatma işlemleri."""
    # Startup: DB tablolarını oluştur, heartbeat başlat
    try:
        await init_db()
        logger.info("Veritabanı tabloları hazır")
    except Exception as exc:
        logger.error("DB init hatası: %s — uygulama DB olmadan çalışacak", exc)

    heartbeat_task = asyncio.create_task(connection_manager.start_heartbeat())
    logger.info("KriptoGraf API v2.1.0 başlatıldı — heartbeat aktif")

    yield

    # Shutdown
    heartbeat_task.cancel()
    try:
        await heartbeat_task
    except asyncio.CancelledError:
        pass
    await close_db()
    logger.info("KriptoGraf API kapatıldı")


def create_app() -> FastAPI:
    app = FastAPI(
        title="KriptoGraf API",
        version="2.1.0",
        docs_url="/api/docs" if settings.debug else None,
        lifespan=lifespan,
    )

    # CORS — production'da ALLOWED_ORIGINS env değişkeni set edilmeli
    origins = settings.allowed_origins if settings.allowed_origins != ["*"] else ["*"]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization"],
    )

    for router in [
        ws_router, market_router, whale_router, orderbook_router,
        cvd_router, spread_router, ai_router, signals_router,
        anomaly_router, news_sentiment_router, global_router,
        sr_router, smc_router, scenarios_router,
        alarmlar_router, portfoy_router,
    ]:
        app.include_router(router)

    @app.get("/api/health")
    async def health():
        return {
            "status": "ok",
            "version": "2.1.0",
            "connections": connection_manager.total_connections(),
            "ai": "groq" if settings.groq_api_key else "devre disi",
        }

    return app


app = create_app()
