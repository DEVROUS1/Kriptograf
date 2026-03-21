import pytest
from pydantic import ValidationError
from app.core.config import Settings

def test_settings_default():
    s = Settings(database_url="sqlite+aiosqlite:///:memory:")
    # allowed_origins should be parsed to list
    assert s.allowed_origins == ["*"]

def test_settings_allowed_origins_parsing():
    s = Settings(database_url="sqlite+aiosqlite:///:memory:", allowed_origins="http://localhost:3000, https://example.com")
    assert "http://localhost:3000" in s.allowed_origins
    assert "https://example.com" in s.allowed_origins

def test_settings_secret_key_warning(caplog):
    s = Settings(database_url="sqlite+aiosqlite:///:memory:", secret_key="change-me")
    assert "GÜVENLİK UYARISI" in caplog.text

def test_settings_secret_key_ok(caplog):
    s = Settings(database_url="sqlite+aiosqlite:///:memory:", secret_key="super-secret")
    assert "GÜVENLİK UYARISI" not in caplog.text
