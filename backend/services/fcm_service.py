"""
Firebase Cloud Messaging (FCM) 푸시 알림 서비스

이 모듈은 Firebase Admin SDK를 사용하여 모바일 디바이스에 푸시 알림을 전송합니다.

주요 기능:
    - 단일 디바이스 알림 전송 (send_notification)
    - 다중 디바이스 알림 전송 (send_multicast)
    - 댓글 알림 (send_comment_notification)
    - 좋아요 알림 (send_like_notification)

Dependencies:
    - firebase-admin (optional): pip install firebase-admin
    - Firebase Admin SDK 서비스 계정 키 파일 필요
    
Setup:
    1. Firebase Console에서 서비스 계정 키 다운로드
    2. backend/config/ttm-firebase-adminsdk.json 위치에 저장
    3. FCMService.initialize() 호출로 초기화
    
Example:
    # 초기화 (앱 시작 시 한 번만 실행)
    FCMService.initialize()
    
    # 단일 알림 전송
    await FCMService.send_notification(
        token="device_fcm_token",
        title="새로운 메시지",
        body="안녕하세요!",
        data={"type": "message", "id": "123"}
    )
    
Note:
    firebase-admin이 설치되지 않은 경우 graceful degradation 처리됨
    알림 전송 시도 시 경고 메시지만 출력되고 에러는 발생하지 않음
"""
from typing import Optional, List, Dict
import os

# Firebase Admin SDK 선택적 import
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    print("⚠️ firebase-admin 패키지가 설치되지 않았습니다. 알림 기능이 비활성화됩니다.")


class FCMService:
    """Firebase Cloud Messaging 서비스"""
    
    _initialized = False
    
    @classmethod
    def initialize(cls):
        """
        Firebase Admin SDK 초기화
        
        앱 시작 시 한 번만 호출해야 합니다.
        환경 변수 FIREBASE_CREDENTIALS_PATH 또는 기본 경로 사용
        
        Environment:
            FIREBASE_CREDENTIALS_PATH: Firebase 서비스 계정 키 파일 경로
            
        Note:
            Firebase Console → 프로젝트 설정 → 서비스 계정 → 새 비공개 키 생성
        """
        if not FIREBASE_AVAILABLE:
            print("⚠️ Firebase를 사용할 수 없습니다. 알림 기능이 비활성화됩니다.")
            return
            
        if cls._initialized:
            return
            
        # Firebase 서비스 계정 키 파일 경로
        cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH', 'firebase-credentials.json')
        
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            cls._initialized = True
            print("✅ Firebase Admin SDK 초기화 완료")
        else:
            print(f"⚠️ Firebase 인증 파일을 찾을 수 없습니다: {cred_path}")
    
    @staticmethod
    async def send_notification(
        token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> bool:
        """
        단일 기기에 푸시 알림 전송
        
        Args:
            token: FCM 토큰
            title: 알림 제목
            body: 알림 내용
            data: 추가 데이터 (예: {"type": "comment", "targetId": "123"})
        
        Returns:
            성공 여부
        """
        if not FIREBASE_AVAILABLE:
            print("⚠️ Firebase를 사용할 수 없어 알림을 전송하지 않습니다.")
            return False
            
        try:
            FCMService.initialize()
            
            if not FCMService._initialized:
                print("❌ Firebase가 초기화되지 않았습니다.")
                return False
            
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                token=token,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='ttm_channel',
                        sound='default',
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                        ),
                    ),
                ),
            )
            
            response = messaging.send(message)
            print(f"✅ 알림 전송 성공: {response}")
            return True
            
        except Exception as e:
            print(f"❌ 알림 전송 실패: {e}")
            return False
    
    @staticmethod
    async def send_multicast(
        tokens: List[str],
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> Dict[str, int]:
        """
        여러 기기에 푸시 알림 전송
        
        Args:
            tokens: FCM 토큰 리스트
            title: 알림 제목
            body: 알림 내용
            data: 추가 데이터
        
        Returns:
            {"success": 성공 수, "failure": 실패 수}
        """
        if not FIREBASE_AVAILABLE:
            print("⚠️ Firebase를 사용할 수 없어 알림을 전송하지 않습니다.")
            return {"success": 0, "failure": len(tokens)}
            
        try:
            FCMService.initialize()
            
            if not FCMService._initialized:
                print("❌ Firebase가 초기화되지 않았습니다.")
                return {"success": 0, "failure": len(tokens)}
            
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                tokens=tokens,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='ttm_channel',
                        sound='default',
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                        ),
                    ),
                ),
            )
            
            response = messaging.send_multicast(message)
            print(f"✅ 멀티캐스트 알림 전송: 성공 {response.success_count}, 실패 {response.failure_count}")
            
            return {
                "success": response.success_count,
                "failure": response.failure_count
            }
            
        except Exception as e:
            print(f"❌ 멀티캐스트 알림 전송 실패: {e}")
            return {"success": 0, "failure": len(tokens)}
    
    @staticmethod
    async def send_comment_notification(
        fcm_token: str,
        commenter_name: str,
        post_id: int,
        is_reply: bool = False
    ) -> bool:
        """
        댓글 알림 전송
        
        Args:
            fcm_token: 게시글 작성자의 FCM 토큰
            commenter_name: 댓글 작성자 이름
            post_id: 게시글 ID
            is_reply: 대댓글 여부
        
        Returns:
            성공 여부
        """
        title = "새로운 댓글" if not is_reply else "새로운 답글"
        body = f"{commenter_name}님이 {'답글을' if is_reply else '댓글을'} 남겼습니다."
        
        return await FCMService.send_notification(
            token=fcm_token,
            title=title,
            body=body,
            data={
                "type": "reply" if is_reply else "comment",
                "targetId": str(post_id)
            }
        )
    
    @staticmethod
    async def send_like_notification(
        fcm_token: str,
        liker_name: str,
        post_id: int
    ) -> bool:
        """
        좋아요 알림 전송
        
        Args:
            fcm_token: 게시글 작성자의 FCM 토큰
            liker_name: 좋아요 누른 사용자 이름
            post_id: 게시글 ID
        
        Returns:
            성공 여부
        """
        return await FCMService.send_notification(
            token=fcm_token,
            title="새로운 좋아요",
            body=f"{liker_name}님이 회원님의 게시글을 좋아합니다.",
            data={
                "type": "like",
                "targetId": str(post_id)
            }
        )
