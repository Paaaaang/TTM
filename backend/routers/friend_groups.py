"""
친구 그룹 관리 라우터
생성일: 2026-01-19
기능: 친구 그룹 CRUD, 그룹 멤버 추가/삭제, 그룹별 영양 점수 조회
"""

from fastapi import APIRouter, HTTPException
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime, date
import mysql.connector.cursor
import mysql.connector
from config.database import get_db_connection

router = APIRouter(prefix="/api/groups", tags=["Friend Groups"])

# ============================================
# Pydantic 모델
# ============================================

class GroupCreate(BaseModel):
    """그룹 생성 요청"""
    group_name: str
    creator_member_id: int

class GroupResponse(BaseModel):
    """그룹 정보 응답"""
    group_id: int
    group_name: str
    creator_member_id: int
    member_count: int
    created_at: datetime

class GroupMemberAdd(BaseModel):
    """그룹에 멤버 추가"""
    member_id: int

class GroupMemberInfo(BaseModel):
    """그룹 멤버 상세 정보"""
    member_id: int
    nickname: str
    profile_image: Optional[str] = None
    calorie_goal: int
    nutrition_score: int  # 오늘의 영양 점수
    badge_count: int  # 획득한 배지 수
    joined_at: datetime

# ============================================
# API 엔드포인트
# ============================================

@router.post("/", response_model=GroupResponse, summary="친구 그룹 생성")
async def create_group(group: GroupCreate):
    """
    새로운 친구 그룹 생성
    
    - **group_name**: 그룹 이름 (예: 가족, 학교 친구)
    - **creator_member_id**: 그룹 생성자의 회원 ID
    """
    conn = get_db_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            # 그룹 생성
            sql = """
                INSERT INTO friend_group (group_name, creator_member_id)
                VALUES (%s, %s)
            """
            cursor.execute(sql, (group.group_name, group.creator_member_id))
            group_id = cursor.lastrowid
            
            # 생성자를 그룹 멤버로 자동 추가
            sql_member = """
                INSERT INTO group_member (group_id, member_id)
                VALUES (%s, %s)
            """
            cursor.execute(sql_member, (group_id, group.creator_member_id))
            
            conn.commit()
            
            # 생성된 그룹 정보 조회
            return get_group_info(group_id)
            
    except mysql.connector.IntegrityError as e:
        raise HTTPException(status_code=400, detail=f"그룹 생성 실패: {str(e)}")
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    finally:
        conn.close()

