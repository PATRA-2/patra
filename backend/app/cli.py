import argparse
import asyncio

from sqlalchemy import select

from app.config import get_settings
from app.database import Database
from app.models import User
from app.security import hash_password


async def create_admin(email: str, password: str, name: str, cooperative_name: str) -> None:
    settings = get_settings()
    database = Database.create(settings)
    if settings.is_sqlite:
        await database.create_demo_schema()
    async with database.session_factory() as session:
        normalized_email = email.lower()
        user = await session.scalar(select(User).where(User.email == normalized_email))
        if user is None:
            user = User(
                name=name,
                email=normalized_email,
                password_hash=hash_password(password),
                cooperative_name=cooperative_name,
                role="cooperative_admin",
            )
            session.add(user)
        else:
            user.name = name
            user.password_hash = hash_password(password)
            user.cooperative_name = cooperative_name
            user.role = "cooperative_admin"
        await session.commit()
    await database.dispose()
    print(f"Admin koperasi siap: {normalized_email}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Radar Tani backend utilities")
    subparsers = parser.add_subparsers(dest="command", required=True)
    create_parser = subparsers.add_parser("create-admin", help="Create or update cooperative admin")
    create_parser.add_argument("--email", required=True)
    create_parser.add_argument("--password", required=True)
    create_parser.add_argument("--name", default="Admin Koperasi")
    create_parser.add_argument("--cooperative-name", default="Koperasi Radar Tani")
    args = parser.parse_args()
    if args.command == "create-admin":
        asyncio.run(create_admin(args.email, args.password, args.name, args.cooperative_name))


if __name__ == "__main__":
    main()
