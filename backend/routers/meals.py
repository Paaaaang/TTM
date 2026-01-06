"""
식단 기록 API 라우터
meal_log, meal_item 테이블 관리
"""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from datetime import date, datetime
from typing import List, Optional
from config.database import get_db_connection

router = APIRouter()

# ===================== Pydantic 모델 =====================

class MealItemRequest(BaseModel):
    """식사 항목 요청 모델"""
    food_name: str
    estimated_portion_size: Optional[float] = None
    calories_kcal: Optional[float] = None
    carbohydrates_g: Optional[float] = None
    protein_g: Optional[float] = None
    fat_g: Optional[float] = None

class MealLogRequest(BaseModel):
    """식사 기록 요청 모델"""
    meal_date: date
    meal_type: str  # BREAKFAST, LUNCH, DINNER, SNACK
    memo: Optional[str] = None
    items: List[MealItemRequest] = []

class MealItemResponse(BaseModel):
    """식사 항목 응답 모델"""
    meal_item_id: int
    meal_log_id: int
    food_name: str
    estimated_portion_size: Optional[float] = None
    calories_kcal: Optional[float] = None
    carbohydrates_g: Optional[float] = None
    protein_g: Optional[float] = None
    fat_g: Optional[float] = None
    created_at: datetime

class MealLogResponse(BaseModel):
    """식사 기록 응답 모델"""
    meal_log_id: int
    meal_date: date
    meal_type: str
    memo: Optional[str] = None
    created_at: datetime
    member_id: int
    items: List[MealItemResponse] = []
    total_calories: float = 0.0

# ===================== API 엔드포인트 =====================

