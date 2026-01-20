# TTM Render 배포 가이드

## ✅ 완료된 작업

### 1. Git 저장소 정리

- ✅ AI 모델 파일 (2GB+) Git 추적에서 제거
- ✅ `.gitignore` 업데이트 (AI 모델, 가상환경, 빌드 파일 제외)
- ✅ 깨끗한 브랜치로 GitHub에 push 완료
- ✅ 저장소 크기: ~5.78MB (배포 가능한 크기)

### 2. 저장소 정보

- **Repository**: https://github.com/Paaaaang/TTM
- **Branch**: master (clean-deploy와 동기화됨)
- **Backend Path**: `/backend`

---

## 🚀 Render 배포 단계

### Step 1: Render 계정 생성 및 로그인

1. https://render.com 접속
2. **Sign Up** → **Continue with GitHub** 선택
3. GitHub 계정 연동 및 인증

### Step 2: 새 Web Service 생성

1. Dashboard → **New +** → **Web Service** 클릭
2. **Connect a repository** 섹션에서:
   - GitHub 저장소 연결 (Render에 권한 부여)
   - `Paaaaang/TTM` 저장소 선택
3. 배포 설정:
   ```
   Name: ttm-backend
   Region: Singapore (또는 가까운 지역)
   Branch: master
   Root Directory: backend
   Runtime: Python 3
   ```

### Step 3: 빌드 및 시작 명령 설정

```bash
Build Command: pip install -r requirements.render.txt
Start Command: bash start.sh
```

### Step 4: 환경 변수 설정

**Environment Variables** 섹션에서 다음 변수 추가:

#### 필수 환경 변수

| Key                 | Value                                    | 설명                                         |
| ------------------- | ---------------------------------------- | -------------------------------------------- |
| `PYTHON_VERSION`    | `3.11`                                   | Python 버전                                  |
| `DATABASE_URL`      | `mysql://user:password@host:3306/ttm_db` | MySQL 연결 정보                              |
| `JWT_SECRET_KEY`    | `[Generate]`                             | JWT 토큰 암호화 키 (Auto-generate 버튼 클릭) |
| `ENVIRONMENT`       | `production`                             | 배포 환경                                    |
| `DISABLE_AI_MODELS` | `true`                                   | AI 모델 비활성화 (메모리 절약)               |

#### 선택적 환경 변수

| Key                    | Value     | 설명                                    |
| ---------------------- | --------- | --------------------------------------- |
| `GOOGLE_API_KEY`       | `AIza...` | Gemini AI API 키 (AI 코치 기능 사용 시) |
| `FIREBASE_CREDENTIALS` | `{...}`   | Firebase 푸시 알림 인증 정보            |

### Step 5: 플랜 선택

```
Free Plan: 무료 (512MB RAM, AI 모델 제외)
Starter Plan: $7/월 (2GB RAM, AI 모델 가능)
```

**권장**: AI 기능 없이 Free Plan으로 시작

### Step 6: 배포 시작

1. **Create Web Service** 버튼 클릭
2. 배포 진행 상황 모니터링 (Logs 탭)
3. 배포 완료 시 URL 확인: `https://ttm-backend-xxxx.onrender.com`

---

## 🗄️ 데이터베이스 설정

### Option A: PlanetScale (무료, 권장)

1. https://planetscale.com 접속 및 가입
2. **New database** 클릭
   - Name: `ttm-db`
   - Region: AWS ap-northeast-2 (Seoul)
3. **Connect** 버튼 → **Create password** → **New password**
4. Connection string 복사:
   ```
   mysql://user:password@aws.connect.psdb.cloud/ttm-db?ssl={"rejectUnauthorized":true}
   ```
5. Render 환경 변수 `DATABASE_URL`에 붙여넣기
6. PlanetScale Console에서 SQL 실행:
   ```sql
   -- backend/database/schema.sql 내용 복사하여 실행
   ```

### Option B: Render MySQL ($7/월)

1. Render Dashboard → **New +** → **PostgreSQL** (또는 MySQL)
2. 데이터베이스 생성 후 내부 연결 URL 복사
3. Render Web Service 환경 변수에 추가

### Option C: 기존 MySQL 서버

- 외부에서 접근 가능한 MySQL 서버 정보 사용
- 방화벽 설정: Render IP 허용 필요

---

## 📱 Flutter 앱 연동

### 1. API 엔드포인트 설정

[lib/constants/api_constants.dart](lib/constants/api_constants.dart) 파일 수정:

