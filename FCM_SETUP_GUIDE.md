# 🔔 TTM 푸시 알림 설정 가이드

## 📋 개요
TTM 앱에 Firebase Cloud Messaging(FCM)을 사용한 푸시 알림 기능이 추가되었습니다.

### 🎯 알림 기능
- ✅ 게시글에 댓글 작성 시 알림
- ✅ 게시글에 대댓글 작성 시 알림
- ✅ 게시글 좋아요 시 알림
- ✅ 카메라 권한 요청
- ✅ 블루투스 권한 요청
- ✅ 알림 권한 요청

---

## 🔧 1. Firebase 프로젝트 설정

### 1-1. Firebase Console에서 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `TTM` 입력
4. Google Analytics 활성화 (선택)
5. 프로젝트 생성 완료

---

## 📱 2. Android 앱 설정

### 2-1. Firebase에 Android 앱 추가
1. Firebase Console → 프로젝트 설정 → "Android 앱 추가"
2. Android 패키지 이름: `com.example.ttm` 입력
3. 앱 닉네임: `TTM Android` (선택)
4. `google-services.json` 파일 다운로드
5. 다운로드한 파일을 `android/app/` 폴더에 복사

### 2-2. google-services.json 배치
```
ttm/
  android/
    app/
      google-services.json  ← 여기에 배치
      build.gradle.kts
```

---

## 🍎 3. iOS 앱 설정

### 3-1. Firebase에 iOS 앱 추가
1. Firebase Console → 프로젝트 설정 → "iOS 앱 추가"
2. iOS 번들 ID: `com.example.ttm` 입력
3. 앱 닉네임: `TTM iOS` (선택)
4. `GoogleService-Info.plist` 파일 다운로드
5. Xcode에서 `Runner` 폴더에 파일 추가
   - `ios/Runner` 폴더를 Xcode에서 열기
   - `GoogleService-Info.plist`를 `Runner` 폴더로 드래그
   - "Copy items if needed" 체크

