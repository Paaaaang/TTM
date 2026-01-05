# TTM Backend API Server

**FastAPI** + MySQL 기반 REST API 서버

## 설치 및 실행

### 1. Python 가상환경 생성 (권장)
```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# Mac/Linux
source venv/bin/activate
```

### 2. 패키지 설치
```bash
pip install -r requirements.txt
```

### 3. 환경 변수 설정
`.env.example` 파일을 `.env`로 복사하고 설정을 수정하세요:
```bash
cp .env.example .env
```

`.env` 파일 수정:
```env
PORT=3000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=ttm_db
JWT_SECRET=your_secret_key
JWT_EXPIRES_DAYS=7
```

### 4. MySQL 데이터베이스 설정
MySQL에 접속하여 스키마를 실행하세요:
```bash
mysql -u root -p < database/schema.sql
```

또는 MySQL Workbench에서 `database/schema.sql` 파일을 실행하세요.

### 5. 서버 실행
```bash
# 개발 모드 (자동 재시작)
python main.py

# 또는 uvicorn 직접 실행
uvicorn main:app --host 0.0.0.0 --port 3000 --reload
```

서버가 http://localhost:3000 에서 실행됩니다.

## API 문서
FastAPI는 자동으로 API 문서를 생성합니다:
- **Swagger UI**: http://localhost:3000/docs
- **ReDoc**: http://localhost:3000/redoc

## API 엔드포인트

### 회원가입
```
POST /api/auth/signup
Content-Type: application/json

{
  "username": "testuser",
  "password": "1234",
  "email": "test@example.com",
  "name": "홍길동"
}
```

### 로그인
```
POST /api/auth/login
Content-Type: application/json

{
  "username": "test",
  "password": "1234"
}
```

응답:
```json
{
  "user": {
    "id": "1",
    "username": "test",
    "email": "test@test.com",
    "name": "테스트 사용자"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## 테스트 계정
- **아이디**: test
- **비밀번호**: 1234

## Flutter 앱 연동
Flutter 앱의 `lib/constants/api_config.dart`에서 baseUrl을 확인하세요:
```dart
static const String baseUrl = 'http://localhost:3000';
```

**Android 에뮬레이터**: `http://10.0.2.2:3000`
**실제 기기**: 컴퓨터의 로컬 IP 주소 사용 (예: `http://192.168.0.10:3000`)

## 디렉토리 구조
```
backend/
├── config/
│   └── database.py      # MySQL 연결 설정
├── routers/
│   └── auth.py          # 인증 라우터
├── database/
│   └── schema.sql       # DB 스키마
├── .env.example         # 환경 변수 예제
├── main.py              # FastAPI 앱 진입점
└── requirements.txt     # Python 패키지 목록
```

## 보안 주의사항
- `.env` 파일은 절대 git에 커밋하지 마세요
- JWT_SECRET은 강력한 랜덤 문자열로 변경하세요
- 프로덕션에서는 HTTPS를 사용하세요
