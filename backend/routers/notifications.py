"""
FCM 토큰 관리 및 알림 전송 API
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from config.database import get_db_connection
from services.fcm_service import FCMService
from routers.auth import get_current_user

router = APIRouter()


class FCMTokenRequest(BaseModel):
    """FCM 토큰 등록 요청"""
    fcm_token: str


class NotificationRequest(BaseModel):
    """테스트 알림 요청"""
    title: str
    body: str


@router.post("/token")
async def register_fcm_token(
    request: FCMTokenRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    FCM 토큰 등록/업데이트
    """
    member_id = current_user.get('member_id')
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # 기존 토큰 확인
        cursor.execute("""
            SELECT fcm_token FROM members WHERE member_id = %s
        """, (member_id,))
        
        result = cursor.fetchone()
        
        if not result:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
        
        # FCM 토큰 업데이트
        cursor.execute("""
            UPDATE members 
            SET fcm_token = %s, 
                updated_at = NOW()
            WHERE member_id = %s
        """, (request.fcm_token, member_id))
        
        conn.commit()
        
        print(f"✅ FCM 토큰 등록: member_id={member_id}, token={request.fcm_token[:20]}...")
        
        return {
            "success": True,
            "message": "FCM 토큰이 등록되었습니다."
        }
        
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"❌ FCM 토큰 등록 실패: {e}")
        raise HTTPException(status_code=500, detail=f"FCM 토큰 등록 실패: {str(e)}")
        
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


@router.post("/test")
async def send_test_notification(
    request: NotificationRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    테스트 알림 전송 (개발용)
    """
    member_id = current_user.get('member_id')
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # FCM 토큰 조회
        cursor.execute("""
            SELECT fcm_token FROM members WHERE member_id = %s
        """, (member_id,))
        
        result = cursor.fetchone()
        
        if not result or not result.get('fcm_token'):
            raise HTTPException(status_code=404, detail="FCM 토큰이 등록되지 않았습니다.")
        
        # 알림 전송
        success = await FCMService.send_notification(
            token=result['fcm_token'],
            title=request.title,
            body=request.body,
            data={"type": "test"}
        )
        
        if not success:
            raise HTTPException(status_code=500, detail="알림 전송에 실패했습니다.")
        
        return {
            "success": True,
            "message": "테스트 알림이 전송되었습니다."
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ 테스트 알림 전송 실패: {e}")
        raise HTTPException(status_code=500, detail=f"알림 전송 실패: {str(e)}")
        
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


@router.delete("/token")
async def delete_fcm_token(
    current_user: dict = Depends(get_current_user)
):
    """
    FCM 토큰 삭제 (로그아웃 시)
    """
    member_id = current_user.get('member_id')
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE members 
            SET fcm_token = NULL, 
                updated_at = NOW()
            WHERE member_id = %s
        """, (member_id,))
        
        conn.commit()
        
        return {
            "success": True,
            "message": "FCM 토큰이 삭제되었습니다."
        }
        
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"❌ FCM 토큰 삭제 실패: {e}")
        raise HTTPException(status_code=500, detail=f"FCM 토큰 삭제 실패: {str(e)}")
        
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