### 3-2. APNs 인증 키 설정 (필수)
1. [Apple Developer](https://developer.apple.com/account/resources/authkeys/list) 접속
2. "Keys" → "+" 버튼 클릭
3. Key Name: `TTM APNs Key`
4. "Apple Push Notifications service (APNs)" 체크
5. 키 다운로드 (.p8 파일)
6. Firebase Console → 프로젝트 설정 → Cloud Messaging → iOS 앱 설정
7. APNs 인증 키 업로드
   - Key ID 입력
   - Team ID 입력 (Apple Developer Membership)
   - .p8 파일 업로드

---

## 🔐 4. 백엔드 Firebase Admin SDK 설정

### 4-1. 서비스 계정 키 다운로드
1. Firebase Console → 프로젝트 설정 → 서비스 계정
2. "새 비공개 키 생성" 클릭
3. JSON 파일 다운로드
4. 파일 이름을 `firebase-credentials.json`으로 변경
5. `backend/` 폴더에 배치

### 4-2. 파일 배치
```
ttm/
  backend/
    firebase-credentials.json  ← 여기에 배치
    main.py
    requirements.txt
```

### 4-3. .gitignore에 추가 (보안)
`backend/.gitignore` 파일에 다음 추가:
```
firebase-credentials.json
google-services.json
GoogleService-Info.plist
```

---

## 💾 5. 데이터베이스 설정

### 5-1. fcm_token 컬럼 추가
터미널에서 실행:
```bash
cd backend
python add_fcm_token.py
```

출력 예시:
```
📝 fcm_token 컬럼 추가 중...
✅ fcm_token 컬럼이 추가되었습니다.
```

---

## 📦 6. 패키지 설치

### 6-1. Flutter 패키지 설치
```bash
flutter pub get
```

### 6-2. Python 패키지 설치
```bash
cd backend
pip install firebase-admin
```

---

## 🚀 7. 앱 실행 및 테스트

### 7-1. 백엔드 서버 실행
```bash
cd backend
python main.py
```

### 7-2. Flutter 앱 실행
```bash
flutter run
```

### 7-3. 권한 요청 확인
앱 첫 실행 시 다음 권한 요청 팝업이 표시됩니다:
- ✅ 알림 권한
- ✅ 카메라 권한
- ✅ 블루투스 권한

### 7-4. FCM 토큰 등록 확인
로그인 후 자동으로 FCM 토큰이 서버에 등록됩니다.

백엔드 로그 확인:
```
✅ FCM 토큰 등록: member_id=1, token=dXXXXXXXXXXXXXXXXXXX...
```

### 7-5. 알림 테스트
1. **댓글 알림 테스트**
   - 사용자 A가 게시글 작성
   - 사용자 B가 댓글 작성
   - 사용자 A에게 알림 도착

2. **좋아요 알림 테스트**
   - 사용자 A가 게시글 작성
   - 사용자 B가 좋아요 클릭
   - 사용자 A에게 알림 도착

3. **테스트 API 사용**
   ```bash
   curl -X POST "http://localhost:3000/api/notifications/test" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -d '{
       "title": "테스트 알림",
       "body": "알림 기능이 정상 작동합니다!"
     }'
   ```

---

## 🔍 8. 문제 해결

### 8-1. 알림이 오지 않는 경우

**Android**
- `google-services.json` 파일 위치 확인
- 패키지 이름 일치 확인 (`com.example.ttm`)
- 앱 재설치 후 테스트

**iOS**
- `GoogleService-Info.plist` 파일 위치 확인
- APNs 인증 키 업로드 확인
- Xcode에서 "Push Notifications" capability 추가
- Xcode에서 "Background Modes" → "Remote notifications" 체크

**공통**
- Firebase Admin SDK 초기화 확인
- FCM 토큰이 DB에 저장되었는지 확인
- 백엔드 로그 확인

### 8-2. 권한 요청이 표시되지 않는 경우
- 앱 삭제 후 재설치
- 기기 설정 → 앱 → TTM → 권한 초기화

### 8-3. Firebase 초기화 오류
```
[core/no-app] No Firebase App '[DEFAULT]' has been created
```
**해결 방법:**
- `google-services.json` (Android) 또는 `GoogleService-Info.plist` (iOS) 파일 확인
- 앱 재빌드: `flutter clean && flutter pub get && flutter run`

---

## 📝 9. API 엔드포인트

### FCM 토큰 등록
```
POST /api/notifications/token
Authorization: Bearer {token}
Content-Type: application/json

{
  "fcm_token": "dXXXXXXXXXXXXXXXXXXX..."
}
```

### 테스트 알림 전송
```
POST /api/notifications/test
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "테스트",
  "body": "알림 테스트 메시지"
}
```

### FCM 토큰 삭제 (로그아웃)
```
DELETE /api/notifications/token
Authorization: Bearer {token}
```

---

## ✅ 10. 체크리스트

### Firebase Console
- [ ] Firebase 프로젝트 생성
- [ ] Android 앱 추가 (`com.example.ttm`)
- [ ] iOS 앱 추가 (`com.example.ttm`)
- [ ] APNs 인증 키 업로드 (iOS)
- [ ] 서비스 계정 키 다운로드

### 파일 배치
- [ ] `android/app/google-services.json`
- [ ] `ios/Runner/GoogleService-Info.plist`
- [ ] `backend/firebase-credentials.json`

### 데이터베이스
- [ ] `members.fcm_token` 컬럼 추가

### 패키지 설치
- [ ] Flutter 패키지 설치 (`flutter pub get`)
- [ ] Python 패키지 설치 (`pip install firebase-admin`)

### 테스트
- [ ] 앱 실행 시 권한 요청 확인
- [ ] FCM 토큰 등록 확인
- [ ] 댓글 알림 테스트
- [ ] 좋아요 알림 테스트

---

## 📚 참고 자료
- [Firebase Cloud Messaging 문서](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [Firebase Admin SDK (Python)](https://firebase.google.com/docs/admin/setup)
- [APNs 설정 가이드](https://firebase.google.com/docs/cloud-messaging/ios/client)

---

## 🎉 완료!
모든 설정이 완료되었습니다. 이제 사용자들은 게시글 활동에 대한 실시간 알림을 받을 수 있습니다!
