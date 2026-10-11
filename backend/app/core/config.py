from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "NexoIA API"
    database_url: str = "sqlite:///./nexoia.db"
    secret_key: str = "cambia-esta-clave-en-produccion"
    access_token_expire_minutes: int = 60

    # Simulación de propuestas para estudiantes
    sim_intervalo_segundos: int = 120
    sim_total_propuestas: int = 5


settings = Settings()
