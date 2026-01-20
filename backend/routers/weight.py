"""
체중 기록 관련 라우터
작성일: 2026-01-07
최종 수정: 2026-01-14 (데코레이터 적용, 코드 최적화)
"""
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime, date
from config.database import get_db_connection
from utils.common import handle_db_transaction, validate_member_exists
from .auth import get_current_user

router = APIRouter()


# Request/Response 모델
class WeightRecordCreate(BaseModel):
    """체중 기록 생성 요청"""
    weight_kg: float = Field(..., gt=0, description="체중 (kg)")
    recorded_date: date = Field(..., description="측정 날짜")
    memo: Optional[str] = Field(None, description="메모")


class WeightRecord(BaseModel):
    """체중 기록 응답"""
    weight_log_id: int
    member_id: int
    weight_kg: float
    recorded_date: date
    memo: Optional[str]
    created_at: datetime


class WeightHistory(BaseModel):
    """체중 변화 이력"""
    records: List[WeightRecord]
    current_weight: Optional[float] = None
    weight_change: Optional[float] = None  # 첫 기록 대비 변화량


@router.post("/record", response_model=WeightRecord, status_code=201)
@handle_db_transaction
async def create_weight_record(
    record: WeightRecordCreate,
    current_user: dict = Depends(get_current_user),
    cursor=None,
    conn=None
):
    """
    체중 기록 생성/업데이트
    
    - 같은 날짜에 이미 기록이 있으면 업데이트
    - members 테이블의 weight_kg도 자동 업데이트
    """
    member_id = current_user["member_id"]
    
    # 같은 날짜에 기록이 있는지 확인
    cursor.execute(
        "SELECT weight_log_id FROM weight_log WHERE member_id = %s AND recorded_date = %s",
        (member_id, record.recorded_date)
    )
    existing = cursor.fetchone()
    
    if existing:
        # 기존 기록 업데이트
        cursor.execute(
            "UPDATE weight_log SET weight_kg = %s, memo = %s WHERE weight_log_id = %s",
            (record.weight_kg, record.memo, existing['weight_log_id'])
        )
        weight_log_id = existing['weight_log_id']
    else:
        # 새 기록 생성
        cursor.execute(
            "INSERT INTO weight_log (member_id, weight_kg, recorded_date, memo) VALUES (%s, %s, %s, %s)",
            (member_id, record.weight_kg, record.recorded_date, record.memo)
        )
        weight_log_id = cursor.lastrowid
    
    # members 테이블의 weight_kg 업데이트 (최근 기록으로)
    cursor.execute(
        """UPDATE members m SET m.weight_kg = (
               SELECT w.weight_kg FROM weight_log w
               WHERE w.member_id = m.member_id
               ORDER BY w.recorded_date DESC, w.created_at DESC
               LIMIT 1
           ) WHERE m.member_id = %s""",
        (member_id,)
    )
    
    # 생성/업데이트된 기록 조회
    cursor.execute("SELECT * FROM weight_log WHERE weight_log_id = %s", (weight_log_id,))
    result = cursor.fetchone()
    
    if not result:
        raise HTTPException(status_code=500, detail="체중 기록 조회 실패")
    
    return WeightRecord(**result)


@router.get("/history", response_model=WeightHistory)
@handle_db_transaction
async def get_weight_history(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    limit: int = 30,
    current_user: dict = Depends(get_current_user),
    cursor=None,
    conn=None
):
    """
    체중 변화 이력 조회
    
    - start_date, end_date로 기간 필터링 가능
    - limit으로 최근 N개 제한 (기본 30개)
    - current_weight: members 테이블의 현재 체중
    - weight_change: 첫 기록 대비 변화량
    """
    member_id = current_user["member_id"]
    
    # 기본 쿼리 및 파라미터
    query = "SELECT * FROM weight_log WHERE member_id = %s"
    params = [member_id]
    
    # 날짜 필터링
    if start_date:
        query += " AND recorded_date >= %s"
        params.append(start_date)
    if end_date:
        query += " AND recorded_date <= %s"
        params.append(end_date)
    
    # 정렬 및 제한
    query += " ORDER BY recorded_date DESC, created_at DESC LIMIT %s"
    params.append(limit)
    
    cursor.execute(query, params)
    records = cursor.fetchall()
    
    # 현재 체중 (members 테이블)
    cursor.execute("SELECT weight_kg FROM members WHERE member_id = %s", (member_id,))
    member_data = cursor.fetchone()
    current_weight = member_data['weight_kg'] if member_data else None
    
    # 체중 변화량 계산 (첫 기록 대비)
    weight_change = None
    if records and current_weight:
        first_weight = records[-1]['weight_kg']  # 가장 오래된 기록
        weight_change = current_weight - first_weight
    
    return WeightHistory(
        records=[WeightRecord(**record) for record in records],
        current_weight=current_weight,
        weight_change=weight_change
    )


@router.delete("/record/{weight_log_id}", status_code=204)
@handle_db_transaction
async def delete_weight_record(
    weight_log_id: int,
    current_user: dict = Depends(get_current_user),
    cursor=None,
    conn=None
):
    """
    체중 기록 삭제
    
    - 본인 기록만 삭제 가능
    - 삭제 후 가장 최근 기록으로 members.weight_kg 업데이트
    """
    member_id = current_user["member_id"]
    
    # 본인 기록인지 확인
    cursor.execute(
        "SELECT member_id FROM weight_log WHERE weight_log_id = %s",
        (weight_log_id,)
    )
    record = cursor.fetchone()
    
    if not record:
        raise HTTPException(status_code=404, detail="체중 기록을 찾을 수 없습니다")
    if record['member_id'] != member_id:
        raise HTTPException(status_code=403, detail="본인의 기록만 삭제할 수 있습니다")
    
    # 기록 삭제
    cursor.execute("DELETE FROM weight_log WHERE weight_log_id = %s", (weight_log_id,))
    
    # members 테이블 업데이트 (최근 기록으로)
    cursor.execute(
        """UPDATE members m SET m.weight_kg = (
               SELECT w.weight_kg FROM weight_log w
               WHERE w.member_id = m.member_id
               ORDER BY w.recorded_date DESC, w.created_at DESC
               LIMIT 1
           ) WHERE m.member_id = %s""",
        (member_id,)
    )


@router.get("/latest", response_model=Optional[WeightRecord])
@handle_db_transaction
async def get_latest_weight(
    current_user: dict = Depends(get_current_user),
    cursor=None,
    conn=None
):
    """
    가장 최근 체중 기록 조회
    """
    member_id = current_user["member_id"]
    
    cursor.execute(
        """SELECT * FROM weight_log
           WHERE member_id = %s
           ORDER BY recorded_date DESC, created_at DESC
           LIMIT 1""",
        (member_id,)
    )
    result = cursor.fetchone()
    
    return WeightRecord(**result) if result else None
