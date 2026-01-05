# 소셜 로그인 설정 가이드

## 📌 개발자 등록 및 키 발급

### 1. 카카오 로그인
1. [Kakao Developers](https://developers.kakao.com/) 접속
2. **내 애플리케이션 > 애플리케이션 추가하기**
3. 앱 이름: `TTM` 입력
4. **앱 키 확인**:
   - 네이티브 앱 키 복사 (Android/iOS용)
   - JavaScript 키 복사 (Web용)
5. **플랫폼 설정**:
   - Android: 패키지명 `com.example.ttm`, 키 해시 등록
   - iOS: Bundle ID `com.example.ttm` 등록
6. **카카오 로그인 활성화**:
   - 제품 설정 > 카카오 로그인 > 활성화 설정 ON
   - Redirect URI: `kakao{NATIVE_APP_KEY}://oauth`

### 2. 네이버 로그인
1. [NAVER Developers](https://developers.naver.com/apps/#/register) 접속
2. **애플리케이션 등록**
3. 사용 API: **네이버 로그인** 선택
4. 제공 정보: 이메일, 닉네임, 프로필사진 선택
5. **서비스 환경**:
   - Android 패키지명: `com.example.ttm`
   - iOS URL Scheme: `naverlogin{CLIENT_ID}`
6. **Client ID / Client Secret 복사**

### 3. 구글 로그인
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. **프로젝트 생성**: `TTM`
3. **API 및 서비스 > OAuth 동의 화면**:
   - 외부 사용자 선택
   - 앱 이름: `TTM`
   - 범위: email, profile 추가
4. **사용자 인증 정보 > OAuth 2.0 클라이언트 ID 만들기**:
   - Android: 패키지명 `com.example.ttm`, SHA-1 인증서 지문 등록
   - iOS: Bundle ID `com.example.ttm` 등록
   - 웹: 승인된 리디렉션 URI 추가
5. **클라이언트 ID 복사** (플랫폼별로 다름)

---

## 🔧 Flutter 네이티브 설정

### Android 설정

#### 1. 카카오 (android/app/build.gradle)
```gradle
android {
    defaultConfig {
        manifestPlaceholders = [KAKAO_NATIVE_APP_KEY: "your_kakao_native_app_key"]
    }
}
```

#### 2. 카카오 (android/app/src/main/AndroidManifest.xml)
```xml
<activity
    android:name="com.kakao.sdk.flutter.AuthCodeCustomTabsActivity"
    android:exported="true">
    <intent-filter android:label="flutter_web_auth">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="kakao{YOUR_NATIVE_APP_KEY}" android:host="oauth"/>
    </intent-filter>
</activity>
```

#### 3. 네이버 (android/app/src/main/AndroidManifest.xml)
```xml
<activity
    android:name="com.nhn.android.naverlogin.ui.view.OAuthLoginActivity"
    android:exported="true"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
```

### iOS 설정

#### 1. 카카오 (ios/Runner/Info.plist)
```xml
<key>KAKAO_NATIVE_APP_KEY</key>
<string>your_kakao_native_app_key</string>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kakao{YOUR_NATIVE_APP_KEY}</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>kakaokompassauth</string>
    <string>kakaolink</string>
</array>
```

#### 2. 네이버 (ios/Runner/Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>naverlogin{YOUR_CLIENT_ID}</string>
        </array>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>naversearchapp</string>
    <string>naversearchthirdlogin</string>
</array>
```

#### 3. 구글 (ios/Runner/Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.{YOUR_CLIENT_ID}</string>
        </array>
    </dict>
</array>
```

---

## 💻 Flutter 코드 구현

### lib/services/social_auth_service.dart 생성 예정

각 플랫폼의 앱 키/클라이언트 ID를 받으면:
1. 초기화 코드 추가
2. 로그인/로그아웃 메서드 구현
3. 사용자 정보 가져오기 구현

---

## ⚠️ 주의사항

1. **개발자 등록 승인**: 보통 1~3일 소요 (카카오/네이버)
2. **SHA-1 지문**: Android Studio에서 생성 필요
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
3. **Bundle ID / 패키지명**: 실제 앱과 동일해야 함
4. **프로덕션 키**: 릴리즈 빌드용 별도 키 필요

---

## 📝 TODO
- [ ] 카카오 개발자 등록 및 앱 키 발급
- [ ] 네이버 개발자 등록 및 클라이언트 ID 발급
- [ ] 구글 OAuth 클라이언트 ID 발급
- [ ] Android/iOS 네이티브 설정 완료
- [ ] social_auth_service.dart 구현

키를 발급받으면 알려주세요. 실제 구현 코드를 작성해드리겠습니다!
