# TTM Backend

TTM (Together To Move) 건강 관리 애플리케이션 백엔드 서버

FastAPI + MySQL 기반 REST API 서버로 식단 관리, 운동 기록, 커뮤니티, AI 분석 등의 기능을 제공합니다.

---

## 🚀 빠른 시작

### 1. 환경 설정

```powershell
# 가상환경 생성 및 활성화
python -m venv venv
.\venv\Scripts\Activate.ps1

# 의존성 설치
pip install -r requirements.txt
```

### 2. 환경 변수 설정

`.env` 파일 생성:
```env
# MySQL Database
DB_HOST=project-db-campus.smhrd.com
DB_USER=we0123
DB_PASSWORD=cand4567
DB_NAME=we0123
DB_PORT=3307

# JWT Secret
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=43200

# Firebase (Optional)
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
```

### 3. 서버 실행

```powershell
python main.py
```

서버 접속:
- **API 문서**: http://localhost:3000/docs
- **API 루트**: http://localhost:3000/

---

## 📁 프로젝트 구조

```
backend/
├── main.py                   # FastAPI 앱 진입점
├── requirements.txt          # Python 의존성
├── .env                      # 환경 변수 (gitignore)
├── .gitignore               # Git 제외 파일
│
├── config/                   # 설정
│   └── database.py          # MySQL 연결
│
├── routers/                  # API 라우터 (11개)
│   ├── auth.py              # 🔐 인증 (회원가입, 로그인)
│   ├── members.py           # 👤 회원 정보 관리
│   ├── meals.py             # 🍽️ 식단 기록 + AI 분석
│   ├── exercises.py         # 💪 운동 기록
│   ├── weight.py            # ⚖️ 체중 기록
│   ├── health.py            # 🏥 건강 정보
│   ├── posts.py             # 📝 커뮤니티 게시글
│   ├── comments.py          # 💬 댓글
│   ├── badges.py            # 🏅 배지 시스템
│   ├── ai.py                # 🤖 AI 챗봇
│   ├── notifications.py     # 🔔 FCM 푸시 알림
│   └── ROUTERS_README.md
│
├── services/                 # 비즈니스 로직
│   ├── food_analyzer.py     # AI 음식 분석
│   ├── badge_auto_award.py  # 배지 자동 수여
│   ├── fcm_service.py       # FCM 알림
│   └── SERVICES_README.md
│
├── database/                 # DB 스키마 및 마이그레이션
│   ├── schema.sql           # 테이블 생성 SQL
│   ├── add_indexes.sql      # 성능 인덱스
│   ├── DATABASE.md          # DB 문서
│   └── migrations/
│
├── models/                   # Pydantic 모델
│   └── responses.py         # API 응답 모델
│
├── utils/                    # 유틸리티
│   └── common.py            # 공통 함수
│
├── utilities/                # 개발 도구
│   ├── archives/            # 보관용 스크립트
│   └── migrations/          # DB 마이그레이션
│
├── uploads/                  # 업로드 파일 저장소
│   ├── profile_images/
│   └── post_images/
│
├── docs/                     # 문서
│   ├── database_최적화_보고서_2026-01-14.md
│   ├── routers_최적화_보고서_2026-01-14.md
│   ├── services_최적화_보고서_2026-01-14.md
│   └── utilities_정리_보고서_2026-01-15.md
│
└── BACKEND_GUIDE.md         # 종합 가이드 (547 lines)
```

---

## 🔌 API 엔드포인트

### 🔐 인증 (auth.py) - 6개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/auth/signup` | 회원가입 |
| POST | `/api/auth/login` | 로그인 |
| POST | `/api/auth/refresh` | 토큰 갱신 |
| POST | `/api/auth/logout` | 로그아웃 |
| GET | `/api/auth/check-login-id/{login_id}` | 아이디 중복 확인 |
| GET | `/api/auth/check-nickname/{nickname}` | 닉네임 중복 확인 |

