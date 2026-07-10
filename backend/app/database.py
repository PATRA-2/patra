from collections.abc import AsyncIterator
from dataclasses import dataclass

from fastapi import Request
from sqlalchemy import event
from sqlalchemy.engine import Engine
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.config import Settings


class Base(DeclarativeBase):
    pass


@event.listens_for(Engine, "connect")
def enable_sqlite_foreign_keys(dbapi_connection: object, _connection_record: object) -> None:
    module_name = dbapi_connection.__class__.__module__
    if not module_name.startswith("aiosqlite"):
        return
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


@dataclass(slots=True)
class Database:
    engine: AsyncEngine
    session_factory: async_sessionmaker[AsyncSession]

    @classmethod
    def create(cls, settings: Settings) -> "Database":
        connect_args: dict[str, object] = {}
        if settings.is_sqlite:
            connect_args["check_same_thread"] = False
        engine = create_async_engine(settings.async_database_url, connect_args=connect_args)
        return cls(
            engine=engine,
            session_factory=async_sessionmaker(engine, expire_on_commit=False),
        )

    async def create_demo_schema(self) -> None:
        async with self.engine.begin() as connection:
            await connection.run_sync(Base.metadata.create_all)

    async def dispose(self) -> None:
        await self.engine.dispose()


async def get_db(request: Request) -> AsyncIterator[AsyncSession]:
    database: Database = request.app.state.database
    async with database.session_factory() as session:
        yield session
