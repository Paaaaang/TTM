# TTM Backend 완벽 가이드

> FastAPI + MySQL 기반 백엔드 서버 개발, 설정, 운영 통합 문서

**작성일**: 2026-01-14  
**버전**: 1.0.0

---

## 📋 목차

1. [프로젝트 구조](#1-프로젝트-구조)
2. [환경 설정](#2-환경-설정)
3. [서버 실행](#3-서버-실행)
4. [API 엔드포인트](#4-api-엔드포인트)
5. [AI 음식 분석](#5-ai-음식-분석)
6. [데이터베이스](#6-데이터베이스)
7. [서비스 레이어](#7-서비스-레이어)
8. [트러블슈팅](#8-트러블슈팅)
9. [배포 가이드](#9-배포-가이드)

---

## 1. 프로젝트 구조

```
backend/
├── config/               # 설정 파일
│   ├── database.py       # MySQL 연결 설정
│   └── __init__.py
│
├── routers/              # API 라우터 (11개)
│   ├── auth.py           # 인증 (회원가입, 로그인)
│   ├── members.py        # 회원 정보 관리
│   ├── meals.py          # 식단 기록 + AI 분석
│   ├── exercises.py      # 운동 기록
│   ├── weight.py         # 체중 기록
│   ├── health.py         # 질병/알레르기 정보
│   ├── posts.py          # 커뮤니티 게시물
│   ├── comments.py       # 댓글
│   ├── badges.py         # 배지 시스템
│   ├── ai.py             # AI 챗봇
│   ├── notifications.py  # FCM 푸시 알림
│   └── README.md
│
├── services/             # 비즈니스 로직
│   ├── food_analyzer.py  # AI 음식 분석
│   ├── badge_auto_award.py  # 배지 자동 수여
│   ├── fcm_service.py    # FCM 알림 서비스
│   └── __init__.py
│
├── database/             # SQL 스크립트
│   ├── schema.sql        # 테이블 생성
│   ├── add_indexes.sql   # 성능 인덱스
│   └── DB_변경이력.md
│
├── utilities/            # 유틸리티 스크립트
│   ├── check_*.py        # DB 체크 스크립트
│   ├── test_*.py         # API 테스트
│   └── debug_*.py        # 디버깅 도구
│
├── uploads/              # 업로드 파일 저장소
│   ├── profile_images/
│   └── post_images/
│
├── main.py               # FastAPI 앱 진입점
├── requirements.txt      # Python 의존성
├── .env                  # 환경 변수
└── BACKEND_GUIDE.md      # 이 문서

```

---

## 2. 환경 설정

### 2.1 필수 요구사항

- **Python**: 3.11 이상
- **MySQL**: 8.0 이상
- **pip**: Python 패키지 관리자

### 2.2 Python 가상환경 설정

```powershell
# backend 폴더로 이동
cd C:\Users\smhrd\Desktop\App\ttm\backend

# 가상환경 생성
python -m venv venv

# 가상환경 활성화 (PowerShell)
.\venv\Scripts\Activate.ps1

# 가상환경 활성화 (CMD)
venv\Scripts\activate.bat
```

### 2.3 패키지 설치

```powershell
pip install -r requirements.txt
```

**주요 패키지**:
```
fastapi==0.115.6          # Web 프레임워크
uvicorn==0.34.0           # ASGI 서버
mysql-connector-python==9.1.0  # MySQL 드라이버
python-jose[cryptography]==3.3.0  # JWT 토큰
passlib[bcrypt]==1.7.4    # 비밀번호 해싱
python-multipart==0.0.20  # 파일 업로드
firebase-admin==6.6.0     # FCM 푸시 알림
python-dotenv==1.0.1      # 환경 변수
openai==1.59.5            # AI 분석
```

### 2.4 환경 변수 설정

`.env` 파일 생성:
```env
# MySQL Database
DB_HOST=project-db-campus.smhrd.com
DB_USER=we0123
DB_PASSWORD=cand4567
DB_NAME=ttm_db
DB_PORT=3307

# JWT Secret
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=43200

# OpenAI API (AI 음식 분석)
OPENAI_API_KEY=your-openai-api-key

# Firebase (FCM 푸시 알림)
FIREBASE_CREDENTIALS_PATH=./firebase-adminsdk.json
```

### 2.5 MySQL 데이터베이스 설정

```bash
# MySQL 접속
mysql -h project-db-campus.smhrd.com -P 3307 -u we0123 -p

# 데이터베이스 선택
USE ttm_db;

# 테이블 생성 (schema.sql 실행)
source C:/Users/smhrd/Desktop/App/ttm/backend/database/schema.sql;

# 테이블 확인
SHOW TABLES;
```

---

## 3. 서버 실행

### 3.1 개발 모드

```powershell
# 방법 1: main.py 직접 실행
python main.py

# 방법 2: uvicorn 직접 실행
uvicorn main:app --host 0.0.0.0 --port 3000 --reload
```

**성공 메시지**:
```
✅ MySQL 데이터베이스 연결 성공
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
INFO:     Started server process [12345]
INFO:     Application startup complete.
```

### 3.2 서버 접속

- **API 문서**: http://localhost:3000/docs (Swagger UI)
- **API 루트**: http://localhost:3000/
- **업로드 파일**: http://localhost:3000/uploads/{filename}

### 3.3 프로덕션 모드

```powershell
# 워커 4개로 실행
uvicorn main:app --host 0.0.0.0 --port 3000 --workers 4
```

---

## 4. API 엔드포인트

### 4.1 인증 (auth.py) - 6개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/auth/signup` | 회원가입 |
| POST | `/api/auth/login` | 로그인 |
| POST | `/api/auth/logout` | 로그아웃 |
| GET | `/api/auth/check-login-id/{login_id}` | 아이디 중복 확인 |
| GET | `/api/auth/check-nickname/{nickname}` | 닉네임 중복 확인 |
| GET | `/api/auth/check-email/{email}` | 이메일 중복 확인 |

**회원가입 요청 예시**:
```json
{
  "loginId": "testuser",
  "password": "Test1234!",
  "email": "test@example.com",
  "phoneNumber": "010-1234-5678",
  "memberName": "홍길동",
  "nickname": "테스터",
  "gender": "M",
  "birthDate": "1990-01-01",
  "region": "서울특별시",
  "heightCm": 175.5,
  "termsAgreed": true
}
```

### 4.2 회원 관리 (members.py) - 7개

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/members/{member_id}` | 회원 정보 조회 |
| POST | `/api/members/upload-profile-image` | 프로필 이미지 업로드 |
| PUT | `/api/members/{member_id}/profile` | 프로필 수정 |
| PUT | `/api/members/{member_id}/health` | 건강 정보 수정 |
| GET | `/api/members/{member_id}/activity-stats` | 활동 통계 |
| PUT | `/api/members/{member_id}/calorie-goal` | 칼로리 목표 수정 |
| DELETE | `/api/members/{member_id}` | 회원 탈퇴 |

### 4.3 식단 관리 (meals.py) - 7개

| Method | Endpoint | 설명 |
|--------|----------|------|
| **POST** | **`/api/meals/analyze-image`** | **AI 식단 이미지 분석** ⭐ |
| GET | `/api/meals/today/{member_id}` | 오늘 식단 조회 |
| GET | `/api/meals/date-range/{member_id}` | 기간별 식단 조회 |
| POST | `/api/meals/` | 식단 기록 추가 |
| PUT | `/api/meals/{meal_log_id}` | 식단 기록 수정 |
| DELETE | `/api/meals/{meal_log_id}` | 식단 기록 삭제 |
| GET | `/api/meals/stats/{member_id}` | 식단 통계 |

### 4.4 운동 관리 (exercises.py) - 6개

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/exercises/today/{member_id}` | 오늘 운동 조회 |
| GET | `/api/exercises/date-range/{member_id}` | 기간별 운동 조회 |
| POST | `/api/exercises/` | 운동 기록 추가 |
| PUT | `/api/exercises/{exercise_log_id}` | 운동 기록 수정 |
| DELETE | `/api/exercises/{exercise_log_id}` | 운동 기록 삭제 |
| GET | `/api/exercises/stats/{member_id}` | 운동 통계 |

### 4.5 체중 관리 (weight.py) - 4개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/weight/record` | 체중 기록 (같은 날짜 자동 업데이트) |
| GET | `/api/weight/history` | 체중 이력 조회 |
| GET | `/api/weight/latest` | 최근 체중 조회 |
| DELETE | `/api/weight/record/{weight_log_id}` | 체중 기록 삭제 |

### 4.6 건강 정보 (health.py) - 6개

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/health/diseases/{member_id}` | 질병 목록 조회 |
| POST | `/api/health/diseases/` | 질병 추가 |
| DELETE | `/api/health/diseases/{member_disease_id}` | 질병 삭제 |
| GET | `/api/health/allergies/{member_id}` | 알레르기 목록 조회 |
| POST | `/api/health/allergies/` | 알레르기 추가 |
| DELETE | `/api/health/allergies/{allergy_id}` | 알레르기 삭제 |

### 4.7 커뮤니티 (posts.py) - 9개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/posts/upload-image` | 이미지 업로드 |
| GET | `/api/posts/list` | 게시물 목록 (페이지네이션) |
| GET | `/api/posts/{post_id}` | 게시물 상세 조회 |
| POST | `/api/posts/` | 게시물 작성 |
| PUT | `/api/posts/{post_id}` | 게시물 수정 |
| DELETE | `/api/posts/{post_id}` | 게시물 삭제 |
| GET | `/api/posts/search` | 게시물 검색 |
| POST | `/api/posts/{post_id}/like` | 좋아요 추가 |
| DELETE | `/api/posts/{post_id}/like` | 좋아요 취소 |

### 4.8 배지 (badges.py) - 6개

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/badges/` | 전체 배지 목록 |
| GET | `/api/badges/member/{member_id}` | 회원 배지 조회 |
| POST | `/api/badges/award` | 배지 수여 |
| DELETE | `/api/badges/member/{member_badge_id}` | 배지 삭제 |
| GET | `/api/badges/stats/{member_id}` | 배지 통계 |
| POST | `/api/badges/check-and-award/{member_id}` | 배지 자동 체크 및 수여 |

### 4.9 기타

- **댓글** (comments.py): 4개 엔드포인트
- **AI 챗봇** (ai.py): 2개 엔드포인트
- **푸시 알림** (notifications.py): 3개 엔드포인트

**총 60개 API 엔드포인트**

---

## 5. AI 음식 분석

### 5.1 시스템 아키텍처

```
Flutter 앱
    │
    │ POST /api/meals/analyze-image (이미지 파일)
    ▼
FastAPI Backend
    │
    ▼
FoodAnalyzer 클래스 (services/food_analyzer.py)
    │
    ├─ 1. YOLO 음식 감지 (음식 종류)
    ├─ 2. ResNet 양 추정 (Q값)
    ├─ 3. 영양 DB 조회 (400개 음식)
    └─ 4. 영양소 계산
    │
    ▼
AI 분석 결과 반환
```

### 5.2 API 사용법

**요청**:
```http
POST /api/meals/analyze-image
Content-Type: multipart/form-data

image: [이미지 파일]
meal_type: "LUNCH"
meal_date: "2026-01-14"
```

**응답**:
```json
{
  "foods": [
    {
      "foodName": "김치찌개",
      "portionSize": 1.2,
      "calories": 180.5,
      "carbohydrates": 15.2,
      "protein": 12.8,
      "fat": 8.5
    }
  ],
  "totalCalories": 180.5,
  "totalCarbs": 15.2,
  "totalProtein": 12.8,
  "totalFat": 8.5
}
```

### 5.3 영양 데이터베이스

- **위치**: `backend/data/nutrition_db.xlsx`
- **음식 수**: 400개
- **영양소**: 16개 (칼로리, 탄수화물, 단백질, 지방, 당, 나트륨 등)

---

## 6. 데이터베이스

### 6.1 테이블 구조 (15개)

| 테이블 | 설명 | 주요 칼럼 |
|--------|------|-----------|
| **members** | 회원 정보 | member_id, login_id, email, nickname |
| **meal_log** | 식단 기록 | meal_log_id, member_id, meal_date, meal_type |
| **meal_item** | 식단 항목 | meal_item_id, meal_log_id, food_name, calories_kcal |
| **exercise_log** | 운동 기록 | exercise_log_id, member_id, exercise_date |
| **weight_log** | 체중 기록 | weight_log_id, member_id, weight_kg |
| **post** | 게시물 | post_id, member_id, title, content |
| **post_image** | 게시물 이미지 | image_id, post_id, image_url |
| **post_like** | 게시물 좋아요 | post_id, member_id |
| **post_comment** | 댓글 | comment_id, post_id, member_id |
| **badge** | 배지 정의 | badge_id, badge_name, conditions |
| **member_badge** | 회원 배지 | member_badge_id, member_id, badge_id |
| **member_disease** | 회원 질병 | member_disease_id, member_id |
| **member_allergy** | 회원 알레르기 | allergy_id, member_id |
| **friend** | 친구 관계 | friendship_id, member_id, friend_id |
| **fcm_token** | FCM 토큰 | member_id, token |

### 6.2 인덱스

성능 최적화를 위한 인덱스:
```sql
-- meal_log
CREATE INDEX idx_meal_date ON meal_log(meal_date);
CREATE INDEX idx_meal_member_id ON meal_log(member_id);

-- exercise_log
CREATE INDEX idx_exercise_member_id ON exercise_log(member_id);

-- weight_log
CREATE INDEX idx_weight_date ON weight_log(recorded_date);
CREATE INDEX idx_weight_member_id ON weight_log(member_id);

-- post
CREATE INDEX idx_post_category ON post(category);
CREATE INDEX idx_post_created_at ON post(created_at);
```

---

## 7. 서비스 레이어

### 7.1 FoodAnalyzer (services/food_analyzer.py)

AI 음식 분석 핵심 로직:
```python
class FoodAnalyzer:
    def analyze_meal_image(self, image_path: str) -> dict:
        # 1. YOLO로 음식 감지
        # 2. ResNet으로 양 추정
        # 3. 영양 DB 조회
        # 4. 영양소 계산
        return analysis_result
```

### 7.2 BadgeAutoAward (services/badge_auto_award.py)

배지 자동 수여 로직:
- 운동 배지: 연속 출석, 총 운동 시간 등
- 식단 배지: 아침 식사 횟수, 단식 횟수 등
- 커뮤니티 배지: 게시물 작성, 좋아요 수 등

### 7.3 FCMService (services/fcm_service.py)

Firebase Cloud Messaging 푸시 알림:
```python
async def send_notification(
    token: str,
    title: str,
    body: str,
    data: dict = None
)
```

---

## 8. 트러블슈팅

### 8.1 DB 연결 실패

**증상**:
```
mysql.connector.errors.DatabaseError: 2003 (HY000): Can't connect to MySQL server
```

**해결**:
1. MySQL 서버 상태 확인
2. `.env` 파일 DB 정보 확인
3. 방화벽 설정 확인 (포트 3307 오픈)

### 8.2 JWT 토큰 오류

**증상**:
```
401 Unauthorized: Invalid token
```

**해결**:
1. 토큰 만료 시간 확인 (기본 43200분 = 30일)
2. `.env`의 `SECRET_KEY` 확인
3. 헤더 형식: `Authorization: Bearer {token}`

### 8.3 이미지 업로드 실패

**증상**:
```
500 Internal Server Error: File upload failed
```

**해결**:
1. `uploads/` 폴더 권한 확인
2. 파일 크기 제한 확인 (기본 10MB)
3. 지원 형식: jpg, jpeg, png

---

## 9. 배포 가이드

### 9.1 프로덕션 체크리스트

- [ ] `.env` 파일 SECRET_KEY 변경
- [ ] CORS 설정 변경 (`allow_origins=["*"]` → 특정 도메인)
- [ ] HTTPS 적용
- [ ] Rate Limiting 추가
- [ ] 로깅 시스템 구축 (Sentry 등)
- [ ] 더미 계정 삭제 또는 비밀번호 변경
- [ ] DB 백업 설정
- [ ] 환경 변수 보안 강화

### 9.2 CORS 설정 (main.py)

```python
# 개발 환경
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 모든 도메인 허용
    ...
)

# 프로덕션 환경
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://yourdomain.com",
        "https://app.yourdomain.com"
    ],
    ...
)
```

### 9.3 보안 권장사항

1. **비밀번호**: bcrypt 해싱 (이미 구현됨)
2. **SQL Injection**: 파라미터화된 쿼리 사용 (이미 구현됨)
3. **JWT**: 짧은 만료 시간 + Refresh Token 추가 권장
4. **파일 업로드**: 파일 타입 검증, 바이러스 스캔
5. **Rate Limiting**: API 호출 횟수 제한

---

## 📞 문의 및 지원

- **이슈 트래킹**: GitHub Issues
- **문서 업데이트**: 이 파일 직접 수정 후 커밋

**마지막 업데이트**: 2026-01-14