### 👤 회원 (members.py) - 8개

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/members/me` | 내 정보 조회 |
| PUT | `/api/members/me` | 내 정보 수정 |
| PUT | `/api/members/me/profile-image` | 프로필 이미지 변경 |
| DELETE | `/api/members/me` | 회원 탈퇴 |
| GET | `/api/members/{member_id}` | 특정 회원 조회 |
| GET | `/api/members/me/stats` | 내 활동 통계 |
| GET | `/api/members/me/badges` | 내 배지 목록 |
| PUT | `/api/members/me/calorie-goal` | 칼로리 목표 설정 |

### 🍽️ 식단 (meals.py) - 8개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/meal` | 식단 기록 생성 |
| GET | `/api/meal` | 식단 기록 목록 |
| GET | `/api/meal/{meal_log_id}` | 식단 상세 조회 |
| PUT | `/api/meal/{meal_log_id}` | 식단 수정 |
| DELETE | `/api/meal/{meal_log_id}` | 식단 삭제 |
| POST | `/api/meal/analyze` | AI 음식 분석 |
| GET | `/api/meal/daily-summary` | 일일 식단 요약 |
| GET | `/api/meal/weekly-chart` | 주간 칼로리 차트 |

### 💪 운동 (exercises.py) - 5개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/exercise` | 운동 기록 생성 |
| GET | `/api/exercise` | 운동 기록 목록 |
| GET | `/api/exercise/{exercise_log_id}` | 운동 상세 조회 |
| PUT | `/api/exercise/{exercise_log_id}` | 운동 수정 |
| DELETE | `/api/exercise/{exercise_log_id}` | 운동 삭제 |

### ⚖️ 체중 (weight.py) - 4개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/weight` | 체중 기록 |
| GET | `/api/weight` | 체중 기록 목록 |
| GET | `/api/weight/chart` | 체중 변화 차트 |
| DELETE | `/api/weight/{weight_log_id}` | 체중 기록 삭제 |

### 🏥 건강 (health.py) - 4개

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/health/diseases` | 질병 목록 |
| GET | `/api/health/allergies` | 알레르기 목록 |
| PUT | `/api/health/me/diseases` | 내 질병 정보 수정 |
| PUT | `/api/health/me/allergies` | 내 알레르기 정보 수정 |

### 📝 커뮤니티 (posts.py) - 7개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/post` | 게시글 작성 |
| GET | `/api/post` | 게시글 목록 |
| GET | `/api/post/{post_id}` | 게시글 상세 |
| PUT | `/api/post/{post_id}` | 게시글 수정 |
| DELETE | `/api/post/{post_id}` | 게시글 삭제 |
| POST | `/api/post/{post_id}/like` | 좋아요 |
| DELETE | `/api/post/{post_id}/like` | 좋아요 취소 |

### 💬 댓글 (comments.py) - 5개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/comment` | 댓글 작성 |
| GET | `/api/comment/{post_id}` | 댓글 목록 |
| PUT | `/api/comment/{comment_id}` | 댓글 수정 |
| DELETE | `/api/comment/{comment_id}` | 댓글 삭제 |
| POST | `/api/comment/{comment_id}/like` | 댓글 좋아요 |

### 🏅 배지 (badges.py) - 3개

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/api/badges` | 전체 배지 목록 |
| GET | `/api/badges/me` | 내 배지 목록 |
| POST | `/api/badges/check` | 배지 조건 확인 |

### 🤖 AI (ai.py) - 2개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/ai/chat` | AI 챗봇 대화 |
| POST | `/api/ai/analyze-food` | AI 음식 분석 |

### 🔔 알림 (notifications.py) - 2개

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/notifications/register-token` | FCM 토큰 등록 |
| POST | `/api/notifications/send` | 푸시 알림 전송 |

**총 엔드포인트**: 60+개

---

## 🗄️ 데이터베이스

### 테이블 구조 (14개)

| 테이블 | 설명 | 주요 컬럼 |
|--------|------|----------|
| **members** | 회원 정보 | member_id, login_id, nickname, email |
| **meal_log** | 식단 기록 | meal_log_id, member_id, meal_type, meal_date |
| **meal_item** | 식단 아이템 | meal_item_id, meal_log_id, food_name, calories_kcal |
| **exercise_log** | 운동 기록 | exercise_log_id, member_id, exercise_type, duration_min |
| **weight_log** | 체중 기록 | weight_log_id, member_id, weight_kg, measured_at |
| **post** | 게시글 | post_id, member_id, title, content, likes_count |
| **comment** | 댓글 | comment_id, post_id, member_id, content |
| **badge** | 배지 정보 | badge_id, badge_name, description, icon_path |
| **member_badge** | 회원 배지 | member_id, badge_id, acquired_at |
| **disease** | 질병 정보 | disease_id, disease_name |
| **allergy** | 알레르기 정보 | allergy_id, allergy_name |
| **member_disease** | 회원 질병 | member_id, disease_id |
| **member_allergy** | 회원 알레르기 | member_id, allergy_id |
| **nutrition_info** | 영양소 정보 | (AI 분석용) |

### 성능 최적화

- **인덱스**: 14개 복합 인덱스 추가 (add_indexes.sql)
- **외래 키**: CASCADE 설정으로 데이터 일관성 보장
- **Soft Delete**: deleted_at 컬럼으로 복구 가능한 삭제

상세 내용: [DATABASE.md](database/DATABASE.md)

---

## 🧩 서비스 레이어

### FoodAnalyzer (AI 음식 분석)

YOLO 객체 탐지 + ResNet 양 추정 + 영양 DB 조회

```python
from services.food_analyzer import get_food_analyzer

