from functools import lru_cache
from typing import Any, List, Union
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://kriptograf:secret@postgres:5432/kriptograf_db"
    redis_url: str = "redis://redis:6379/0"
    secret_key: str = "change-me"
    debug: bool = False
    log_level: str = "info"
    allowed_origins: Any = ["http://localhost:3000", "http://localhost"]
    groq_api_key: str = ""

    @field_validator("allowed_origins", mode="before")
    @classmethod
    def parse_origins(cls, v):
        if isinstance(v, str):
            # "http://a.com,http://b.com" formatını listeye çevir
            return [i.strip() for i in v.split(",") if i.strip()]
        return v


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
