"""인증 관련 라우터 (회원가입, 로그인, JWT 토큰)"""
from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr, validator
from passlib.context import CryptContext
from jose import jwt, JWTError
from datetime import datetime, timedelta, date
from config.database import get_db_connection
from utils.common import handle_db_transaction
from models.responses import SuccessResponse, ErrorResponse, TokenResponse
import os
import re

router = APIRouter()
security = HTTPBearer()

# 비밀번호 해싱
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT 설정
SECRET_KEY = os.getenv("JWT_SECRET", "your_jwt_secret_key")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = int(os.getenv("JWT_EXPIRES_DAYS", 7))

# Pydantic 모델
class SignupRequest(BaseModel):
    login_id: str
    nickname: str
    email: EmailStr
    password: str
    member_name: str
    phone_number: str | None = None
    birth_date: str | None = None  # YYYY-MM-DD 형식
    gender: str | None = None  # 'M' or 'F'
    region: str = '서울'  # 기본값

    @validator('login_id')
    def login_id_length(cls, v):
        if len(v) < 3:
            raise ValueError('아이디는 최소 3자 이상이어야 합니다')
        return v

    @validator('nickname')
    def nickname_length(cls, v):
        if len(v) < 2:
            raise ValueError('닉네임은 최소 2자 이상이어야 합니다')
        return v

    @validator('password')
    def password_strength(cls, v):
        if len(v) < 10:
            raise ValueError('비밀번호는 최소 10자 이상이어야 합니다')
        if len(v) > 50:
            raise ValueError('비밀번호는 최대 50자까지 입력 가능합니다')
        if not any(c.isupper() for c in v):
            raise ValueError('비밀번호는 대문자를 포함해야 합니다')
        if not any(c.islower() for c in v):
            raise ValueError('비밀번호는 소문자를 포함해야 합니다')
        if not any(c.isdigit() for c in v):
            raise ValueError('비밀번호는 숫자를 포함해야 합니다')
        if not any(c in '!@#$%^&*(),.?":{}|<>' for c in v):
            raise ValueError('비밀번호는 특수문자를 포함해야 합니다')
        return v

class LoginRequest(BaseModel):
    login_id: str  # login_id 또는 email
    password: str

class UserResponse(BaseModel):
    member_id: int
    login_id: str
    nickname: str
    email: str
    member_name: str
    phone_number: str | None = None
    birth_date: str | None = None
    gender: str | None = None
    created_at: datetime | None = None

class LoginResponse(BaseModel):
    user: UserResponse
    token: str

def create_access_token(data: dict):
    """JWT 토큰 생성"""
    to_encode = data.copy()
    member_id = to_encode.get("member_id")
    if member_id is not None:
        to_encode["sub"] = str(member_id)
    expire = datetime.utcnow() + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def _check_duplicate_field(cursor, field: str, value: str) -> None:
    """필드 중복 체크 헬퍼 함수"""
    cursor.execute(
        f"SELECT member_id FROM members WHERE {field} = %s AND deleted_at IS NULL",
        (value,)
    )
    if cursor.fetchone():
        field_names = {
            'login_id': '아이디',
            'nickname': '닉네임',
            'email': '이메일'
        }
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"이미 존재하는 {field_names.get(field, field)}입니다"
        )

def _hash_password(password: str) -> str:
    """비밀번호 해싱 (bcrypt 72바이트 제한 처리)"""
    password_bytes = password.encode('utf-8')[:72]
    password_truncated = password_bytes.decode('utf-8', errors='ignore')
    return pwd_context.hash(password_truncated)

