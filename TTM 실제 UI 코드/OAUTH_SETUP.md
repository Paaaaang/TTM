# 소셜 로그인 설정 가이드

이 문서는 TAB TO ME 애플리케이션의 소셜 로그인 기능을 설정하는 방법을 설명합니다.

## 클라이언트 ID 발급 방법

### 1. 카카오 로그인 설정

1. [카카오 개발자 콘솔](https://developers.kakao.com/)에 접속
2. 내 애플리케이션 > 애플리케이션 추가하기
3. 앱 설정 > 앱 키에서 **REST API 키** 복사
4. 제품 설정 > 카카오 로그인 > 활성화 설정 ON
5. Redirect URI 등록: `http://localhost:5173/auth/kakao/callback` (개발환경)

**발급받은 REST API 키를 `/src/config/oauth.ts` 파일의 `YOUR_KAKAO_REST_API_KEY`에 입력하세요.**

---

### 2. 네이버 로그인 설정

1. [네이버 개발자 센터](https://developers.naver.com/)에 접속
2. Application > 애플리케이션 등록
3. 사용 API: 네이버 로그인 선택
4. 제공 정보: 이메일, 프로필 정보 선택
5. 서비스 URL: `http://localhost:5173` (개발환경)
6. Callback URL: `http://localhost:5173/auth/naver/callback`
7. **Client ID**와 **Client Secret** 확인

**발급받은 Client ID를 `/src/config/oauth.ts` 파일의 `YOUR_NAVER_CLIENT_ID`에 입력하세요.**

---

### 3. 구글 로그인 설정

1. [Google Cloud Console](https://console.cloud.google.com/)에 접속
2. 프로젝트 생성
3. API 및 서비스 > 사용자 인증 정보
4. 사용자 인증 정보 만들기 > OAuth 2.0 클라이언트 ID
5. 애플리케이션 유형: 웹 애플리케이션
6. 승인된 리디렉션 URI: `http://localhost:5173/auth/google/callback`
7. **클라이언트 ID**와 **클라이언트 보안 비밀번호** 확인

**발급받은 클라이언트 ID를 `/src/config/oauth.ts` 파일의 `YOUR_GOOGLE_CLIENT_ID`에 입력하세요.**

---

## 설정 파일 수정

`/src/config/oauth.ts` 파일을 열고 아래와 같이 발급받은 클라이언트 ID를 입력하세요:

```typescript
export const oauthConfig = {
  kakao: {
    clientId: '여기에_카카오_REST_API_키_입력',
    // ...
  },
  naver: {
    clientId: '여기에_네이버_클라이언트_ID_입력',
    // ...
  },
  google: {
    clientId: '여기에_구글_클라이언트_ID_입력',
    // ...
  },
};
```

---

## 주의사항

- 클라이언트 ID는 절대 공개 저장소에 커밋하지 마세요.
- 프로덕션 환경에서는 환경 변수(`.env` 파일)로 관리하는 것을 권장합니다.
- Redirect URI는 배포 환경에 맞게 변경해야 합니다.
- 실제 배포 시에는 각 플랫폼에서 프로덕션 도메인을 추가로 등록해야 합니다.

---

## 콜백 처리

소셜 로그인 후 리다이렉트되는 콜백 URL에서 인증 코드를 받아 백엔드 서버로 전송하여 액세스 토큰을 발급받아야 합니다. 이 부분은 백엔드 개발이 필요합니다.
