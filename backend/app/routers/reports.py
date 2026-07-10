import asyncio
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, BackgroundTasks, File, Form, Query, Request, Response, UploadFile
from fastapi import status as http_status
from sqlalchemy import func, select

from app.dependencies import CurrentUser, DBSession, RequestSettings
from app.errors import AppError
from app.models import Diagnosis, PlantReport
from app.schemas import (
    DataResponse,
    DiagnosisOut,
    DiagnosisResult,
    PaginatedData,
    PlantCategory,
    PlantReportOut,
    PlantReportUpdate,
)
from app.services import (
    REPORT_AI_FAILED,
    REPORT_ANALYZING,
    REPORT_REJECTED,
    REPORT_VERIFIED,
    active_farm,
    attach_diagnosis,
    diagnosis_out,
    find_owned_farm,
    finish_report_ai,
    report_out,
    summary_from,
    validate_image,
)

router = APIRouter(tags=["Plant Reports"])


@router.post(
    "/plant-reports",
    response_model=DataResponse[PlantReportOut],
    status_code=http_status.HTTP_201_CREATED,
)
async def create_plant_report(
    request: Request,
    background_tasks: BackgroundTasks,
    user: CurrentUser,
    session: DBSession,
    settings: RequestSettings,
    image: Annotated[UploadFile, File(description="Foto tanaman, maksimum 10 MB")],
    title: Annotated[str, Form(min_length=3, max_length=200)],
    category: Annotated[PlantCategory, Form()],
    description: Annotated[str | None, Form(max_length=4_000)] = None,
    farm_id: Annotated[UUID | None, Form()] = None,
    latitude: Annotated[float | None, Form(ge=-90, le=90)] = None,
    longitude: Annotated[float | None, Form(ge=-180, le=180)] = None,
    publish_to_feed: Annotated[bool, Form()] = True,
) -> DataResponse[PlantReportOut]:
    if (latitude is None) != (longitude is None):
        raise AppError(
            422,
            "VALIDATION_ERROR",
            "latitude dan longitude harus dikirim bersama.",
            [{"field": "coordinate", "message": "Koordinat harus lengkap."}],
        )

    farm = (
        await find_owned_farm(session, farm_id, user.id)
        if farm_id
        else await active_farm(session, user.id)
    )
    if farm is None:
        raise AppError(422, "FARM_REQUIRED", "Pilih atau tambahkan lahan aktif terlebih dahulu.")

    content = await image.read(settings.max_upload_bytes + 1)
    mime_type = (image.content_type or "").lower()
    await validate_image(content, mime_type, settings.max_upload_bytes)

    report_id = uuid4()
    services = request.app.state.services
    stored = await services.storage.upload(report_id, content, mime_type)
    report = PlantReport(
        id=report_id,
        user_id=user.id,
        farm_id=farm.id,
        title=title,
        category=str(category),
        summary=summary_from(description, None),
        description=description,
        status=REPORT_ANALYZING,
        publish_to_feed=publish_to_feed,
        latitude=latitude if latitude is not None else farm.latitude,
        longitude=longitude if longitude is not None else farm.longitude,
        image_url=stored.url,
        image_path=stored.path,
        mime_type=mime_type,
        file_size=len(content),
    )
    session.add(report)
    await session.commit()

    ai_task = asyncio.create_task(
        services.ai.analyze(
            image=content,
            mime_type=mime_type,
            crop=farm.crop,
            symptom_notes=description,
        )
    )
    try:
        result = await asyncio.wait_for(
            asyncio.shield(ai_task), timeout=settings.ai_sync_timeout_seconds
        )
    except TimeoutError:
        background_tasks.add_task(
            finish_report_ai,
            ai_task,
            report.id,
            request.app.state.database.session_factory,
        )
    except Exception:
        report.status = REPORT_AI_FAILED
        await session.commit()
    else:
        await attach_diagnosis(session, report, result)
        await session.commit()
    await session.refresh(report)
    return DataResponse(data=await report_out(session, report))