@router.post("/signup", status_code=status.HTTP_201_CREATED)
@handle_db_transaction
async def signup(request: SignupRequest, cursor=None, conn=None):
    """
    회원가입
    
    - login_id, nickname, email 중복 체크
    - 비밀번호 bcrypt 해싱 (72바이트 제한)
    - member_status: ACTIVE, terms_agreed: 1로 자동 설정
    """
    # 중복 체크
    _check_duplicate_field(cursor, 'login_id', request.login_id)
    _check_duplicate_field(cursor, 'nickname', request.nickname)
    _check_duplicate_field(cursor, 'email', request.email)
    
    # 비밀번호 해싱
    hashed_password = _hash_password(request.password)
    
    # 사용자 생성
    cursor.execute(
        """INSERT INTO members (login_id, nickname, email, password_hash, member_name, 
                                phone_number, birth_date, gender, region, member_status, terms_agreed) 
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'ACTIVE', 1)""",
        (request.login_id, request.nickname, request.email, hashed_password, request.member_name,
         request.phone_number, request.birth_date, request.gender, request.region)
    )
    member_id = cursor.lastrowid
    
    # 생성된 회원 정보 조회
    cursor.execute(
        """SELECT member_id, login_id, nickname, email, member_name,
                  phone_number, birth_date, gender, region,
                  height_cm, weight_kg, calorie_goal, water_goal, activity_level,
                  member_status, terms_agreed, push_notification_enabled,
                  marketing_notification_enabled, profile_image, created_at
           FROM members WHERE member_id = %s""",
        (member_id,)
    )
    user = cursor.fetchone()
    
    return {
        "user": {
            "memberId": user['member_id'],
            "loginId": user['login_id'],
            "nickname": user['nickname'],
            "email": user['email'],
            "memberName": user['member_name'],
            "phoneNumber": user.get('phone_number'),
            "birthDate": str(user['birth_date']) if user.get('birth_date') else None,
            "gender": user.get('gender'),
            "region": user.get('region'),
            "heightCm": user.get('height_cm'),
            "weightKg": user.get('weight_kg'),
            "calorieGoal": user.get('calorie_goal') or 2000,
            "waterGoal": user.get('water_goal'),
            "activityLevel": user.get('activity_level'),
            "memberStatus": user.get('member_status', 'ACTIVE'),
            "termsAgreed": bool(user.get('terms_agreed', 0)),
            "pushNotificationEnabled": bool(user.get('push_notification_enabled', 1)),
            "marketingNotificationEnabled": bool(user.get('marketing_notification_enabled', 0)),
            "profileImage": user.get('profile_image'),
            "createdAt": user['created_at'].isoformat() if user.get('created_at') else None
        }
    }

@router.post("/login")
@handle_db_transaction
async def login(request: LoginRequest, cursor=None, conn=None):
    """
    로그인
    
    - login_id 또는 email로 로그인 가능
    - JWT 토큰 생성 (유효기간: 7일)
    - 로그인 시간 자동 업데이트
    """
    # 사용자 조회 (login_id 또는 email)
    cursor.execute(
        """SELECT member_id, login_id, nickname, email, password_hash, member_name, 
                  phone_number, birth_date, gender, region,
                  height_cm, weight_kg, calorie_goal, water_goal, activity_level,
                  member_status, terms_agreed, push_notification_enabled, 
                  marketing_notification_enabled, profile_image, created_at
           FROM members 
           WHERE (login_id = %s OR email = %s) AND deleted_at IS NULL AND member_status = 'ACTIVE'""",
        (request.login_id, request.login_id)
    )
    user = cursor.fetchone()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="아이디 또는 비밀번호가 일치하지 않습니다"
        )
    
    # 비밀번호 검증
    password_bytes = request.password.encode('utf-8')[:72]
    password_truncated = password_bytes.decode('utf-8', errors='ignore')
    if not pwd_context.verify(password_truncated, user['password_hash']):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="아이디 또는 비밀번호가 일치하지 않습니다"
        )
    
    # JWT 토큰 생성
    token = create_access_token({
        "member_id": user['member_id'],
        "login_id": user['login_id'],
        "email": user['email']
    })
    
    # 마지막 로그인 시간 업데이트
    cursor.execute(
        "UPDATE members SET updated_at = NOW() WHERE member_id = %s",
        (user['member_id'],)
    )
    
    return {
        "user": {
            "memberId": user['member_id'],
            "loginId": user['login_id'],
            "nickname": user['nickname'],
            "email": user['email'],
            "memberName": user['member_name'],
            "phoneNumber": user.get('phone_number'),
            "birthDate": str(user['birth_date']) if user.get('birth_date') else None,
            "gender": user.get('gender'),
            "region": user.get('region'),
            "heightCm": user.get('height_cm'),
            "weightKg": user.get('weight_kg'),
            "calorieGoal": user.get('calorie_goal') or 2000,
            "waterGoal": user.get('water_goal'),
            "activityLevel": user.get('activity_level'),
            "memberStatus": user.get('member_status', 'ACTIVE'),
            "termsAgreed": bool(user.get('terms_agreed', 0)),
            "pushNotificationEnabled": bool(user.get('push_notification_enabled', 1)),
            "marketingNotificationEnabled": bool(user.get('marketing_notification_enabled', 0)),
            "profileImage": user.get('profile_image'),
            "createdAt": user['created_at'].isoformat() if user.get('created_at') else None
        },
        "token": token
    }

