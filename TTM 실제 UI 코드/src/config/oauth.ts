// OAuth 설정 파일
// 실제 사용 시 각 플랫폼에서 발급받은 클라이언트 ID로 교체하세요

export const oauthConfig = {
  kakao: {
    clientId: 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6', // 카카오 개발자 콘솔에서 발급받은 REST API 키
    redirectUri: `${window.location.origin}/auth/kakao/callback`,
    authUrl: 'https://kauth.kakao.com/oauth/authorize',
  },
  naver: {
    clientId: 'AbCdEfGhIjKlMnOp', // 네이버 개발자 센터에서 발급받은 클라이언트 ID
    redirectUri: `${window.location.origin}/auth/naver/callback`,
    authUrl: 'https://nid.naver.com/oauth2.0/authorize',
  },
  google: {
    clientId: '123456789012-abcdefghijklmnopqrstuvwxyz012345.apps.googleusercontent.com', // 구글 클라우드 콘솔에서 발급받은 클라이언트 ID
    redirectUri: `${window.location.origin}/auth/google/callback`,
    authUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
    scope: 'email profile',
  },
};

// 카카오 로그인 URL 생성
export const getKakaoAuthUrl = () => {
  const { clientId, redirectUri, authUrl } = oauthConfig.kakao;
  return `${authUrl}?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&response_type=code`;
};

// 네이버 로그인 URL 생성
export const getNaverAuthUrl = () => {
  const { clientId, redirectUri, authUrl } = oauthConfig.naver;
  const state = Math.random().toString(36).substring(7); // CSRF 방지용 state
  return `${authUrl}?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&state=${state}`;
};

// 구글 로그인 URL 생성
export const getGoogleAuthUrl = () => {
  const { clientId, redirectUri, authUrl, scope } = oauthConfig.google;
  return `${authUrl}?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&response_type=code&scope=${encodeURIComponent(scope)}`;
};