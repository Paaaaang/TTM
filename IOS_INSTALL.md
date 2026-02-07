# iOS 개발용 설치 가이드 (시연용)

## 📱 무료로 아이폰에 설치하기

### 준비물

- iPhone (USB 케이블)
- Mac 또는 Windows PC
- 무료 Apple ID

---

## 1️⃣ Xcode 설정 (Mac)

### Step 1: Xcode 설치

```bash
# App Store에서 Xcode 설치
# 또는 터미널에서
xcode-select --install
```

### Step 2: Apple ID 추가

1. Xcode 열기
2. `Xcode > Preferences > Accounts`
3. `+` 버튼 → Apple ID 추가

### Step 3: 프로젝트 열기

```bash
cd /Users/smhrd/Desktop/App/ttm
open ios/Runner.xcworkspace
```

### Step 4: 서명 설정

1. Runner 프로젝트 선택
2. `Signing & Capabilities` 탭
3. **Team**: Apple ID 선택
4. **Bundle Identifier**: 고유한 ID로 변경
   - 예: `com.yourname.ttm`

### Step 5: 빌드 & 설치

```bash
# iPhone USB 연결 후
flutter run --release
```

---

## 2️⃣ Windows에서 설치

### 필요 사항

- iTunes 설치
- USB 드라이버 설치

### 설치 방법

```powershell
# iPhone USB 연결
flutter run --release

# 또는 IPA 파일 생성
flutter build ios --release --no-codesign
```

### iPhone에서 신뢰 설정

1. **설정** > **일반** > **VPN 및 기기 관리**
2. 개발자 앱 섹션에서 Apple ID 탭
3. **"신뢰"** 버튼 클릭

---

## ⚠️ 제약사항

### 무료 Apple ID:

- **7일 후 만료** (재설치 필요)
- **최대 3개 기기**까지 설치 가능

### 해결 방법:

- 7일마다 재설치 (1분 소요)
- 또는 Apple Developer 가입 ($99/년)

---

## 🔥 빠른 설치 (한 줄)

```bash
# Mac에서
flutter run --release

# Windows에서 (사전에 iTunes 설치 필요)
flutter run --release
```

---

## 💡 시연 팁

### 배포 전 체크리스트:

1. ✅ 백엔드 서버 실행 중
2. ✅ `api_constants.dart`에 서버 URL 설정
3. ✅ iPhone WiFi = PC WiFi (같은 네트워크)
4. ✅ 앱 신뢰 설정 완료

### 시연 중 오류:

- **"연결 실패"**: 서버 URL 확인
- **"개발자를 신뢰할 수 없음"**: 설정 > 기기 관리에서 신뢰
- **7일 후 실행 안됨**: `flutter run --release` 재실행

---

## 📞 문제 해결

### Q: Mac이 없는데요?

**A**: Windows에서도 가능하지만, Mac이 훨씬 편합니다.

### Q: 7일마다 재설치 귀찮아요

**A**: Apple Developer ($99/년) 가입하면 1년 유효

### Q: 다른 사람 iPhone에도 설치 가능?

**A**: 가능! 그 사람의 iPhone을 USB로 연결하고 같은 방법으로 설치

---
