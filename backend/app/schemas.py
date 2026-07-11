from datetime import datetime
from enum import StrEnum
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator


class APIModel(BaseModel):
    model_config = ConfigDict(from_attributes=True, str_strip_whitespace=True)


class DataResponse[T](APIModel):
    data: T


class PaginatedData[T](APIModel):
    items: list[T]
    page: int
    page_size: int
    total: int


class ErrorDetail(APIModel):
    field: str
    message: str


class ErrorBody(APIModel):
    code: str
    message: str
    details: list[ErrorDetail] = Field(default_factory=list)


class ErrorResponse(APIModel):
    error: ErrorBody


class HealthOut(APIModel):
    status: str
    service: str
    version: str


class Coordinate(APIModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class UserOut(APIModel):
    id: UUID
    name: str
    email: EmailStr
    cooperative_name: str | None = None


class RegisterIn(APIModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    cooperative_name: str | None = Field(default=None, max_length=200)
    farm_location: str | None = Field(default=None, max_length=200)


class LoginIn(APIModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class RefreshIn(APIModel):
    refresh_token: str = Field(min_length=32)


class TokenPairOut(APIModel):
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int


class AuthOut(TokenPairOut):
    user: UserOut


class FarmCreate(APIModel):
    name: str = Field(min_length=2, max_length=120)
    crop: str = Field(min_length=2, max_length=120)
    location: str = Field(min_length=2, max_length=200)
    coordinate: Coordinate
    is_active: bool = True


class FarmUpdate(APIModel):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    crop: str | None = Field(default=None, min_length=2, max_length=120)
    location: str | None = Field(default=None, min_length=2, max_length=200)
    coordinate: Coordinate | None = None
    is_active: bool | None = None


class FarmOut(APIModel):
    id: UUID
    name: str
    crop: str
    location: str
    coordinate: Coordinate
    is_active: bool
    created_at: datetime
    updated_at: datetime


class PlantCategory(StrEnum):
    DISEASE = "Penyakit"
    PEST = "Hama"
    OTHER = "Lainnya"


class DiagnosisResult(APIModel):
    prediction: str = Field(min_length=3)
    confidence: int = Field(ge=0, le=100)
    symptoms: str = Field(min_length=3)
    recommendation: str = Field(min_length=3)
    crop_type: str | None = None
    disclaimer: str = (
        "Hasil ini merupakan perkiraan awal berbasis AI dan bukan pengganti pemeriksaan "
        "langsung oleh penyuluh atau ahli pertanian."
    )


class DiagnosisOut(APIModel):
    id: UUID
    prediction: str
    confidence: int = Field(ge=0, le=100)
    symptoms: str
    recommendation: str
    created_at: datetime


class PlantChatDiagnosisIn(APIModel):
    prediction: str = Field(min_length=3, max_length=500)
    confidence: int = Field(ge=0, le=100)
    symptoms: str = Field(min_length=1, max_length=4_000)
    recommendation: str = Field(min_length=1, max_length=4_000)


class PlantChatIn(APIModel):
    message: str = Field(min_length=1, max_length=1_000)
    diagnosis: PlantChatDiagnosisIn


class PlantChatOut(APIModel):
    reply: str


class PlantReportOut(APIModel):
    id: UUID
    title: str
    category: str
    summary: str
    description: str | None = None
    status: str
    farm_id: UUID
    farm_name: str
    coordinate: Coordinate
    image_url: str
    diagnosis: DiagnosisOut | None = None
    created_at: datetime
    updated_at: datetime


class PlantReportUpdate(APIModel):
    title: str | None = Field(default=None, min_length=3, max_length=200)
    category: PlantCategory | None = None
    description: str | None = Field(default=None, max_length=4_000)
    publish_to_feed: bool | None = None


class FeedReportOut(APIModel):
    id: UUID
    category: str
    distance: str
    distance_km: float
    title: str
    summary: str
    status: str
    farm_name: str
    coordinate: Coordinate
    image_url: str
    created_at: datetime


class MapReportOut(APIModel):
    id: UUID
    title: str
    category: str
    status: str
    coordinate: Coordinate
    created_at: datetime


class MapItemsOut(APIModel):
    items: list[MapReportOut]


class NotificationOut(APIModel):
    id: UUID
    title: str
    message: str
    related_report_id: UUID | None = None
    is_read: bool
    created_at: datetime


class PesticideOrderCreate(APIModel):
    product_name: str = Field(min_length=2, max_length=200)
    quantity: int = Field(gt=0, le=10_000)
    related_report_id: UUID | None = None


class PesticideOrderOut(APIModel):
    id: UUID
    product_name: str
    quantity: int
    status: str
    created_at: datetime


class DeviceCreate(APIModel):
    fcm_token: str = Field(min_length=16, max_length=4_096)
    platform: str = Field(default="ios", max_length=24)

    @field_validator("platform")
    @classmethod
    def validate_platform(cls, value: str) -> str:
        normalized = value.lower()
        if normalized not in {"ios", "android", "web"}:
            raise ValueError("Platform harus ios, android, atau web.")
        return normalized


class DeviceOut(APIModel):
    id: UUID
    platform: str
    last_seen_at: datetime


class VerifyBroadcastIn(APIModel):
    radius_km: float = Field(default=10, gt=0, le=100)


class RejectReportIn(APIModel):
    reason: str = Field(min_length=3, max_length=1_000)


class BroadcastSummary(APIModel):
    targeted: int
    sent: int
    failed: int


class VerifyBroadcastOut(APIModel):
    report: PlantReportOut
    broadcast: BroadcastSummary


class DashboardReporter(APIModel):
    id: UUID
    name: str
    email: EmailStr


class DashboardReportOut(PlantReportOut):
    reporter: DashboardReporter
    rejected_reason: str | None = None
    verified_at: datetime | None = None


class LocationQuery(APIModel):
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)

    @model_validator(mode="after")
    def require_complete_pair(self) -> "LocationQuery":
        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("latitude dan longitude harus dikirim bersama.")
        return self
