"""Initial Radar Tani schema with optional PostGIS columns.

Revision ID: 0001_initial
Revises:
Create Date: 2026-07-10
"""

from alembic import op
from app import models  # noqa: F401
from app.database import Base

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    Base.metadata.create_all(bind=bind)
    if bind.dialect.name == "postgresql":
        op.execute("CREATE EXTENSION IF NOT EXISTS postgis")
        op.execute(
            """
            ALTER TABLE farms
            ADD COLUMN IF NOT EXISTS geo_location geography(Point, 4326)
            GENERATED ALWAYS AS (
                ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
            ) STORED
            """
        )
        op.execute(
            """
            ALTER TABLE plant_reports
            ADD COLUMN IF NOT EXISTS geo_location geography(Point, 4326)
            GENERATED ALWAYS AS (
                ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
            ) STORED
            """
        )
        op.execute(
            "CREATE INDEX IF NOT EXISTS ix_farms_geo_location ON farms USING GIST (geo_location)"
        )
        op.execute(
            "CREATE INDEX IF NOT EXISTS ix_reports_geo_location "
            "ON plant_reports USING GIST (geo_location)"
        )


def downgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("DROP INDEX IF EXISTS ix_reports_geo_location")
        op.execute("DROP INDEX IF EXISTS ix_farms_geo_location")
        op.execute("ALTER TABLE plant_reports DROP COLUMN IF EXISTS geo_location")
        op.execute("ALTER TABLE farms DROP COLUMN IF EXISTS geo_location")
    Base.metadata.drop_all(bind=bind)
