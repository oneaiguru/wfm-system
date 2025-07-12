from typing import List, Union
from pydantic_settings import BaseSettings
from pydantic import AnyHttpUrl, field_validator


class Settings(BaseSettings):
    PROJECT_NAME: str = "WFM Enterprise Integration API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_USER: str = "wfm_user"
    POSTGRES_PASSWORD: str = "wfm_password"
    POSTGRES_DB: str = "wfm_enterprise"
    DATABASE_URL: str = ""
    
    REDIS_URL: str = "redis://localhost:6379/0"
    
    SECRET_KEY: str = "your-secret-key-here-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    BACKEND_CORS_ORIGINS: List[AnyHttpUrl] = []
    
    CACHE_TTL_SECONDS: int = 300
    CACHE_KEY_PREFIX: str = "wfm:"
    
    RESPONSE_TIMEOUT_SECONDS: int = 2
    MAX_RETRY_ATTEMPTS: int = 3
    RETRY_DELAY_SECONDS: float = 0.5
    
    MONITORING_ENABLED: bool = True
    LOG_LEVEL: str = "INFO"
    DEMO_MODE: bool = False
    
    class Config:
        case_sensitive = True
        env_file = ".env"
        extra = "allow"
    
    @field_validator("DATABASE_URL", mode="before")
    def assemble_db_connection(cls, v: str, values) -> str:
        if isinstance(v, str) and v:
            return v
        return f"postgresql+asyncpg://{values.data.get('POSTGRES_USER')}:{values.data.get('POSTGRES_PASSWORD')}@{values.data.get('POSTGRES_SERVER')}/{values.data.get('POSTGRES_DB')}"
    
    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)


settings = Settings()