analyzer = get_food_analyzer()
results = analyzer.analyze_meal_image("meal.jpg")
# [{food_name: "쌀밥", calories_kcal: 312, ...}, ...]
```

### BadgeAutoAward (배지 자동 수여)

11가지 배지 조건 자동 체크 및 수여

```python
from services.badge_auto_award import BadgeAutoAward

newly_earned = BadgeAutoAward.check_and_award_badges(member_id=123)
# [{"badge_name": "첫 걸음", ...}, ...]
```

### FCMService (푸시 알림)

Firebase Cloud Messaging 푸시 알림

```python
from services.fcm_service import FCMService

FCMService.initialize()
await FCMService.send_notification(
    token="fcm_token",
    title="새로운 댓글",
    body="김철수님이 댓글을 남겼습니다."
)
```

상세 내용: [SERVICES_README.md](services/SERVICES_README.md)

---

## 🔧 개발 도구

### 코드 최적화

- **@handle_db_transaction**: DB 트랜잭션 자동 관리 데코레이터
- **Response Models**: 일관된 API 응답 형식
- **Type Hints**: 타입 안정성 확보

### 테스트 스크립트

```powershell
# DB 연결 테스트
python utilities/archives/tests/test_db_connection.py

# API 테스트
python utilities/archives/tests/test_health_api.py
```

### 시스템 점검

```powershell
# 전체 시스템 감사
python utilities/archives/audits/system_audit.py
```

상세 내용: [utilities/README.md](utilities/README.md)

---

## 📊 최적화 보고서

### Database 최적화 (2026-01-14)
- 파일: 7개 → 2개 (-71%)
- 문서: DATABASE.md 800+ lines 생성
- 인덱스: 14개 복합 인덱스 추가

### Routers 최적화 (2026-01-14)
- auth.py: 454 → 350 lines (-23%)
- weight.py: 276 → 180 lines (-35%)
- README: ROUTERS_README.md 200 lines

### Services 최적화 (2026-01-14)
- badge_auto_award.py: @handle_db_transaction 적용
- 문서: SERVICES_README.md 668 lines
- 코드 품질: 타입 힌트, docstring 추가

### Utilities 정리 (2026-01-15)
- 파일: 32개 → 16개 (-50%)
- 제거: 일회성 스크립트 21개
- 보관: archives/ 폴더 (tests, audits, converters)

상세 내용:
- [database_최적화_보고서.md](docs/database_최적화_보고서_2026-01-14.md)
- [routers_최적화_보고서.md](docs/routers_최적화_보고서_2026-01-14.md)
- [services_최적화_보고서.md](docs/services_최적화_보고서_2026-01-14.md)
- [utilities_정리_보고서.md](docs/utilities_정리_보고서_2026-01-15.md)

---

## 🚀 배포

### 프로덕션 설정

```powershell
# 워커 4개로 실행
uvicorn main:app --host 0.0.0.0 --port 3000 --workers 4

# 또는 Gunicorn 사용
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:3000
```

### 환경 변수 (프로덕션)

```env
# CORS 설정 변경
ALLOWED_ORIGINS=https://yourdomain.com

# JWT 시크릿 키 변경
SECRET_KEY=production-secret-key-here

# DB 연결 최적화
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20
```

### Docker (Optional)

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]
```

---

## 📖 추가 문서

- **종합 가이드**: [BACKEND_GUIDE.md](BACKEND_GUIDE.md) (547 lines)
- **데이터베이스**: [database/DATABASE.md](database/DATABASE.md)
- **API 라우터**: [routers/ROUTERS_README.md](routers/ROUTERS_README.md)
- **서비스 레이어**: [services/SERVICES_README.md](services/SERVICES_README.md)
- **유틸리티**: [utilities/README.md](utilities/README.md)

---

## 🤝 기여

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

---

## 👥 팀

**TTM 개발팀**  
스마트인재개발원 2024

---

**최종 업데이트**: 2026-01-15  
**버전**: 1.0.0