@router.post("/logout")
async def logout():
    """로그아웃 (클라이언트에서 토큰 삭제로 처리)"""
    return {"message": "로그아웃 되었습니다"}

@router.get("/check-login-id/{login_id}")
@handle_db_transaction
async def check_login_id(login_id: str, cursor=None, conn=None):
    """
    아이디 중복 확인
    
    - 최소 3자 이상
    - 영문, 숫자, 하이픈(-), 언더스코어(_)만 허용
    """
    # 형식 검증
    if len(login_id) < 3:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="아이디는 최소 3자 이상이어야 합니다"
        )
    
    if not re.match(r'^[a-zA-Z0-9_-]+$', login_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="아이디는 영문, 숫자, 하이픈(-), 언더스코어(_)만 사용 가능합니다"
        )
    
    # 중복 확인
    cursor.execute(
        "SELECT member_id FROM members WHERE login_id = %s AND deleted_at IS NULL", 
        (login_id,)
    )
    existing = cursor.fetchone()
    
    return {
        "available": existing is None,
        "message": "사용 가능한 아이디입니다" if existing is None else "이미 사용중인 아이디입니다"
    }

@router.get("/check-nickname/{nickname}")
async def check_nickname(nickname: str):
    """닉네임 중복 확인"""
    # 형식 검증
    if len(nickname) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="닉네임은 최소 2자 이상이어야 합니다"
        )
    
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute(
            "SELECT member_id FROM members WHERE nickname = %s AND deleted_at IS NULL", 
            (nickname,)
        )
        existing = cursor.fetchone()
        
        return {
            "available": existing is None,
            "message": "사용 가능한 닉네임입니다" if existing is None else "이미 사용중인 닉네임입니다"
        }
    except Exception as e:
        print(f"닉네임 확인 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="닉네임 확인 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.get("/check-email/{email}")
async def check_email(email: str):
    """이메일 중복 확인"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute(
            "SELECT member_id FROM members WHERE email = %s AND deleted_at IS NULL", 
            (email,)
        )
        existing = cursor.fetchone()
        
        return {
            "available": existing is None,
            "message": "사용 가능한 이메일입니다" if existing is None else "이미 사용중인 이메일입니다"
        }
    except Exception as e:
        print(f"이메일 확인 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="이메일 확인 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """
    JWT 토큰으로 현재 사용자 정보 조회 (의존성 주입용)
    
    Returns:
        dict: 사용자 정보 (member_id, login_id, email, nickname 등)
    
    Raises:
        HTTPException: 401 Unauthorized - 토큰이 유효하지 않거나 만료됨
    """
    token = credentials.credentials
    
    try:
        # JWT 토큰 디코딩
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        member_id = payload.get("sub") or payload.get("member_id")
        
        if member_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="유효하지 않은 토큰입니다",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        try:
            member_id = int(member_id)
        except (TypeError, ValueError):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="유효하지 않은 토큰입니다",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # DB에서 사용자 정보 조회
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            cursor.execute(
                """SELECT member_id, login_id, email, nickname, member_name, 
                          phone_number, birth_date, gender, region, height_cm, weight_kg,
                          activity_level, calorie_goal, water_goal
                   FROM members 
                   WHERE member_id = %s AND deleted_at IS NULL AND member_status = 'ACTIVE'""",
                (member_id,)
            )
            user = cursor.fetchone()
            
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="사용자를 찾을 수 없습니다",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            
            return user
            
        finally:
            cursor.close()
            conn.close()
            
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="토큰이 만료되었거나 유효하지 않습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )
