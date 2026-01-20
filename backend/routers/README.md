# TTM Routers 가이드

> 최종 수정일: 2026-01-14  
> 라우터 파일: 11개  
> 최적화 완료: 2개 (auth.py, weight.py)

---

## 📋 라우터 목록

### 인증 및 회원 관리
- **auth.py** ⚡ - 회원가입, 로그인, JWT 토큰 (6개 엔드포인트)
- **members.py** - 프로필 관리, 이미지 업로드 (8개 엔드포인트)

### 건강 추적
- **meals.py** - AI 음식 분석, 식단 기록 (7개 엔드포인트)
- **exercises.py** - 운동 기록 (6개 엔드포인트)
- **weight.py** ⚡ - 체중 기록 및 변화 추이 (4개 엔드포인트)
- **health.py** - 질병/알레르기 정보 (6개 엔드포인트)

### 커뮤니티
- **posts.py** - 게시물 CRUD, 좋아요 (9개 엔드포인트)
- **comments.py** - 댓글, 대댓글 (5개 엔드포인트)

### 기타
- **badges.py** - 배지 시스템 (4개 엔드포인트)
- **notifications.py** - FCM 푸시 알림 (3개 엔드포인트)
- **ai.py** - AI 음식 분석 (1개 엔드포인트)

---

## ⚡ 최적화 현황

### 1. auth.py (2026-01-14)
**적용 사항**:
- ✅ `@handle_db_transaction` 데코레이터
- ✅ Helper 함수 추출 (`_check_duplicate_field`, `_hash_password`)
- ✅ camelCase 응답 형식
- ✅ prefix 추가: `/api/auth`

**개선 효과**:
- 코드 라인 수: 454줄 → 350줄 (23% 감소)
- try-finally 블록 자동 처리
- 가독성 대폭 향상

### 2. weight.py (2026-01-14)
**적용 사항**:
- ✅ `@handle_db_transaction` 데코레이터
- ✅ mysql.connector import 제거
- ✅ prefix 추가: `/api/weight`

**개선 효과**:
- 코드 라인 수: 276줄 → 180줄 (35% 감소)
- 에러 처리 자동화
- commit/rollback 자동 처리

---

## 🔑 주요 패턴

### 1. 데이터베이스 트랜잭션

**Before**:
```python
async def endpoint(...):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(...)
        conn.commit()
        return result
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()
```

**After** ⚡:
```python
@handle_db_transaction
async def endpoint(..., cursor=None, conn=None):
    cursor.execute(...)
    return result  # commit/rollback 자동
```

### 2. JWT 인증

```python
from .auth import get_current_user

@router.get("/protected")
async def protected(current_user: dict = Depends(get_current_user)):
    member_id = current_user["member_id"]
    return {"message": f"Hello, {current_user['nickname']}!"}
```

### 3. 응답 형식

```python
# Success (camelCase)
{
    "data": {...},
    "message": "성공"
}

# Error (HTTPException)
{
    "detail": "에러 메시지",
    "status_code": 400/401/403/404/500
}
```

---

## 📚 사용 예제

### 회원가입 → 로그인

```bash
# 1. 회원가입
POST /api/auth/signup
{
    "loginId": "test",
    "nickname": "테스터",
    "email": "test@example.com",
    "password": "Password123!@#",
    ...
}

# 2. 로그인
POST /api/auth/login
{
    "loginId": "test",
    "password": "Password123!@#"
}

# 응답
{
    "user": {...},
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 체중 기록

```bash
# 체중 기록
POST /api/weight/record
Headers: Authorization: Bearer <token>
{
    "weight_kg": 70.5,
    "recorded_date": "2026-01-14",
    "memo": "아침 측정"
}

# 이력 조회
GET /api/weight/history?start_date=2025-12-15&limit=30
Headers: Authorization: Bearer <token>

# 응답
{
    "records": [...],
    "current_weight": 70.5,
    "weight_change": -2.3  # 첫 기록 대비
}
```

---

## 🛠 최적화 도구

### 공통 유틸리티
- **utils/common.py**
  - `handle_db_transaction`: DB 트랜잭션 데코레이터
  - `validate_member_exists`: 회원 존재 확인
  - `snake_to_camel`: 스네이크 케이스 → camelCase 변환

### 응답 모델
- **models/responses.py**
  - `SuccessResponse`: 성공 응답
  - `ErrorResponse`: 에러 응답
  - `PaginatedResponse`: 페이지네이션

---

## 📊 API 테스트

- **Swagger UI**: http://localhost:3000/docs
- **ReDoc**: http://localhost:3000/redoc

---

## 📁 관련 문서

- [BACKEND_GUIDE.md](../BACKEND_GUIDE.md) - 전체 백엔드 가이드
- [DATABASE.md](../database/DATABASE.md) - 데이터베이스 스키마
- [FRONTEND_GUIDE.md](../../lib/FRONTEND_GUIDE.md) - Flutter 연동

---

**✅ 최적화 진행 중**  
**다음 대상**: members.py, posts.py, meals.py
