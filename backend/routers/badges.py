"""
배지 API 라우터

badge, member_badge 테이블 엔드포인트 제공:
- GET /api/badges/ - 전체 배지 목록 조회
- GET /api/badges/member/{member_id} - 회원 획득 배지 조회
- POST /api/badges/award - 배지 수여
- DELETE /api/badges/member/{member_badge_id} - 회원 배지 삭제 (관리자)
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from config.database import get_db_connection
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from services.badge_auto_award import BadgeAutoAward

router = APIRouter()


# ============================================================
# Pydantic 모델 정의
# ============================================================

class BadgeResponse(BaseModel):
    """배지 응답"""
    badge_id: int
    badge_name: str
    description: str
    badge_condition: Optional[str]
    icon_path: Optional[str]
    created_at: Optional[str]


class MemberBadgeResponse(BaseModel):
    """회원 배지 응답"""
    member_badge_id: int
    badge_id: int
    badge_name: str
    description: str
    icon_path: Optional[str]
    acquired_at: str


class BadgeAwardRequest(BaseModel):
    """배지 수여 요청"""
    member_id: int
    badge_id: int


# ============================================================
# API 엔드포인트
# ============================================================

@router.get("/", response_model=List[BadgeResponse])
async def get_all_badges():
    """
    전체 배지 목록 조회
    
    Returns:
        모든 배지 목록
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        query = """
            SELECT 
                badge_id,
                badge_name,
                description,
                badge_condition,
                icon_path,
                created_at
            FROM badge
            ORDER BY badge_id
        """
        
        cursor.execute(query)
        badges = cursor.fetchall()
        
        # datetime을 문자열로 변환
        for badge in badges:
            if badge['created_at']:
                badge['created_at'] = badge['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return badges
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"배지 목록 조회 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.get("/member/{member_id}", response_model=List[MemberBadgeResponse])
async def get_member_badges(member_id: int):
    """
    회원 획득 배지 조회
    
    Args:
        member_id: 회원 ID
        
    Returns:
        회원이 획득한 배지 목록
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        query = """
            SELECT 
                mb.member_badge_id,
                mb.badge_id,
                b.badge_name,
                b.description,
                b.icon_path,
                mb.acquired_at
            FROM member_badge mb
            INNER JOIN badge b ON mb.badge_id = b.badge_id
            WHERE mb.member_id = %s
            ORDER BY mb.acquired_at DESC
        """
        
        cursor.execute(query, (member_id,))
        member_badges = cursor.fetchall()
        
        # datetime을 문자열로 변환
        for badge in member_badges:
            if badge['acquired_at']:
                badge['acquired_at'] = badge['acquired_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return member_badges
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"회원 배지 조회 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.post("/award")
async def award_badge(request: BadgeAwardRequest):
    """
    배지 수여
    
    Args:
        request: 배지 수여 요청 (member_id, badge_id)
        
    Returns:
        수여된 배지 정보
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 배지 존재 확인
        cursor.execute("SELECT badge_id FROM badge WHERE badge_id = %s", (request.badge_id,))
        badge = cursor.fetchone()
        
        if not badge:
            raise HTTPException(status_code=404, detail="배지를 찾을 수 없습니다")
        
        # 이미 획득한 배지인지 확인
        cursor.execute(
            "SELECT member_badge_id FROM member_badge WHERE member_id = %s AND badge_id = %s",
            (request.member_id, request.badge_id)
        )
        existing = cursor.fetchone()
        
        if existing:
            raise HTTPException(status_code=400, detail="이미 획득한 배지입니다")
        
        # 배지 수여
        insert_query = """
            INSERT INTO member_badge (member_id, badge_id, acquired_at)
            VALUES (%s, %s, NOW())
        """
        
        cursor.execute(insert_query, (request.member_id, request.badge_id))
        member_badge_id = cursor.lastrowid
        conn.commit()
        
        # 수여된 배지 정보 조회
        cursor.execute("""
            SELECT 
                mb.member_badge_id,
                mb.badge_id,
                b.badge_name,
                b.description,
                b.icon_path,
                mb.acquired_at
            FROM member_badge mb
            INNER JOIN badge b ON mb.badge_id = b.badge_id
            WHERE mb.member_badge_id = %s
        """, (member_badge_id,))
        
        result = cursor.fetchone()
        
        if result['acquired_at']:
            result['acquired_at'] = result['acquired_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return {
            "message": "배지가 수여되었습니다",
            "badge": result
        }
        
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"배지 수여 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.delete("/member/{member_badge_id}")
async def delete_member_badge(member_badge_id: int):
    """
    회원 배지 삭제 (관리자 기능)
    
    Args:
        member_badge_id: 회원 배지 ID
        
    Returns:
        삭제 성공 메시지
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 배지 존재 확인
        cursor.execute(
            "SELECT member_badge_id FROM member_badge WHERE member_badge_id = %s",
            (member_badge_id,)
        )
        badge = cursor.fetchone()
        
        if not badge:
            raise HTTPException(status_code=404, detail="배지를 찾을 수 없습니다")
        
        # 배지 삭제
        cursor.execute("DELETE FROM member_badge WHERE member_badge_id = %s", (member_badge_id,))
        conn.commit()
        
        return {"message": "배지가 삭제되었습니다"}
        
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"배지 삭제 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.get("/stats/{member_id}")
async def get_badge_stats(member_id: int):
    """
    회원 배지 통계
    
    Args:
        member_id: 회원 ID
        
    Returns:
        배지 통계 정보 (전체 배지 수, 획득 배지 수, 획득률)
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 전체 배지 수
        cursor.execute("SELECT COUNT(*) as total_badges FROM badge")
        total_result = cursor.fetchone()
        total_badges = total_result['total_badges']
        
        # 획득 배지 수
        cursor.execute(
            "SELECT COUNT(*) as acquired_badges FROM member_badge WHERE member_id = %s",
            (member_id,)
        )
        acquired_result = cursor.fetchone()
        acquired_badges = acquired_result['acquired_badges']
        
        # 획득률 계산
        acquisition_rate = (acquired_badges / total_badges * 100) if total_badges > 0 else 0
        
        return {
            "total_badges": total_badges,
            "acquired_badges": acquired_badges,
            "acquisition_rate": round(acquisition_rate, 1)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"배지 통계 조회 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.post("/check-and-award/{member_id}")
async def check_and_award_badges(member_id: int):
    """
    회원의 활동을 체크하고 획득 가능한 배지를 자동으로 부여
    
    Args:
        member_id: 회원 ID
        
    Returns:
        새로 획득한 배지 목록
    """
    try:
        newly_earned = BadgeAutoAward.check_and_award_badges(member_id)
        
        return {
            "success": True,
            "newly_earned_count": len(newly_earned),
            "newly_earned_badges": newly_earned
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"배지 자동 부여 실패: {str(e)}")