```dart
class ApiConstants {
  // Render 배포 URL로 변경
  static const String baseUrl = 'https://ttm-backend-xxxx.onrender.com';

  // 또는 환경 변수 사용
  static const bool useProductionServer = true;
  static const String productionUrl = 'https://ttm-backend-xxxx.onrender.com';
  static const String developmentUrl = 'http://localhost:8000';

  static String get apiUrl => useProductionServer ? productionUrl : developmentUrl;
}
```

### 2. iOS 빌드 및 테스트

```bash
# iOS 시뮬레이터
flutter run

# 실제 iPhone에 설치
flutter run --release -d <device-id>

# APK 빌드 (Android)
flutter build apk --release
```

---

## 🔍 배포 확인 및 테스트

### 1. 헬스 체크

```bash
curl https://ttm-backend-xxxx.onrender.com/
# 응답: {"status": "healthy", "message": "TTM Backend API"}
```

### 2. API 문서 확인

브라우저에서 접속:

```
https://ttm-backend-xxxx.onrender.com/docs
```

### 3. 회원가입/로그인 테스트

```bash
# 회원가입
curl -X POST https://ttm-backend-xxxx.onrender.com/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!","nickname":"테스터"}'

# 로그인
curl -X POST https://ttm-backend-xxxx.onrender.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}'
```

---

## ⚠️ 주의사항

### AI 모델 제외 배포

현재 설정은 **AI 모델 파일을 포함하지 않습니다**:

- YOLO 음식 인식: Mock 데이터로 대체
- 영양 분석: 데이터베이스 기반 분석만 제공
- Gemini AI 코치: Google API 키 필요 (별도)

### AI 모델 포함 배포 (Starter Plan 이상)

AI 모델을 사용하려면:

1. Render Starter Plan ($7/월) 선택 (2GB RAM)
2. `requirements.txt` 사용 (requirements.render.txt 대신)
3. AI 모델 파일을 외부 스토리지에 저장 후 다운로드
   ```python
   # startup 시 AI 모델 다운로드
   import requests
   model_url = "https://your-storage.com/model.pt"
   response = requests.get(model_url)
   with open("model.pt", "wb") as f:
       f.write(response.content)
   ```

### Free Plan 제한사항

- 15분 무활동 시 자동 슬립 (첫 요청 시 재시작, ~30초 소요)
- 월 750시간 실행 시간 제한
- 512MB RAM (AI 모델 불가)

---

## 🛠️ 문제 해결

### 배포 실패 시

1. Render Logs 확인
2. Build Command 오류:
   ```
   pip install --upgrade pip
   pip install -r requirements.render.txt
   ```
3. 데이터베이스 연결 오류:
   - `DATABASE_URL` 환경 변수 확인
   - 네트워크 연결 확인

### AI 기능 오류

1. Google API Key 설정 확인
2. Firebase 인증 정보 확인
3. Logs에서 오류 메시지 확인

### 슬로우 콜드 스타트

- Free Plan은 15분 무활동 후 슬립
- Paid Plan 사용 또는 Keep-Alive 스크립트 설정

---

## 📞 지원

- **Render 문서**: https://render.com/docs
- **TTM Backend Guide**: [backend/BACKEND_GUIDE.md](backend/BACKEND_GUIDE.md)
- **API 문서**: https://ttm-backend-xxxx.onrender.com/docs

---

## 🎯 다음 단계

1. ✅ Render Web Service 생성
2. ✅ 환경 변수 설정
3. ✅ 데이터베이스 연결
4. ✅ Flutter 앱 API URL 업데이트
5. ✅ 배포 테스트
6. 🔄 도메인 연결 (선택사항)
7. 🔄 CI/CD 자동 배포 설정

## 배포 완료 체크리스트

- [ ] Render 계정 생성
- [ ] GitHub 저장소 연동
- [ ] Web Service 생성 (backend 디렉토리)
- [ ] 환경 변수 설정 (DATABASE_URL, JWT_SECRET_KEY)
- [ ] 데이터베이스 생성 및 연결
- [ ] 배포 성공 확인 (헬스 체크)
- [ ] Flutter 앱 API URL 업데이트
- [ ] 앱에서 회원가입/로그인 테스트
- [ ] 주요 기능 테스트

---

**배포 문의**: AI 모델 포함 배포, 커스텀 도메인 설정 등 추가 지원이 필요하면 말씀해주세요.