@router.get("/{member_id}", response_model=List[GroupResponse], summary="내 그룹 목록 조회")
async def get_my_groups(member_id: int):
    """
    특정 회원이 속한 모든 그룹 목록 조회
    
    - **member_id**: 회원 ID
    """
    conn = get_db_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            sql = """
                SELECT 
                    fg.group_id,
                    fg.group_name,
                    fg.creator_member_id,
                    fg.created_at,
                    COALESCE(SUM(CASE WHEN gm.member_id != %s THEN 1 ELSE 0 END), 0) as member_count
                FROM friend_group fg
                INNER JOIN group_member gm ON fg.group_id = gm.group_id
                WHERE fg.group_id IN (
                    SELECT group_id FROM group_member WHERE member_id = %s
                )
                GROUP BY fg.group_id
                ORDER BY fg.created_at DESC
            """
            cursor.execute(sql, (member_id, member_id))
            groups = cursor.fetchall()
            
            return [
                GroupResponse(
                    group_id=g['group_id'],
                    group_name=g['group_name'],
                    creator_member_id=g['creator_member_id'],
                    member_count=g['member_count'],
                    created_at=g['created_at']
                )
                for g in groups
            ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    finally:
        conn.close()

@router.delete("/{group_id}", summary="그룹 삭제")
async def delete_group(group_id: int, member_id: int):
    """
    그룹 삭제 (생성자만 가능)
    
    - **group_id**: 삭제할 그룹 ID
    - **member_id**: 요청한 회원 ID (생성자 확인용)
    """
    conn = get_db_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            # 생성자 확인
            sql_check = """
                SELECT creator_member_id FROM friend_group WHERE group_id = %s
            """
            cursor.execute(sql_check, (group_id,))
            result = cursor.fetchone()
            
            if not result:
                raise HTTPException(status_code=404, detail="그룹을 찾을 수 없습니다")
            
            if result['creator_member_id'] != member_id:
                raise HTTPException(status_code=403, detail="그룹 생성자만 삭제할 수 있습니다")
            
            # 그룹 삭제 (CASCADE로 group_member도 자동 삭제)
            sql_delete = """
                DELETE FROM friend_group WHERE group_id = %s
            """
            cursor.execute(sql_delete, (group_id,))
            conn.commit()
            
            return {"message": "그룹이 삭제되었습니다"}
            
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    finally:
        conn.close()

@router.post("/{group_id}/members", summary="그룹에 멤버 추가")
async def add_group_member(group_id: int, member: GroupMemberAdd):
    """
    그룹에 새로운 멤버 추가
    
    - **group_id**: 그룹 ID
    - **member_id**: 추가할 회원 ID
    
    주의: 그룹 생성자와 친구 관계(ACCEPTED)인 사용자만 추가 가능
    """
    conn = get_db_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            # 그룹 존재 확인 및 생성자 ID 가져오기
            sql_check = "SELECT creator_member_id FROM friend_group WHERE group_id = %s"
            cursor.execute(sql_check, (group_id,))
            group_info = cursor.fetchone()
            if not group_info:
                raise HTTPException(status_code=404, detail="그룹을 찾을 수 없습니다")
            
            creator_id = group_info['creator_member_id']
            
            # 회원 존재 확인
            sql_member_check = "SELECT member_id FROM members WHERE member_id = %s"
            cursor.execute(sql_member_check, (member.member_id,))
            if not cursor.fetchone():
                raise HTTPException(status_code=404, detail="회원을 찾을 수 없습니다")
            
            # 친구 관계 확인 (생성자와 추가하려는 멤버가 친구인지)
            sql_friend_check = """
                SELECT friend_id FROM friend 
                WHERE member_id = %s 
                  AND friend_member_id = %s 
                  AND status = 'ACCEPTED'
            """
            cursor.execute(sql_friend_check, (creator_id, member.member_id))
            if not cursor.fetchone():
                raise HTTPException(
                    status_code=403, 
                    detail="친구 관계가 아닌 사용자는 그룹에 추가할 수 없습니다"
                )
            
            # 멤버 추가
            sql = """
                INSERT INTO group_member (group_id, member_id)
                VALUES (%s, %s)
            """
            cursor.execute(sql, (group_id, member.member_id))
            conn.commit()
            
            return {"message": "멤버가 추가되었습니다"}
            
    except mysql.connector.IntegrityError:
        raise HTTPException(status_code=400, detail="이미 그룹에 속한 멤버입니다")
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    finally:
        conn.close()

@router.delete("/{group_id}/members/{member_id}", summary="그룹에서 멤버 제거")
async def remove_group_member(group_id: int, member_id: int):
    """
    그룹에서 멤버 제거
    
    - **group_id**: 그룹 ID
    - **member_id**: 제거할 회원 ID
    """
    conn = get_db_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            # 멤버 제거
            sql = """
                DELETE FROM group_member 
                WHERE group_id = %s AND member_id = %s
            """
            affected_rows = cursor.execute(sql, (group_id, member_id))
            
            if affected_rows == 0:
                raise HTTPException(status_code=404, detail="그룹 멤버를 찾을 수 없습니다")
            
            conn.commit()
            return {"message": "멤버가 제거되었습니다"}
            
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    finally:
        conn.close()

@router.get("/{group_id}/members", response_model=List[GroupMemberInfo], summary="그룹 멤버 목록 조회")
async def get_group_members(group_id: int):
    """
    그룹에 속한 모든 멤버 조회 (영양 점수, 배지 수 포함)
    
    - **group_id**: 그룹 ID
    """
    conn = get_db_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            # 오늘 날짜
            today = date.today().isoformat()
            
            sql = """
                SELECT 
                    m.member_id,
                    m.nickname,
                    m.profile_image,
                    m.calorie_goal,
                    gm.joined_at,
                    COALESCE(
                        (SELECT COUNT(*) FROM member_badge WHERE member_id = m.member_id),
                        0
                    ) as badge_count,
                    COALESCE(
                        (SELECT 
                            GREATEST(0, LEAST(100,
                                100 
                                - (ABS(SUM(carbohydrates_g) / NULLIF(SUM(mi.calories_kcal), 0) * 100 - 55) * 2)
                                - (ABS(SUM(protein_g) / NULLIF(SUM(mi.calories_kcal), 0) * 100 - 20) * 2)
                                - (ABS(SUM(fat_g) / NULLIF(SUM(mi.calories_kcal), 0) * 100 - 25) * 2)
                                - (CASE WHEN SUM(sugar_g) > 50 THEN (SUM(sugar_g) - 50) * 0.5 ELSE 0 END)
                                - (CASE WHEN SUM(sodium_mg) > 2000 THEN (SUM(sodium_mg) - 2000) * 0.01 ELSE 0 END)
                            ))
                        FROM meal_log ml
                        INNER JOIN meal_item mi ON ml.meal_log_id = mi.meal_log_id
                        WHERE ml.member_id = m.member_id 
                        AND ml.meal_date = %s
                        GROUP BY ml.member_id),
                        0
                    ) as nutrition_score
                FROM members m
                INNER JOIN group_member gm ON m.member_id = gm.member_id
                WHERE gm.group_id = %s
                ORDER BY nutrition_score DESC, m.nickname ASC
            """
            cursor.execute(sql, (today, group_id))
            members = cursor.fetchall()
            
            return [
                GroupMemberInfo(
                    member_id=m['member_id'],
                    nickname=m['nickname'],
                    profile_image=m['profile_image'],
                    calorie_goal=m['calorie_goal'],
                    nutrition_score=m['nutrition_score'],
                    badge_count=m['badge_count'],
                    joined_at=m['joined_at']
                )
                for m in members
            ]
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    finally:
        conn.close()

# ============================================
# 헬퍼 함수
# ============================================

def get_group_info(group_id: int) -> GroupResponse:
    """그룹 정보 조회 (내부 함수)"""
    conn = get_db_connection()
    try:
        with conn.cursor(dictionary=True) as cursor:
            sql = """
                SELECT 
                    fg.group_id,
                    fg.group_name,
                    fg.creator_member_id,
                    fg.created_at,
                    COALESCE(SUM(CASE WHEN gm.member_id != fg.creator_member_id THEN 1 ELSE 0 END), 0) as member_count
                FROM friend_group fg
                LEFT JOIN group_member gm ON fg.group_id = gm.group_id
                WHERE fg.group_id = %s
                GROUP BY fg.group_id
            """
            cursor.execute(sql, (group_id,))
            group = cursor.fetchone()
            
            if not group:
                raise HTTPException(status_code=404, detail="그룹을 찾을 수 없습니다")
            
            return GroupResponse(
                group_id=group['group_id'],
                group_name=group['group_name'],
                creator_member_id=group['creator_member_id'],
                member_count=group['member_count'],
                created_at=group['created_at']
            )
    finally:
        conn.close()
