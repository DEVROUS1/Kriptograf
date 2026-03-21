import pytest
import httpx
from app.services.whale_tracker import get_recent_whale_trades

@pytest.mark.asyncio
async def test_get_recent_whale_trades_success(mocker):
    # httpx.AsyncClient'ı mock'la
    mock_client = mocker.patch("httpx.AsyncClient.__aenter__")
    mock_client.return_value.get = mocker.AsyncMock(side_effect=[
        # Price response (1. çağrı)
        mocker.MagicMock(
            status_code=200, 
            json=lambda: {"price": "60000.0"},
            raise_for_status=lambda: None
        ),
        # Trades response (2. çağrı) — biri whale, diğeri değil
        mocker.MagicMock(
            status_code=200, 
            json=lambda: [
                {"id": 1, "time": 1700000000000, "qty": "10.0", "price": "60000.0", "isBuyerMaker": True},  # 600K USD -> WHALE (SATIŞ)
                {"id": 2, "time": 1700000010000, "qty": "0.1", "price": "60000.0", "isBuyerMaker": False},  # 6K USD -> IGNORE
            ],
            raise_for_status=lambda: None
        )
    ])

    result = await get_recent_whale_trades("BTCUSDT")
    assert len(result) == 1
    assert result[0]["usd_deger"] == 600000.0
    assert result[0]["yon"] == "SATIŞ"

@pytest.mark.asyncio
async def test_get_recent_whale_trades_timeout(mocker):
    # Timeout exception mock'la
    mock_client = mocker.patch("httpx.AsyncClient.__aenter__")
    mock_client.return_value.get = mocker.AsyncMock(side_effect=httpx.TimeoutException("Timeout"))

    result = await get_recent_whale_trades("BTCUSDT")
    assert result == []  # Hata yutulup boş liste dönmeli
