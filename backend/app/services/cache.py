"""
Redis önbellek servisi.
Tüm API servislerinin kullandığı get_cached / set_cached fonksiyonları burada.
Redis bağlanamasa bile uygulama çökmez — hata yakalar ve None döner.
"""
import json
import logging
from typing import Any

import redis.asyncio as redis

from app.core.config import settings

logger = logging.getLogger(__name__)

_client: redis.Redis | None = None


def _get_client() -> redis.Redis:
    global _client
    if _client is None:
        _client = redis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
            socket_connect_timeout=3,
            socket_timeout=3,
        )
    return _client


async def get_cached(key: str) -> Any | None:
    try:
        raw = await _get_client().get(key)
        if raw is None:
            return None
        return json.loads(raw)
    except Exception as exc:
        logger.debug("Cache get hatası [%s]: %s", key, exc)
        return None


async def set_cached(key: str, value: Any, ttl: int = 60) -> None:
    try:
        await _get_client().setex(key, ttl, json.dumps(value, ensure_ascii=False))
    except Exception as exc:
        logger.debug("Cache set hatası [%s]: %s", key, exc)


async def delete_cached(key: str) -> None:
    try:
        await _get_client().delete(key)
    except Exception as exc:
        logger.debug("Cache delete hatası [%s]: %s", key, exc)


async def close_cache() -> None:
    global _client
    if _client:
        await _client.aclose()
        _client = None

# Aliases for backward compatibility
get_cache = get_cached
set_cache = set_cached