@router.get("/today/{member_id}", response_model=List[MealLogResponse])
async def get_today_meals(member_id: int):
    """오늘의 식사 기록 조회"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # 오늘 날짜의 식사 기록 조회
        cursor.execute(
            """SELECT * FROM meal_log 
               WHERE member_id = %s AND meal_date = CURDATE()
               ORDER BY meal_type""",
            (member_id,)
        )
        meal_logs = cursor.fetchall()
        
        result = []
        for log in meal_logs:
            # 각 식사의 항목들 조회
            cursor.execute(
                """SELECT * FROM meal_item 
                   WHERE meal_log_id = %s""",
                (log['meal_log_id'],)
            )
            items = cursor.fetchall()
            
            # 총 칼로리 계산
            total_calories = sum(item['calories_kcal'] or 0 for item in items)
            
            result.append(MealLogResponse(
                **log,
                items=[MealItemResponse(**item) for item in items],
                total_calories=total_calories
            ))
        
        return result
        
    except Exception as e:
        print(f"오늘 식사 조회 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="식사 기록 조회 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.get("/date-range/{member_id}", response_model=List[MealLogResponse])
async def get_meals_by_date_range(
    member_id: int,
    start_date: date,
    end_date: date
):
    """기간별 식사 기록 조회"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute(
            """SELECT * FROM meal_log 
               WHERE member_id = %s AND meal_date BETWEEN %s AND %s
               ORDER BY meal_date DESC, meal_type""",
            (member_id, start_date, end_date)
        )
        meal_logs = cursor.fetchall()
        
        result = []
        for log in meal_logs:
            cursor.execute(
                """SELECT * FROM meal_item 
                   WHERE meal_log_id = %s""",
                (log['meal_log_id'],)
            )
            items = cursor.fetchall()
            
            total_calories = sum(item['calories_kcal'] or 0 for item in items)
            
            result.append(MealLogResponse(
                **log,
                items=[MealItemResponse(**item) for item in items],
                total_calories=total_calories
            ))
        
        return result
        
    except Exception as e:
        print(f"기간별 식사 조회 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="식사 기록 조회 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.post("/", response_model=MealLogResponse, status_code=status.HTTP_201_CREATED)
async def create_meal_log(member_id: int, meal: MealLogRequest):
    """식사 기록 추가"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # meal_log 삽입
        cursor.execute(
            """INSERT INTO meal_log (meal_date, meal_type, memo, member_id, created_at) 
               VALUES (%s, %s, %s, %s, NOW())""",
            (meal.meal_date, meal.meal_type, meal.memo, member_id)
        )
        meal_log_id = cursor.lastrowid
        
        # meal_item들 삽입
        items_response = []
        for item in meal.items:
            cursor.execute(
                """INSERT INTO meal_item 
                   (meal_log_id, food_name, estimated_portion_size, calories_kcal, 
                    carbohydrates_g, protein_g, fat_g, created_at)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())""",
                (meal_log_id, item.food_name, item.estimated_portion_size,
                 item.calories_kcal, item.carbohydrates_g, item.protein_g, item.fat_g)
            )
            item_id = cursor.lastrowid
            
            # 삽입된 항목 조회
            cursor.execute("SELECT * FROM meal_item WHERE meal_item_id = %s", (item_id,))
            inserted_item = cursor.fetchone()
            items_response.append(MealItemResponse(**inserted_item))
        
        conn.commit()
        
        # 생성된 meal_log 조회
        cursor.execute("SELECT * FROM meal_log WHERE meal_log_id = %s", (meal_log_id,))
        created_log = cursor.fetchone()
        
        total_calories = sum(item.calories_kcal or 0 for item in items_response)
        
        return MealLogResponse(
            **created_log,
            items=items_response,
            total_calories=total_calories
        )
        
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"식사 기록 추가 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="식사 기록 추가 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.put("/{meal_log_id}", response_model=MealLogResponse)
async def update_meal_log(meal_log_id: int, meal: MealLogRequest):
    """식사 기록 수정"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # 기존 meal_log 존재 확인
        cursor.execute("SELECT * FROM meal_log WHERE meal_log_id = %s", (meal_log_id,))
        existing = cursor.fetchone()
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="식사 기록을 찾을 수 없습니다"
            )
        
        # meal_log 업데이트
        cursor.execute(
            """UPDATE meal_log 
               SET meal_date = %s, meal_type = %s, memo = %s 
               WHERE meal_log_id = %s""",
            (meal.meal_date, meal.meal_type, meal.memo, meal_log_id)
        )
        
        # 기존 meal_item 삭제
        cursor.execute("DELETE FROM meal_item WHERE meal_log_id = %s", (meal_log_id,))
        
        # 새로운 meal_item들 삽입
        items_response = []
        for item in meal.items:
            cursor.execute(
                """INSERT INTO meal_item 
                   (meal_log_id, food_name, estimated_portion_size, calories_kcal, 
                    carbohydrates_g, protein_g, fat_g, created_at)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())""",
                (meal_log_id, item.food_name, item.estimated_portion_size,
                 item.calories_kcal, item.carbohydrates_g, item.protein_g, item.fat_g)
            )
            item_id = cursor.lastrowid
            
            cursor.execute("SELECT * FROM meal_item WHERE meal_item_id = %s", (item_id,))
            inserted_item = cursor.fetchone()
            items_response.append(MealItemResponse(**inserted_item))
        
        conn.commit()
        
        # 업데이트된 meal_log 조회
        cursor.execute("SELECT * FROM meal_log WHERE meal_log_id = %s", (meal_log_id,))
        updated_log = cursor.fetchone()
        
        total_calories = sum(item.calories_kcal or 0 for item in items_response)
        
        return MealLogResponse(
            **updated_log,
            items=items_response,
            total_calories=total_calories
        )
        
    except HTTPException:
        raise
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"식사 기록 수정 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="식사 기록 수정 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.delete("/{meal_log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_meal_log(meal_log_id: int):
    """식사 기록 삭제"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # 존재 확인
        cursor.execute("SELECT * FROM meal_log WHERE meal_log_id = %s", (meal_log_id,))
        if not cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="식사 기록을 찾을 수 없습니다"
            )
        
        # meal_item 먼저 삭제 (FK 제약)
        cursor.execute("DELETE FROM meal_item WHERE meal_log_id = %s", (meal_log_id,))
        
        # meal_log 삭제
        cursor.execute("DELETE FROM meal_log WHERE meal_log_id = %s", (meal_log_id,))
        
        conn.commit()
        
    except HTTPException:
        raise
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"식사 기록 삭제 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="식사 기록 삭제 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.get("/stats/{member_id}")
async def get_meal_stats(member_id: int, days: int = 7):
    """식사 통계 조회 (최근 N일)"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute(
            """SELECT 
                   ml.meal_date,
                   ml.meal_type,
                   SUM(mi.calories_kcal) as total_calories,
                   SUM(mi.carbohydrates_g) as total_carbs,
                   SUM(mi.protein_g) as total_protein,
                   SUM(mi.fat_g) as total_fat
               FROM meal_log ml
               LEFT JOIN meal_item mi ON ml.meal_log_id = mi.meal_log_id
               WHERE ml.member_id = %s 
                 AND ml.meal_date >= DATE_SUB(CURDATE(), INTERVAL %s DAY)
               GROUP BY ml.meal_date, ml.meal_type
               ORDER BY ml.meal_date DESC""",
            (member_id, days)
        )
        stats = cursor.fetchall()
        
        return {
            "member_id": member_id,
            "period_days": days,
            "stats": stats
        }
        
    except Exception as e:
        print(f"식사 통계 조회 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="식사 통계 조회 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
