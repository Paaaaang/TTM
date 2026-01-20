# Render 배포 가이드

## 🚀 Render 무료 배포 (AI 모델 제외)

### 1. Render 계정 생성
https://render.com (GitHub 연동)

### 2. 새 Web Service 생성
- **Repository**: GitHub에 코드 푸시 필요
- **Root Directory**: `backend`
- **Build Command**: `pip install -r requirements.render.txt`
- **Start Command**: `bash start.sh`

### 3. 환경 변수 설정
```env
DATABASE_URL=mysql://user:password@host:3306/ttm_db
JWT_SECRET_KEY=자동생성됨
ENVIRONMENT=production
DISABLE_AI_MODELS=true
```

### 4. MySQL 데이터베이스
**옵션 A: PlanetScale (무료)**
- https://planetscale.com
- MySQL 호환, 무료 5GB

**옵션 B: Render MySQL ($7/월)**
- Render Dashboard에서 추가

### 5. 배포 URL 획득
```
https://ttm-backend-xxxx.onrender.com
```

---

## 📱 iOS 앱 설정

1. `lib/constants/api_constants.dart` 수정:
```dart
static const bool useProductionServer = true;
static const String productionUrl = 'https://ttm-backend-xxxx.onrender.com';
```

2. iPhone에 설치:
```bash
flutter run --release
```

---

## ⚠️ 제약사항 (무료 티어)

### Render 무료:
- 15분 미사용 시 **슬립 모드** (첫 요청 시 15초 대기)
- 월 750시간 무료 (31일 사용 가능)
- AI 모델 **비활성화** (메모리 512MB 제한)

### 해결방법:
1. **AI 기능**: 더미 데이터 반환
2. **슬립 방지**: 5분마다 health check (별도 서비스)
3. **유료 전환**: $7/월 → AI 모델 활성화 가능

---

## 💰 비용 최적화

| 항목 | 무료 | 유료 |
|------|------|------|
| Render Web Service | ✅ 750시간 | $7/월 (2GB 메모리) |
| PlanetScale MySQL | ✅ 5GB | $29/월 |
| **합계** | **무료** | **$7/월** |

---

## 🔧 AI 모델 활성화 (유료)

1. `requirements.render.txt` → `requirements.txt` 사용
2. Render Plan: **Starter ($7/월)**
3. 환경 변수: `DISABLE_AI_MODELS=false`

---

## 📝 다음 단계

1. GitHub 저장소 생성
2. Render 계정 연동
3. PlanetScale MySQL 생성
4. 환경 변수 설정
5. 배포 완료!

도움 필요하면 말씀하세요! 🚀
