import pytest
from app.api.rest.market import _ticker_24h, BINANCE_API
import httpx

@pytest.mark.asyncio
async def test_ticker_success(mocker):
    mock_get = mocker.patch("httpx.AsyncClient.get", new_callable=mocker.AsyncMock)
    mock_response = mocker.MagicMock()
    mock_response.json.return_value = {
        "symbol": "BTCUSDT",
        "lastPrice": "50000.0",
        "priceChangePercent": "5.5",
        "priceChange": "2500.0",
        "quoteVolume": "1000000.0",
        "highPrice": "51000.0",
        "lowPrice": "49000.0",
        "count": "5000"
    }
    mock_get.return_value = mock_response

    result = await _ticker_24h("BTCUSDT")
    assert result is not None
    assert result["sembol"] == "BTCUSDT"
    assert result["fiyat"] == 50000.0
    assert result["degisim_yuzde"] == 5.5

@pytest.mark.asyncio
async def test_ticker_exception(mocker):
    mock_get = mocker.patch("httpx.AsyncClient.get", new_callable=mocker.AsyncMock)
    mock_get.side_effect = httpx.RequestError("Network Error")

    result = await _ticker_24h("BTCUSDT")
    assert result is None
