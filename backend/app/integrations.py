import asyncio
from dataclasses import dataclass
from typing import Protocol
from urllib.parse import urljoin
from uuid import UUID

import anyio

from app.config import Settings
from app.schemas import DiagnosisResult


@dataclass(slots=True)
class StoredImage:
    url: str
    path: str


@dataclass(slots=True)
class DeliveryResult:
    token: str
    success: bool
    message_id: str | None = None
    error: str | None = None


class StorageService(Protocol):
    async def upload(self, report_id: UUID, content: bytes, mime_type: str) -> StoredImage: ...


class AIService(Protocol):
    async def analyze(
        self,
        image: bytes,
        mime_type: str,
        crop: str | None,
        symptom_notes: str | None,
    ) -> DiagnosisResult: ...


class NotificationService(Protocol):
    async def send(
        self, tokens: list[str], title: str, body: str, data: dict[str, str]
    ) -> list[DeliveryResult]: ...


class LocalStorage:
    def __init__(self, settings: Settings) -> None:
        self.directory = settings.upload_dir
        self.public_base_url = settings.public_base_url.rstrip("/") + "/"

    async def upload(self, report_id: UUID, content: bytes, mime_type: str) -> StoredImage:
        extensions = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/heic": ".heic",
            "image/heif": ".heic",
        }
        filename = f"{report_id}{extensions[mime_type]}"
        path = self.directory / filename
        await anyio.to_thread.run_sync(path.write_bytes, content)
        url = urljoin(self.public_base_url, f"media/{filename}")
        return StoredImage(url=url, path=filename)


class SupabaseStorage:
    def __init__(self, settings: Settings) -> None:
        from supabase import create_client

        self.client = create_client(
            settings.supabase_url or "", settings.supabase_service_role_key or ""
        )
        self.supabase_url = (settings.supabase_url or "").rstrip("/")
        self.bucket_name = settings.supabase_bucket_name
        self.signed_url_expire_seconds = settings.signed_url_expire_seconds

    async def upload(self, report_id: UUID, content: bytes, mime_type: str) -> StoredImage:
        extensions = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/heic": ".heic",
            "image/heif": ".heic",
        }
        object_path = f"reports/{report_id}{extensions[mime_type]}"

        def do_upload() -> str:
            bucket = self.client.storage.from_(self.bucket_name)
            bucket.upload(
                path=object_path,
                file=content,
                file_options={"content-type": mime_type, "upsert": "false"},
            )
            signed = bucket.create_signed_url(object_path, self.signed_url_expire_seconds)
            signed_url = (
                signed.get("signedURL") or signed.get("signedUrl") or signed.get("signed_url")
            )
            if not signed_url:
                raise RuntimeError("Supabase tidak mengembalikan signed URL.")
            if str(signed_url).startswith("http"):
                return str(signed_url)
            return f"{self.supabase_url}/storage/v1{signed_url}"

        url = await anyio.to_thread.run_sync(do_upload)
        return StoredImage(url=url, path=object_path)


class DemoAI:
    def __init__(self, settings: Settings) -> None:
        self.delay = settings.demo_ai_delay_seconds

    async def analyze(
        self,
        image: bytes,
        mime_type: str,
        crop: str | None,
        symptom_notes: str | None,
    ) -> DiagnosisResult:
        del image, mime_type
        if self.delay > 0:
            await asyncio.sleep(self.delay)
        crop_name = crop or "tanaman"
        notes = symptom_notes or "Daun menunjukkan perubahan warna dan bentuk."
        return DiagnosisResult(
            prediction=f"Kemungkinan gangguan hama atau penyakit pada {crop_name}",
            confidence=82,
            symptoms=notes,
            recommendation=(
                "Pisahkan tanaman terdampak, pantau selama 2-3 hari, dan konsultasikan "
                "dengan penyuluh atau koperasi bila gejala menyebar."
            ),
            crop_type=crop,
        )


class GeminiAI:
    def __init__(self, settings: Settings) -> None:
        from google import genai

        self.client = genai.Client(api_key=settings.gemini_api_key)
        self.model = settings.gemini_model

    async def analyze(
        self,
        image: bytes,
        mime_type: str,
        crop: str | None,
        symptom_notes: str | None,
    ) -> DiagnosisResult:
        from google.genai import types

        prompt = (
            "Analisis foto tanaman ini sebagai perkiraan awal, bukan diagnosis final. "
            "Jawab dalam Bahasa Indonesia dan patuhi schema JSON. "
            f"Jenis tanaman: {crop or 'tidak diketahui'}. "
            f"Catatan petani: {symptom_notes or 'tidak ada'}."
        )
        response = await self.client.aio.models.generate_content(
            model=self.model,
            contents=[prompt, types.Part.from_bytes(data=image, mime_type=mime_type)],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=DiagnosisResult,
            ),
        )
        parsed = response.parsed
        if isinstance(parsed, DiagnosisResult):
            return parsed
        if isinstance(parsed, dict):
            return DiagnosisResult.model_validate(parsed)
        return DiagnosisResult.model_validate_json(response.text)


class DemoNotifier:
    async def send(
        self, tokens: list[str], title: str, body: str, data: dict[str, str]
    ) -> list[DeliveryResult]:
        del title, body, data
        return [
            DeliveryResult(token=token, success=True, message_id=f"demo/{index}")
            for index, token in enumerate(tokens, start=1)
        ]


class FirebaseNotifier:
    def __init__(self, settings: Settings) -> None:
        import firebase_admin
        from firebase_admin import credentials

        service_account = {
            "type": "service_account",
            "project_id": settings.firebase_project_id,
            "client_email": settings.firebase_client_email,
            "private_key": (settings.firebase_private_key or "").replace("\\n", "\n"),
            "token_uri": "https://oauth2.googleapis.com/token",
        }
        app_name = f"radar-tani-{id(self)}"
        self.app = firebase_admin.initialize_app(
            credentials.Certificate(service_account),
            options={"projectId": settings.firebase_project_id},
            name=app_name,
        )

    async def send(
        self, tokens: list[str], title: str, body: str, data: dict[str, str]
    ) -> list[DeliveryResult]:
        if not tokens:
            return []

        def do_send() -> list[DeliveryResult]:
            from firebase_admin import messaging

            messages = [
                messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    data=data,
                    token=token,
                )
                for token in tokens
            ]
            batch = messaging.send_each(messages, app=self.app)
            results: list[DeliveryResult] = []
            for token, response in zip(tokens, batch.responses, strict=True):
                if response.success:
                    results.append(
                        DeliveryResult(token=token, success=True, message_id=response.message_id)
                    )
                else:
                    results.append(
                        DeliveryResult(token=token, success=False, error=str(response.exception))
                    )
            return results

        return await anyio.to_thread.run_sync(do_send)


@dataclass(slots=True)
class ServiceContainer:
    storage: StorageService
    ai: AIService
    notifier: NotificationService


def create_services(settings: Settings) -> ServiceContainer:
    if settings.service_mode == "real":
        return ServiceContainer(
            storage=SupabaseStorage(settings),
            ai=GeminiAI(settings),
            notifier=FirebaseNotifier(settings),
        )
    ai = GeminiAI(settings) if settings.gemini_api_key else DemoAI(settings)
    return ServiceContainer(
        storage=LocalStorage(settings),
        ai=ai,
        notifier=DemoNotifier(),
    )
