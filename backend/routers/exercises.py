"""
운동 기록 API 라우터

exercise_log 테이블 CRUD 엔드포인트 제공:
- GET /api/exercises/today/{member_id} - 오늘의 운동 기록 조회
- GET /api/exercises/date-range/{member_id} - 기간별 운동 기록 조회
- POST /api/exercises/ - 운동 기록 생성
- PUT /api/exercises/{exercise_log_id} - 운동 기록 수정
- DELETE /api/exercises/{exercise_log_id} - 운동 기록 삭제
- GET /api/exercises/stats/{member_id} - 운동 통계 조회
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime, timedelta
from config.database import get_db_connection

router = APIRouter(prefix="/api/exercises", tags=["exercises"])


# ============================================================
# Pydantic 모델 정의
# ============================================================

class ExerciseLogCreate(BaseModel):
    """운동 기록 생성 요청"""
    member_id: int
    exercise_date: str  # YYYY-MM-DD
    exercise_name: str
    duration_minutes: int
    calories_burned: Optional[float] = None
    memo: Optional[str] = None


class ExerciseLogUpdate(BaseModel):
    """운동 기록 수정 요청"""
    exercise_date: str  # YYYY-MM-DD
    exercise_name: str
    duration_minutes: int
    calories_burned: Optional[float] = None
    memo: Optional[str] = None


class ExerciseLogResponse(BaseModel):
    """운동 기록 응답"""
    exercise_log_id: int
    member_id: int
    exercise_date: str
    exercise_name: str
    duration_minutes: int
    calories_burned: Optional[float]
    memo: Optional[str]
    created_at: Optional[str]


class ExerciseStatsResponse(BaseModel):
    """운동 통계 응답"""
    total_exercises: int
    total_duration_minutes: int
    total_calories_burned: float
    avg_duration_per_session: float
    avg_calories_per_session: float
    most_frequent_exercise: Optional[str]


# ============================================================
# API 엔드포인트
# ============================================================

@router.get("/today/{member_id}")
async def get_today_exercises(member_id: int):
    """
    오늘의 운동 기록 조회
    
    Args:
        member_id: 회원 ID
        
    Returns:
        오늘의 운동 기록 리스트
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        today = date.today().strftime('%Y-%m-%d')
        
        query = """
            SELECT 
                exercise_log_id,
                member_id,
                exercise_date,
                exercise_name,
                duration_minutes,
                calories_burned,
                memo,
                created_at
            FROM exercise_log
            WHERE member_id = %s AND exercise_date = %s
            ORDER BY created_at DESC
        """
        
        cursor.execute(query, (member_id, today))
        exercises = cursor.fetchall()
        
        # datetime을 문자열로 변환
        for exercise in exercises:
            if exercise.get('exercise_date'):
                exercise['exercise_date'] = exercise['exercise_date'].strftime('%Y-%m-%d')
            if exercise.get('created_at'):
                exercise['created_at'] = exercise['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return {
            "success": True,
            "exercises": exercises,
            "count": len(exercises)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"운동 기록 조회 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.get("/date-range/{member_id}")
async def get_exercises_by_date_range(
    member_id: int,
    start_date: str,
    end_date: str
):
    """
    기간별 운동 기록 조회
    
    Args:
        member_id: 회원 ID
        start_date: 시작 날짜 (YYYY-MM-DD)
        end_date: 종료 날짜 (YYYY-MM-DD)
        
    Returns:
        해당 기간의 운동 기록 리스트
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        query = """
            SELECT 
                exercise_log_id,
                member_id,
                exercise_date,
                exercise_name,
                duration_minutes,
                calories_burned,
                memo,
                created_at
            FROM exercise_log
            WHERE member_id = %s 
                AND exercise_date BETWEEN %s AND %s
            ORDER BY exercise_date DESC, created_at DESC
        """
        
        cursor.execute(query, (member_id, start_date, end_date))
        exercises = cursor.fetchall()
        
        # datetime을 문자열로 변환
        for exercise in exercises:
            if exercise.get('exercise_date'):
                exercise['exercise_date'] = exercise['exercise_date'].strftime('%Y-%m-%d')
            if exercise.get('created_at'):
                exercise['created_at'] = exercise['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return {
            "success": True,
            "exercises": exercises,
            "count": len(exercises),
            "date_range": {
                "start": start_date,
                "end": end_date
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"운동 기록 조회 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.post("/", status_code=201)
async def create_exercise(exercise: ExerciseLogCreate):
    """
    운동 기록 생성
    
    Args:
        exercise: 운동 기록 생성 정보
        
    Returns:
        생성된 운동 기록 (exercise_log_id 포함)
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 운동 기록 삽입
        insert_query = """
            INSERT INTO exercise_log (
                member_id,
                exercise_date,
                exercise_name,
                duration_minutes,
                calories_burned,
                memo,
                created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, NOW())
        """
        
        cursor.execute(insert_query, (
            exercise.member_id,
            exercise.exercise_date,
            exercise.exercise_name,
            exercise.duration_minutes,
            exercise.calories_burned,
            exercise.memo
        ))
        
        exercise_log_id = cursor.lastrowid
        conn.commit()
        
        # 생성된 운동 기록 조회
        select_query = """
            SELECT 
                exercise_log_id,
                member_id,
                exercise_date,
                exercise_name,
                duration_minutes,
                calories_burned,
                memo,
                created_at
            FROM exercise_log
            WHERE exercise_log_id = %s
        """
        
        cursor.execute(select_query, (exercise_log_id,))
        created_exercise = cursor.fetchone()
        
        # datetime을 문자열로 변환
        if created_exercise.get('exercise_date'):
            created_exercise['exercise_date'] = created_exercise['exercise_date'].strftime('%Y-%m-%d')
        if created_exercise.get('created_at'):
            created_exercise['created_at'] = created_exercise['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return {
            "success": True,
            "message": "운동 기록이 생성되었습니다",
            "exercise_log": created_exercise
        }
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"운동 기록 생성 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.put("/{exercise_log_id}")
async def update_exercise(exercise_log_id: int, exercise: ExerciseLogUpdate):
    """
    운동 기록 수정
    
    Args:
        exercise_log_id: 운동 기록 ID
        exercise: 수정할 운동 기록 정보
        
    Returns:
        수정 성공 메시지
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # 운동 기록 존재 확인
        cursor.execute(
            "SELECT exercise_log_id FROM exercise_log WHERE exercise_log_id = %s",
            (exercise_log_id,)
        )
        
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="운동 기록을 찾을 수 없습니다")
        
        # 운동 기록 수정
        update_query = """
            UPDATE exercise_log
            SET exercise_date = %s,
                exercise_name = %s,
                duration_minutes = %s,
                calories_burned = %s,
                memo = %s
            WHERE exercise_log_id = %s
        """
        
        cursor.execute(update_query, (
            exercise.exercise_date,
            exercise.exercise_name,
            exercise.duration_minutes,
            exercise.calories_burned,
            exercise.memo,
            exercise_log_id
        ))
        
        conn.commit()
        
        return {
            "success": True,
            "message": "운동 기록이 수정되었습니다",
            "exercise_log_id": exercise_log_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"운동 기록 수정 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.delete("/{exercise_log_id}")
async def delete_exercise(exercise_log_id: int):
    """
    운동 기록 삭제
    
    Args:
        exercise_log_id: 삭제할 운동 기록 ID
        
    Returns:
        삭제 성공 메시지
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # 운동 기록 존재 확인
        cursor.execute(
            "SELECT exercise_log_id FROM exercise_log WHERE exercise_log_id = %s",
            (exercise_log_id,)
        )
        
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="운동 기록을 찾을 수 없습니다")
        
        # 운동 기록 삭제
        cursor.execute(
            "DELETE FROM exercise_log WHERE exercise_log_id = %s",
            (exercise_log_id,)
        )
        
        conn.commit()
        
        return {
            "success": True,
            "message": "운동 기록이 삭제되었습니다",
            "exercise_log_id": exercise_log_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"운동 기록 삭제 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.get("/stats/{member_id}")
async def get_exercise_stats(member_id: int, days: int = 7):
    """
    운동 통계 조회
    
    Args:
        member_id: 회원 ID
        days: 통계 기간 (기본 7일)
        
    Returns:
        운동 통계 (총 운동 횟수, 총 시간, 총 칼로리 등)
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        start_date = (date.today() - timedelta(days=days)).strftime('%Y-%m-%d')
        end_date = date.today().strftime('%Y-%m-%d')
        
        # 통계 조회
        stats_query = """
            SELECT 
                COUNT(*) as total_exercises,
                COALESCE(SUM(duration_minutes), 0) as total_duration,
                COALESCE(SUM(calories_burned), 0) as total_calories,
                COALESCE(AVG(duration_minutes), 0) as avg_duration,
                COALESCE(AVG(calories_burned), 0) as avg_calories
            FROM exercise_log
            WHERE member_id = %s 
                AND exercise_date BETWEEN %s AND %s
        """
        
        cursor.execute(stats_query, (member_id, start_date, end_date))
        stats = cursor.fetchone()
        
        # 가장 많이 한 운동 조회
        most_frequent_query = """
            SELECT exercise_name, COUNT(*) as count
            FROM exercise_log
            WHERE member_id = %s 
                AND exercise_date BETWEEN %s AND %s
            GROUP BY exercise_name
            ORDER BY count DESC
            LIMIT 1
        """
        
        cursor.execute(most_frequent_query, (member_id, start_date, end_date))
        most_frequent = cursor.fetchone()
        
        return {
            "success": True,
            "stats": {
                "total_exercises": stats['total_exercises'],
                "total_duration_minutes": int(stats['total_duration']),
                "total_calories_burned": float(stats['total_calories']),
                "avg_duration_per_session": round(float(stats['avg_duration']), 1),
                "avg_calories_per_session": round(float(stats['avg_calories']), 1),
                "most_frequent_exercise": most_frequent['exercise_name'] if most_frequent else None
            },
            "period_days": days,
            "date_range": {
                "start": start_date,
                "end": end_date
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"운동 통계 조회 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()
