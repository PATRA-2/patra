import asyncio
import math
from datetime import UTC, datetime
from io import BytesIO
from uuid import UUID

from PIL import Image, UnidentifiedImageError
from pillow_heif import register_heif_opener
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import AppError
from app.integrations import ServiceContainer
from app.models import Diagnosis, Farm, PlantReport, User
from app.schemas import (
    Coordinate,
    DashboardReporter,
    DashboardReportOut,
    DiagnosisOut,
    DiagnosisResult,
    FarmOut,
    PlantReportOut,
    UserOut,
)

register_heif_opener()


ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/heic", "image/heif"}
REPORT_ANALYZING = "Analisis berjalan"
REPORT_PENDING = "Menunggu verifikasi"
REPORT_VERIFIED = "Terverifikasi"
REPORT_REJECTED = "Ditolak"
REPORT_AI_FAILED = "Analisis gagal"


def as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def user_out(user: User) -> UserOut:
    return UserOut(
        id=user.id,
        name=user.name,
        email=user.email,
        cooperative_name=user.cooperative_name,
    )


def farm_out(farm: Farm) -> FarmOut:
    return FarmOut(
        id=farm.id,
        name=farm.name,
        crop=farm.crop,
        location=farm.location,
        coordinate=Coordinate(latitude=farm.latitude, longitude=farm.longitude),
        is_active=farm.is_active,
        created_at=as_utc(farm.created_at),
        updated_at=as_utc(farm.updated_at),
    )


def diagnosis_out(diagnosis: Diagnosis) -> DiagnosisOut:
    return DiagnosisOut(
        id=diagnosis.id,
        prediction=diagnosis.prediction,
        confidence=diagnosis.confidence,
        symptoms=diagnosis.symptoms,
        recommendation=diagnosis.recommendation,
        created_at=as_utc(diagnosis.created_at),
    )


async def report_out(session: AsyncSession, report: PlantReport) -> PlantReportOut:
    farm = await session.get(Farm, report.farm_id)
    if farm is None:
        raise AppError(500, "INTERNAL_SERVER_ERROR", "Data lahan laporan tidak konsisten.")
    diagnosis = await session.get(Diagnosis, report.diagnosis_id) if report.diagnosis_id else None
    return PlantReportOut(
        id=report.id,
        title=report.title,
        category=report.category,
        summary=report.summary,
        description=report.description,
        status=report.status,
        farm_id=report.farm_id,
        farm_name=farm.name,
        coordinate=Coordinate(latitude=report.latitude, longitude=report.longitude),
        image_url=report.image_url,
        diagnosis=diagnosis_out(diagnosis) if diagnosis else None,
        created_at=as_utc(report.created_at),
        updated_at=as_utc(report.updated_at),
    )


async def dashboard_report_out(session: AsyncSession, report: PlantReport) -> DashboardReportOut:
    base = await report_out(session, report)
    reporter = await session.get(User, report.user_id)
    if reporter is None:
        raise AppError(500, "INTERNAL_SERVER_ERROR", "Data pelapor tidak konsisten.")
    return DashboardReportOut(
        **base.model_dump(),
        reporter=DashboardReporter(id=reporter.id, name=reporter.name, email=reporter.email),
        rejected_reason=report.rejected_reason,
        verified_at=as_utc(report.verified_at) if report.verified_at else None,
    )


async def validate_image(content: bytes, mime_type: str, max_size: int) -> None:
    if mime_type not in ALLOWED_MIME_TYPES:
        raise AppError(
            415,
            "UNSUPPORTED_MEDIA_TYPE",
            "File harus berupa image/jpeg, image/png, atau image/heic.",
        )
    if len(content) > max_size:
        raise AppError(413, "PAYLOAD_TOO_LARGE", "Ukuran foto melebihi batas 10 MB.")
    if not content:
        raise AppError(422, "VALIDATION_ERROR", "File foto tidak boleh kosong.")

    try:
        image = Image.open(BytesIO(content))
        image.verify()
        detected = (image.format or "").upper()
    except (UnidentifiedImageError, OSError, ValueError) as exc:
        raise AppError(415, "UNSUPPORTED_MEDIA_TYPE", "Isi file bukan gambar yang valid.") from exc

    expected_formats = {
        "image/jpeg": {"JPEG"},
        "image/png": {"PNG"},
        "image/heic": {"HEIF", "HEIC"},
        "image/heif": {"HEIF", "HEIC"},
    }
    if detected not in expected_formats[mime_type]:
        raise AppError(415, "UNSUPPORTED_MEDIA_TYPE", "MIME type tidak sesuai isi gambar.")


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    earth_radius_km = 6371.0088
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    a = (
        math.sin(delta_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    )
    return earth_radius_km * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def summary_from(description: str | None, result: DiagnosisResult | None) -> str:
    source = description or (result.symptoms if result else "Analisis tanaman sedang diproses.")
    normalized = " ".join(source.split())
    return normalized if len(normalized) <= 240 else normalized[:237].rstrip() + "..."


async def attach_diagnosis(
    session: AsyncSession,
    report: PlantReport,
    result: DiagnosisResult,
) -> Diagnosis:
    diagnosis = Diagnosis(
        user_id=report.user_id,
        farm_id=report.farm_id,
        prediction=result.prediction,
        confidence=result.confidence,
        symptoms=result.symptoms,
        recommendation=result.recommendation,
        crop_type=result.crop_type,
        disclaimer=result.disclaimer,
        raw_response=result.model_dump(),
    )
    session.add(diagnosis)
    await session.flush()
    report.diagnosis_id = diagnosis.id
    report.status = REPORT_PENDING
    report.summary = summary_from(report.description, result)
    return diagnosis


async def finish_report_ai(
    task: asyncio.Task[DiagnosisResult],
    report_id: UUID,
    session_factory: object,
) -> None:
    factory = session_factory
    async with factory() as session:
        report = await session.get(PlantReport, report_id)
        if report is None:
            return
        try:
            result = await task
        except Exception:
            report.status = REPORT_AI_FAILED
            await session.commit()
            return
        await attach_diagnosis(session, report, result)
        await session.commit()


async def find_owned_farm(session: AsyncSession, farm_id: UUID, user_id: UUID) -> Farm:
    farm = await session.get(Farm, farm_id)
    if farm is None:
        raise AppError(404, "NOT_FOUND", "Lahan tidak ditemukan.")
    if farm.user_id != user_id:
        raise AppError(403, "FORBIDDEN", "Lahan bukan milik user ini.")
    return farm


async def active_farm(session: AsyncSession, user_id: UUID) -> Farm | None:
    return await session.scalar(
        select(Farm)
        .where(Farm.user_id == user_id, Farm.is_active.is_(True))
        .order_by(Farm.updated_at.desc())
        .limit(1)
    )


def get_services_from_app(app: object) -> ServiceContainer:
    return app.state.services
