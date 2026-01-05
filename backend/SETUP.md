# TTM Backend - MySQL 설정 및 실행 가이드

## 📦 필수 요구사항
- Python 3.8 이상
- MySQL 8.0 이상
- pip (Python 패키지 관리자)

## 🗄️ MySQL 데이터베이스 설정

### 1. MySQL 접속
```bash
mysql -u we0123 -p
# 비밀번호: cand4567
```

### 2. 데이터베이스 및 테이블 생성
```bash
# backend/database/schema.sql 실행
mysql -u we0123 -p < backend/database/schema.sql

# 또는 MySQL 내에서
source C:/Users/smhrd/Desktop/App/ttm/backend/database/schema.sql
```

### 3. 테이블 확인
```sql
USE ttm_db;
SHOW TABLES;
DESC users;
SELECT * FROM users;
```

## 🚀 백엔드 서버 실행

### 1. Python 가상환경 생성 및 활성화
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

### 2. 필요한 패키지 설치
```powershell
pip install -r requirements.txt
```

### 3. 환경 변수 확인
`.env` 파일이 이미 생성되어 있습니다:
```
DB_HOST=localhost
DB_USER=we0123
DB_PASSWORD=cand4567
DB_NAME=ttm_db
DB_PORT=3306
```

### 4. 서버 실행
```powershell
# 개발 모드 (자동 재시작)
python main.py

# 또는 uvicorn 직접 실행
uvicorn main:app --host 0.0.0.0 --port 3000 --reload
```

### 5. 서버 확인
브라우저에서 접속:
- API 문서: http://localhost:3000/docs
- API 루트: http://localhost:3000/

## 📡 API 엔드포인트

### 회원 관리
- `POST /api/auth/signup` - 회원가입
- `POST /api/auth/login` - 로그인
- `POST /api/auth/logout` - 로그아웃
- `GET /api/auth/check-nickname/{nickname}` - 닉네임 중복 확인
- `GET /api/auth/check-username/{username}` - 아이디 중복 확인

### 회원가입 요청 예시
```json
{
  "username": "testuser",
  "nickname": "테스트유저",
  "password": "Test1234!@",
  "email": "test@example.com",
  "name": "홍길동",
  "phone": "010-1234-5678",
  "birthdate": "1990-01-01"
}
```

## 🔧 문제 해결

### MySQL 접속 오류
```powershell
# MySQL 서비스 시작 (관리자 권한)
net start MySQL80

# MySQL 서비스 상태 확인
sc query MySQL80
```

### 포트 충돌 (3000 포트 사용중)
```powershell
# 포트 사용 프로세스 확인
netstat -ano | findstr :3000

# 프로세스 종료 (PID 확인 후)
taskkill /PID [프로세스ID] /F
```

### 패키지 설치 오류
```powershell
# pip 업그레이드
python -m pip install --upgrade pip

# 특정 패키지 재설치
pip install --force-reinstall mysql-connector-python
```

## 🧪 테스트

### 데이터베이스 연결 테스트
```powershell
python -c "from config.database import test_connection; test_connection()"
```

### API 테스트 (curl)
```powershell
# 회원가입
curl -X POST "http://localhost:3000/api/auth/signup" ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"test123\",\"nickname\":\"테스터\",\"password\":\"Test1234!@\",\"email\":\"test@test.com\",\"name\":\"테스트\"}"

# 닉네임 중복 확인
curl "http://localhost:3000/api/auth/check-nickname/테스터"

# 아이디 중복 확인
curl "http://localhost:3000/api/auth/check-username/test123"
```

## 📝 Flutter 앱에서 연결
`lib/services/auth_service.dart`의 baseUrl 확인:
```dart
static const String baseUrl = 'http://localhost:3000/api/auth';
```

실제 기기 테스트 시:
```dart
static const String baseUrl = 'http://[PC_IP주소]:3000/api/auth';
```

## 💡 주의사항
1. 가상환경을 항상 활성화한 상태에서 서버 실행
2. MySQL 서비스가 실행 중인지 확인
3. 방화벽에서 3000 포트 허용
4. 프로덕션 환경에서는 .env의 JWT_SECRET 변경 필수
