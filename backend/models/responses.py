"""
Response 모델 정의
"""
from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime


class SuccessResponse(BaseModel):
    """성공 응답 기본 모델"""
    success: bool = True
    message: str
    data: Optional[Any] = None


class ErrorResponse(BaseModel):
    """에러 응답 기본 모델"""
    success: bool = False
    error: str
    detail: Optional[str] = None


class PaginatedResponse(BaseModel):
    """페이지네이션 응답 모델"""
    data: List[Any]
    page: int
    limit: int
    total: int
    totalPages: int


class TokenResponse(BaseModel):
    """토큰 응답 모델"""
    accessToken: str
    tokenType: str = "bearer"
    expiresIn: int  # 초 단위


class MemberResponse(BaseModel):
    """회원 정보 응답 모델"""
    memberId: int
    loginId: str
    email: str
    nickname: str
    memberName: str
    gender: str
    birthDate: str
    region: Optional[str]
    heightCm: Optional[float]
    weightKg: Optional[float]
    profileImage: Optional[str]
    activityLevel: Optional[str]
    calorieGoal: Optional[int]
    createdAt: datetime
