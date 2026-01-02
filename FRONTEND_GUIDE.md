# TTM 앱 프론트엔드 개발 가이드

## 📱 현재 구현된 화면

### ✅ 완료된 화면
1. **Splash Screen** - 앱 시작 화면
2. **Onboarding Screen** - 온보딩 화면 (온보딩.png 기반)
3. **Login Screen** - 로그인 화면 (로그인.png 기반)
4. **Main Screen** - 하단 네비게이션 바가 있는 메인 화면
5. **Home Screen** - 홈 대시보드 (기능 구현됨)
6. **Exercise Screen** - 운동 화면 (운동.png 참조)
7. **Diet Screen** - 식단 화면 (식단.png 참조)
8. **Community Screen** - 커뮤니티 화면 (커뮤니티 홈.png 참조)
9. **Profile Screen** - 내정보 화면 (내정보.png 참조)

### 🚧 구현 예정 화면

#### 운동 관련
- [ ] Exercise Add Screen - 운동 기록 추가 (운동 기록 추가.png)

#### 식단 관련
- [ ] Diet Add Screen - 식단 추가
  - 아침 (식단추가_아침.png)
  - 점심 (식단추가_점심.png)
  - 저녁 (식단추가_저녁.png)
  - 간식 (식단추가_간식.png)
- [ ] Photo Capture Screen - 사진 촬영 (사진 촬영.png)

#### 커뮤니티 관련
- [ ] Community Post Screen - 게시물 상세 (커뮤니티_게시물.png)
- [ ] Community Create Screen - 게시물 작성 (커뮤글.png)
- [ ] Community Friend Add - 친구 추가 (커뮤니티_친구추가.png)

#### 통계 관련
- [ ] Weekly Stats Screen - 주간 통계 (주간 통계1.png, 주간 통계2.png)
- [ ] Monthly Stats Screen - 월간 통계 (월간 통계1.png, 월간 통계2.png)

#### 프로필 관련
- [ ] Badges Screen - 뱃지 화면 (내정보 뱃지1-4.png)
- [ ] Settings Screen - 사용자 설정 (사용자 설정.png)
  - 친구 목록 (사용자 설정(친구 목록).png)
  - 친구 추가 (사용자 설정(친구 목록_친구 추가).png)
  - 언어 설정 (사용자 설정(언어 설정).png)
  - 도움말 (사용자 설정(도움말).png)
  - 로그아웃 (사용자 설정(로그아웃).png)
  - 회원 탈퇴 (사용자 설정(회원 탈퇴).png)

#### AI 관련
- [ ] AI Coach Screen - AI 영양 코치 (AI 영양 코치.png)

## 📦 설치된 패키지

### 상태 관리
- `provider: ^6.1.1` - 상태 관리

### 네비게이션
- `go_router: ^14.6.2` - 라우팅

### HTTP & API
- `http: ^1.2.2` - HTTP 클라이언트
- `dio: ^5.7.0` - 고급 HTTP 클라이언트

### 로컬 저장소
- `shared_preferences: ^2.3.3` - 간단한 키-값 저장소
- `sqflite: ^2.4.1` - SQLite 데이터베이스
- `path_provider: ^2.1.5` - 파일 시스템 경로

### 이미지 처리
- `image_picker: ^1.1.2` - 이미지 선택/촬영
- `cached_network_image: ^3.4.1` - 이미지 캐싱

### 날짜 & 시간
- `intl: ^0.19.0` - 국제화 및 포맷팅

### UI 컴포넌트
- `flutter_svg: ^2.0.10+1` - SVG 이미지
- `google_fonts: ^6.2.1` - 구글 폰트
- `fl_chart: ^0.70.1` - 차트 라이브러리

## 🎨 디자인 시스템

### 색상 (AppColors)
- **Primary**: #6C63FF (메인 브랜드 색상)
- **Secondary**: #4CAF50 (보조 색상 - 식단/성공)
- **Accent**: #FF6B6B (강조 색상)
- **Background**: #F5F5F5
- **Text Primary**: #333333
- **Text Secondary**: #666666

### 공통 UI 패턴
1. **카드**: 흰색 배경, 12px 라운드, 그림자
2. **버튼**: 56px 높이, 12px 라운드
3. **간격**: 8, 12, 16, 24px 단위 사용

## 📁 프로젝트 구조

```
lib/
├── main.dart                        # 앱 진입점
├── constants/
│   ├── app_colors.dart             # 색상 상수
│   ├── app_strings.dart            # 문자열 상수
│   └── README.md
├── routes/
│   ├── app_routes.dart             # 라우트 정의
│   └── README.md
├── screens/
│   ├── splash_screen.dart          # ✅ 스플래시
│   ├── onboarding_screen.dart      # ✅ 온보딩
│   ├── login_screen.dart           # ✅ 로그인
│   ├── main_screen.dart            # ✅ 메인 (네비게이션)
│   ├── home_screen.dart            # ✅ 홈
│   ├── exercise_screen.dart        # ✅ 운동
│   ├── diet_screen.dart            # ✅ 식단
│   ├── community_screen.dart       # ✅ 커뮤니티
│   ├── profile_screen.dart         # ✅ 프로필
│   └── README.md
├── widgets/                         # 재사용 가능한 위젯
├── models/                          # 데이터 모델
├── services/                        # API 서비스
├── providers/                       # 상태 관리
└── utils/                          # 유틸리티

assets/
├── images/                          # UI 디자인 이미지 (PDF/UI에서 복사됨)
└── icons/                          # 아이콘
```

## 🚀 다음 개발 단계

### Phase 1: 기본 화면 구현 (현재 단계)
- [x] 프로젝트 구조 설정
- [x] 패키지 설치
- [x] UI 이미지 assets 복사
- [x] 기본 화면 레이아웃
- [x] 네비게이션 설정

### Phase 2: 데이터 모델 구현
- [ ] 데이터베이스 스키마에 따른 모델 클래스 생성
- [ ] API 서비스 레이어 구축

### Phase 3: 상세 화면 구현
- [ ] 운동 기록 추가/수정 화면
- [ ] 식단 기록 추가/수정 화면
- [ ] 커뮤니티 게시물 작성/상세 화면
- [ ] 통계 화면 (차트 포함)
- [ ] 설정 화면 세부 기능

### Phase 4: 기능 통합
- [ ] 상태 관리 구현
- [ ] API 연동
- [ ] 로컬 데이터베이스 연동
- [ ] 이미지 업로드 기능

### Phase 5: AI 기능
- [ ] AI 영양 코치 화면
- [ ] AI API 연동

### Phase 6: 최적화 및 테스트
- [ ] 성능 최적화
- [ ] 에러 처리
- [ ] 사용자 경험 개선
- [ ] 테스트 작성

## 💡 개발 팁

1. **UI 디자인 참고**: `assets/images/` 폴더의 PNG 파일들을 참고하여 구현
2. **일관성 유지**: `AppColors`와 공통 UI 패턴 사용
3. **재사용성**: 반복되는 UI 컴포넌트는 `widgets/` 폴더에 분리
4. **상태 관리**: Provider 패턴 사용 권장
5. **라우팅**: 화면 추가 시 `routes/app_routes.dart`와 `main.dart` 업데이트

## 🔧 실행 방법

```bash
# 패키지 설치
flutter pub get

# 앱 실행 (Windows)
flutter run -d windows

# 앱 실행 (Android)
flutter run -d android

# 앱 실행 (iOS)
flutter run -d ios
```

## 📝 참고 문서
- PDF 폴더의 화면설계서
- PDF 폴더의 데이터베이스요구사항분석서
- PDF 폴더의 테이블명세서
