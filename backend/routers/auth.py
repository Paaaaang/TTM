from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, EmailStr, validator
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta, date
from config.database import get_db_connection
import os

router = APIRouter()

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

class LoginResponse(BaseModel):
    user: UserResponse
    token: str

def create_access_token(data: dict):
    """JWT 토큰 생성"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

@router.post("/signup", response_model=dict, status_code=status.HTTP_201_CREATED)
async def signup(request: SignupRequest):
    """회원가입"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # login_id 중복 체크
        cursor.execute(
            "SELECT member_id FROM members WHERE login_id = %s AND deleted_at IS NULL",
            (request.login_id,)
        )
        if cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="이미 존재하는 아이디입니다"
            )

        # nickname 중복 체크
        cursor.execute(
            "SELECT member_id FROM members WHERE nickname = %s AND deleted_at IS NULL",
            (request.nickname,)
        )
        if cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="이미 존재하는 닉네임입니다"
            )

        # 이메일 중복 체크
        cursor.execute(
            "SELECT member_id FROM members WHERE email = %s AND deleted_at IS NULL",
            (request.email,)
        )
        if cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="이미 존재하는 이메일입니다"
            )

        # 비밀번호 해싱
        hashed_password = pwd_context.hash(request.password)

        # 사용자 생성
        cursor.execute(
            """INSERT INTO members (login_id, nickname, email, password_hash, member_name, 
                                    phone_number, birth_date, gender, member_status, created_at, terms_agreed) 
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'ACTIVE', NOW(), 1)""",
            (request.login_id, request.nickname, request.email, hashed_password, request.member_name,
             request.phone_number, request.birth_date, request.gender)
        )
        conn.commit()
        member_id = cursor.lastrowid

        return {
            "user": {
                "member_id": member_id,
                "login_id": request.login_id,
                "nickname": request.nickname,
                "email": request.email,
                "member_name": request.member_name,
                "phone_number": request.phone_number,
                "birth_date": request.birth_date,
                "gender": request.gender
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"회원가입 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="회원가입 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest):
    """로그인"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # 사용자 조회 (login_id 또는 email로 로그인)
        cursor.execute(
            """SELECT member_id, login_id, nickname, email, password_hash, member_name, 
                      phone_number, birth_date, gender 
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
        if not pwd_context.verify(request.password, user['password_hash']):
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
        conn.commit()

        return {
            "user": {
                "member_id": user['member_id'],
                "login_id": user['login_id'],
                "nickname": user['nickname'],
                "email": user['email'],
                "member_name": user['member_name'],
                "phone_number": user.get('phone_number'),
                "birth_date": str(user['birth_date']) if user.get('birth_date') else None,
                "gender": user.get('gender')
            },
            "token": token
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"로그인 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="로그인 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.post("/logout")
async def logout():
    """로그아웃 (클라이언트에서 토큰 삭제로 처리)"""
    return {"message": "로그아웃 되었습니다"}

@router.get("/check-login-id/{login_id}")
async def check_login_id(login_id: str):
    """아이디 중복 확인"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute(
            "SELECT member_id FROM members WHERE login_id = %s AND deleted_at IS NULL", 
            (login_id,)
        )
        existing = cursor.fetchone()
        
        return {
            "available": existing is None,
            "message": "사용 가능한 아이디입니다" if existing is None else "이미 사용중인 아이디입니다"
        }
    except Exception as e:
        print(f"아이디 확인 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="아이디 확인 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.get("/check-nickname/{nickname}")
async def check_nickname(nickname: str):
    """닉네임 중복 확인"""
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
