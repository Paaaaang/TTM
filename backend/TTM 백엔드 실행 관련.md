# TTM 백엔드 서버 FAQ

## 목차
- [서버와 데이터베이스 관계](#서버와-데이터베이스-관계)
- [백엔드 서버 실행 방법](#백엔드-서버-실행-방법)
- [DB 연결 실패 처리](#db-연결-실패-처리)
- [테스트 계정](#테스트-계정)

---

## 서버와 데이터베이스 관계

### Q. 무조건 서버가 실행될 때만 DB가 작동하는가?

**아니요!** MySQL 데이터베이스는 독립적인 서버입니다.

#### 시스템 구조
```
Flutter 앱 ↔ 백엔드 서버 ↔ MySQL DB
```

#### 각 구성 요소의 역할

| 구성요소 | 역할 | 독립성 |
|---------|------|--------|
| **MySQL DB** | 데이터 저장소 (project-db-campus.smhrd.com:3307) | ✅ 항상 켜져있음 |
| **백엔드 서버** | API 제공, MySQL에 연결하는 클라이언트 | ❌ 수동으로 실행 필요 |
| **Flutter 앱** | 사용자 인터페이스 | ❌ 백엔드 서버 필요 |

#### 정리
- MySQL 서버는 원격에서 24시간 작동 중
- 백엔드 서버가 꺼져도 DB는 계속 작동함
- **백엔드 서버가 켜져야만** Flutter 앱이 DB에 접근 가능

---

## 백엔드 서버 실행 방법

### 실행 명령어

```powershell
C:\Users\smhrd\Desktop\App\ttm\backend\venv\Scripts\python.exe C:\Users\smhrd\Desktop\App\ttm\backend\main.py
```

### 성공 메시지
```
✅ MySQL 데이터베이스 연결 성공
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
INFO:     Started server process [xxxx]
INFO:     Application startup complete.
```

### 서버 주소
- **API 서버**: http://localhost:3000
- **API 문서 (Swagger)**: http://localhost:3000/docs
- **API 문서 (ReDoc)**: http://localhost:3000/redoc

### 서버 중지
터미널에서 `CTRL+C` 누르기

---

## DB 연결 실패 처리

### Q. DB 연결이 안 될 때 회원가입/로그인이 안 되게 만들어야 하는가?

**네, 이미 구현되어 있습니다!**

### 현재 구현된 에러 처리

#### 코드 구조
```python
try:
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    # ... DB 작업 ...
    
except HTTPException:
    raise  # 비즈니스 로직 에러 (중복 이메일 등)
    
except Exception as e:
    print(f"회원가입 오류: {e}")
    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="회원가입 중 오류가 발생했습니다"
    )
```

### 동작 방식

1. **DB 연결 실패 발생**
   - `get_db_connection()`에서 예외 발생
   - 예: 네트워크 오류, 잘못된 비밀번호, DB 서버 다운

2. **Exception catch**
   - 모든 예외를 catch하여 처리
   - HTTP 500 Internal Server Error 반환

3. **Flutter 앱에서 표시**
   - 상태 코드: 500
   - 에러 메시지: "회원가입 중 오류가 발생했습니다"

### 에러 타입별 처리

| 상황 | HTTP 코드 | 메시지 |
|-----|----------|--------|
| DB 연결 실패 | 500 | "회원가입 중 오류가 발생했습니다" |
| 이메일 중복 | 409 | "이미 존재하는 이메일입니다" |
| 잘못된 로그인 | 401 | "이메일 또는 비밀번호가 일치하지 않습니다" |
| 유효성 검사 실패 | 422 | 해당 필드의 에러 메시지 |

---

## 테스트 계정

회원가입/로그인 테스트용 계정 2개가 준비되어 있습니다.

### 테스트 계정 1 (일반 사용자)
```
이메일: test@test.com
비밀번호: Test1234!@
이름: 테스트사용자
```

### 테스트 계정 2 (관리자)
```
이메일: admin@ttm.com
비밀번호: Test1234!@
이름: 관리자
```

### 테스트 방법

#### 1. API 문서로 테스트
1. 서버 실행 후 http://localhost:3000/docs 접속
2. `POST /auth/login` 클릭
3. "Try it out" 클릭
4. 요청 본문 입력:
```json
{
  "email": "test@test.com",
  "password": "Test1234!@"
}
```
5. "Execute" 클릭
6. 응답 확인: 토큰과 사용자 정보 반환

#### 2. Flutter 앱으로 테스트
1. 백엔드 서버 실행 확인
2. Flutter 앱 실행
3. 로그인 화면에서 위 계정으로 로그인

---

## API 엔드포인트

### 인증 관련 (auth)

#### POST /auth/signup
회원가입

**요청:**
```json
{
  "email": "user@example.com",
  "password": "Test1234!@",
  "member_name": "홍길동",
  "phone_number": "010-1234-5678",
  "birth_date": "1990-01-01",
  "gender": "M"
}
```

**응답 (201):**
```json
{
  "user": {
    "member_id": 1,
    "email": "user@example.com",
    "member_name": "홍길동",
    "phone_number": "010-1234-5678",
    "birth_date": "1990-01-01",
    "gender": "M"
  }
}
```

#### POST /auth/login
로그인

**요청:**
```json
{
  "email": "test@test.com",
  "password": "Test1234!@"
}
```

**응답 (200):**
```json
{
  "user": {
    "member_id": 1,
    "email": "test@test.com",
    "member_name": "테스트사용자",
    ...
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### GET /auth/check-email/{email}
이메일 중복 확인

**요청:** GET /auth/check-email/test@test.com

**응답 (200):**
```json
{
  "available": false,
  "message": "이미 사용중인 이메일입니다"
}
```

#### POST /auth/logout
로그아웃 (클라이언트에서 토큰 삭제)

**응답 (200):**
```json
{
  "message": "로그아웃 되었습니다"
}
```

---

## 환경 설정 (.env)

```env
# 서버 설정
PORT=3000

# MySQL 데이터베이스 설정
DB_HOST=project-db-campus.smhrd.com
DB_USER=we0123
DB_PASSWORD=cand4567
DB_NAME=we0123
DB_PORT=3307

# JWT 설정
JWT_SECRET=ttm_secret_key_2026_change_in_production
JWT_EXPIRES_DAYS=7
```

---

## 문제 해결

### 서버가 시작되지 않을 때

#### 1. 포트 충돌
```
Error: Address already in use
```
**해결:** 이미 실행 중인 서버 종료 후 재시작

#### 2. DB 연결 실패
```
Access denied for user 'we0123'
```
**해결:** .env 파일의 DB 정보 확인

#### 3. 모듈 없음 에러
```
ModuleNotFoundError: No module named 'passlib'
```
**해결:**
```powershell
C:\Users\smhrd\Desktop\App\ttm\backend\venv\Scripts\pip.exe install -r requirements.txt
```

### Flutter 앱에서 연결 안 될 때

#### 증상
```
SocketException: Failed to connect
```

#### 체크리스트
- [ ] 백엔드 서버가 실행 중인가?
- [ ] Flutter 앱의 API URL이 올바른가? (http://localhost:3000 또는 http://10.0.2.2:3000)
- [ ] 방화벽이 3000번 포트를 차단하는가?

---

## 프로젝트 구조

```
backend/
├── main.py                    # FastAPI 앱 진입점
├── .env                       # 환경 변수 (DB 정보)
├── requirements.txt           # Python 패키지 목록
├── insert_test_users.py       # 테스트 계정 삽입 스크립트
├── venv/                      # Python 가상환경
├── config/
│   └── database.py           # DB 연결 설정
├── routers/
│   └── auth.py               # 인증 API 라우터
└── database/
    └── schema.sql            # DB 스키마 (참고용)
```

---

## 추가 정보

### JWT 토큰
- 유효기간: 7일
- 알고리즘: HS256
- 포함 정보: member_id, email

### 비밀번호 정책
- 최소 10자 이상
- 대문자 포함 필수
- 소문자 포함 필수
- 숫자 포함 필수
- 특수문자 포함 필수 (!@#$%^&*(),.?":{}|<>)

### 데이터베이스
- 테이블: members (25개 컬럼)
- 문자셋: utf8mb4
- 주요 필드: member_id, email, password_hash, member_name, phone_number, birth_date, gender, region 등

---

**작성일:** 2026년 1월 5일  
**버전:** 1.0