@router.get("/plant-reports", response_model=DataResponse[PaginatedData[PlantReportOut]])
async def list_plant_reports(
    user: CurrentUser,
    session: DBSession,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
    category: PlantCategory | None = None,
    status: str | None = None,
    farm_id: UUID | None = None,
) -> DataResponse[PaginatedData[PlantReportOut]]:
    conditions = [PlantReport.user_id == user.id]
    if category:
        conditions.append(PlantReport.category == str(category))
    if status:
        conditions.append(PlantReport.status == status)
    if farm_id:
        await find_owned_farm(session, farm_id, user.id)
        conditions.append(PlantReport.farm_id == farm_id)

    total = await session.scalar(select(func.count()).select_from(PlantReport).where(*conditions))
    reports = (
        await session.scalars(
            select(PlantReport)
            .where(*conditions)
            .order_by(PlantReport.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
    ).all()
    items = [await report_out(session, report) for report in reports]
    return DataResponse(
        data=PaginatedData(items=items, page=page, page_size=page_size, total=total or 0)
    )


async def _owned_report(session: DBSession, report_id: UUID, user_id: UUID) -> PlantReport:
    report = await session.get(PlantReport, report_id)
    if report is None:
        raise AppError(404, "NOT_FOUND", "Laporan tidak ditemukan.")
    if report.user_id != user_id:
        raise AppError(403, "FORBIDDEN", "Laporan bukan milik user ini.")
    return report


@router.get("/plant-reports/{report_id}", response_model=DataResponse[PlantReportOut])
async def get_plant_report(
    report_id: UUID,
    user: CurrentUser,
    session: DBSession,
) -> DataResponse[PlantReportOut]:
    report = await _owned_report(session, report_id, user.id)
    return DataResponse(data=await report_out(session, report))


@router.patch("/plant-reports/{report_id}", response_model=DataResponse[PlantReportOut])
async def update_plant_report(
    report_id: UUID,
    payload: PlantReportUpdate,
    user: CurrentUser,
    session: DBSession,
) -> DataResponse[PlantReportOut]:
    report = await _owned_report(session, report_id, user.id)
    if report.status in {REPORT_VERIFIED, REPORT_REJECTED}:
        raise AppError(
            409,
            "REPORT_ALREADY_VERIFIED",
            "Laporan yang sudah dimoderasi tidak dapat diubah.",
        )
    changes = payload.model_dump(exclude_unset=True)
    if "category" in changes and changes["category"] is not None:
        changes["category"] = str(changes["category"])
    for field, value in changes.items():
        setattr(report, field, value)
    if "description" in changes:
        report.summary = summary_from(report.description, None)
    await session.commit()
    await session.refresh(report)
    return DataResponse(data=await report_out(session, report))


@router.delete(
    "/plant-reports/{report_id}",
    status_code=http_status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
async def delete_plant_report(
    report_id: UUID,
    user: CurrentUser,
    session: DBSession,
) -> Response:
    report = await _owned_report(session, report_id, user.id)
    if report.status in {REPORT_VERIFIED, REPORT_REJECTED}:
        raise AppError(
            409,
            "REPORT_ALREADY_VERIFIED",
            "Laporan yang sudah dimoderasi tidak dapat dihapus.",
        )
    await session.delete(report)
    await session.commit()
    return Response(status_code=http_status.HTTP_204_NO_CONTENT)


@router.post("/plant-diagnoses", response_model=DataResponse[DiagnosisOut])
async def create_plant_diagnosis(
    request: Request,
    user: CurrentUser,
    session: DBSession,
    settings: RequestSettings,
    image: Annotated[UploadFile, File(description="Foto tanaman, maksimum 10 MB")],
    crop: Annotated[str | None, Form(max_length=120)] = None,
    symptom_notes: Annotated[str | None, Form(max_length=4_000)] = None,
) -> DataResponse[DiagnosisOut]:
    content = await image.read(settings.max_upload_bytes + 1)
    mime_type = (image.content_type or "").lower()
    await validate_image(content, mime_type, settings.max_upload_bytes)
    try:
        result: DiagnosisResult = await asyncio.wait_for(
            request.app.state.services.ai.analyze(
                image=content,
                mime_type=mime_type,
                crop=crop,
                symptom_notes=symptom_notes,
            ),
            timeout=settings.standalone_ai_timeout_seconds,
        )
    except TimeoutError as exc:
        raise AppError(504, "AI_TIMEOUT", "Analisis AI melewati batas waktu.") from exc
    except Exception as exc:
        raise AppError(503, "AI_UNAVAILABLE", "Layanan analisis AI sedang tidak tersedia.") from exc

    diagnosis = Diagnosis(
        user_id=user.id,
        prediction=result.prediction,
        confidence=result.confidence,
        symptoms=result.symptoms,
        recommendation=result.recommendation,
        crop_type=result.crop_type,
        disclaimer=result.disclaimer,
        raw_response=result.model_dump(),
    )
    session.add(diagnosis)
    await session.commit()
    await session.refresh(diagnosis)
    return DataResponse(data=diagnosis_out(diagnosis))
