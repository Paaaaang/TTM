"""
식단 기록 API 라우터
meal_log, meal_item 테이블 관리
"""
from fastapi import APIRouter, HTTPException, status, File, UploadFile, Form
import mysql.connector
from pydantic import BaseModel
from datetime import date, datetime
from typing import List, Optional
from config.database import get_db_connection
import os
import shutil
from pathlib import Path
import json
import threading

router = APIRouter()

# 업로드 디렉토리 설정
BASE_DIR = Path(__file__).resolve().parent.parent
UPLOAD_DIR = BASE_DIR / "uploads"
_processing_lock = threading.Lock()
PROCESSING_STATUS_FILE = BASE_DIR / "iot_processing.json"


def _read_processing_status():
    try:
        if not PROCESSING_STATUS_FILE.exists():
            return {}
        with PROCESSING_STATUS_FILE.open('r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return {}


def _write_processing_status(d):
    with PROCESSING_STATUS_FILE.open('w', encoding='utf-8') as f:
        json.dump(d, f)


def _set_processing(member_id: int, value: bool, message: Optional[str] = None):
    with _processing_lock:
        d = _read_processing_status()
        d[str(member_id)] = {"processing": bool(value), "message": message or ""}
        _write_processing_status(d)


def _get_processing(member_id: int):
    d = _read_processing_status()
    entry = d.get(str(member_id), {"processing": False, "message": ""})
    return entry

# ===================== Pydantic 모델 =====================

class MealItemRequest(BaseModel):
    """식사 항목 요청 모델"""
    food_name: str
    calories_kcal: Optional[float] = None
    carbohydrates_g: Optional[float] = None
    protein_g: Optional[float] = None
    fat_g: Optional[float] = None
    sugar_g: Optional[float] = None
    sodium_mg: Optional[float] = None

class MealLogRequest(BaseModel):
    """식사 기록 요청 모델"""
    member_id: int
    meal_date: date
    meal_type: str  # BREAKFAST, LUNCH, DINNER, SNACK
    memo: Optional[str] = None
    items: List[MealItemRequest] = []

class MealItemResponse(BaseModel):
    """식사 항목 응답 모델"""
    meal_item_id: int
    meal_log_id: int
    food_name: str
    calories_kcal: Optional[float] = None
    carbohydrates_g: Optional[float] = None
    protein_g: Optional[float] = None
    fat_g: Optional[float] = None
    sugar_g: Optional[float] = None
    sodium_mg: Optional[float] = None
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
    newly_earned_badges: Optional[List[dict]] = None  # 새로 획득한 배지

class AIAnalysisResponse(BaseModel):
    """AI 분석 응답 모델"""
    success: bool
    message: str
    foods: List[dict]  # 탐지된 음식 목록
    saved_meal_log_id: Optional[int] = None


def _resolve_meal_type(captured_at: datetime) -> str:
    """식사 시간대별 분류: 아침(06~11시), 점심(11:30~16:30), 저녁(17:00~22:30)"""
    hour = captured_at.hour
    minute = captured_at.minute
    
    # 아침: 06:00 ~ 11:00 (11:00 포함)
    if 6 <= hour < 11 or (hour == 11 and minute == 0):
        return "BREAKFAST"
    # 점심: 11:30 ~ 16:30 (16:30 포함, 16:31~16:59도 포함)
    elif (hour == 11 and minute >= 30) or (12 <= hour <= 16):
        return "LUNCH"
    # 저녁: 17:00 ~ 22:30 (22:30 포함)
    elif 17 <= hour < 22 or (hour == 22 and minute <= 30):
        return "DINNER"
    else:
        return "SNACK"


def _parse_capture_time(value: Optional[str]) -> datetime:
    if not value:
        return datetime.now()
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        try:
            return datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            return datetime.now()

# ===================== API 엔드포인트 =====================

@router.post("/analyze-image", response_model=AIAnalysisResponse)
async def analyze_meal_image(
    file: UploadFile = File(...),
    member_id: int = Form(...),
    meal_type: str = Form(...),  # BREAKFAST, LUNCH, DINNER, SNACK
    meal_date: Optional[str] = Form(None)
):
    """
    AI 식사 이미지 분석 엔드포인트
    
    내부 처리 순서:
    1. 이미지 수신/저장
    2. YOLO 추론 → food_name, bbox
    3. crop 생성
    4. ResNet 추론 → Q, ratio
    5. 영양 DB 조회
    6. 영양 계산(영양DB 조회 '음식명' 매칭 후 "영양소 * Q값")
    7. 계산 결과값 응답 (DB 저장 안 함)
    
    Note:
    - 분석 결과만 반환하고 DB에 저장하지 않음
    - 사용자 확인 후 POST /api/meals/ 엔드포인트로 저장
    """
    print(f"🤖 AI 식사 이미지 분석 요청")
    print(f"   member_id: {member_id}")
    print(f"   meal_type: {meal_type}")
    print(f"   file: {file.filename}")
    
    # 업로드 디렉토리 생성
    upload_dir = UPLOAD_DIR / "meals"
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # 임시 파일 저장
    temp_file_path = upload_dir / f"temp_{member_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}.jpg"
    
    try:
        # Step 1: 이미지 저장
        print(f"\n📥 이미지 업로드 시작")
        print(f"  파일명: {file.filename}")
        print(f"  Content-Type: {file.content_type}")
        
        file_content = await file.read()
        print(f"  파일 크기: {len(file_content)} bytes")
        
        with temp_file_path.open("wb") as buffer:
            buffer.write(file_content)
        
        print(f"✅ 이미지 저장: {temp_file_path}")
        print(f"  저장 파일 크기: {temp_file_path.stat().st_size} bytes")
        
        # 파일이 제대로 저장되었는지 확인
        if not temp_file_path.exists() or temp_file_path.stat().st_size == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미지 파일 저장 실패"
            )
        
        # Step 2-6: AI 분석 (통합 모듈 사용)
        from services.nutrition_analyzer import get_nutrition_info_from_image
        analyzed_foods = get_nutrition_info_from_image(str(temp_file_path))
        
        if not analyzed_foods:
            return AIAnalysisResponse(
                success=False,
                message="음식을 탐지하지 못했습니다",
                foods=[]
            )
        
        # Step 7: 계산 결과값 응답 (DB 저장 안 함)
        # 사용자가 확인/수정 후 별도로 저장 엔드포인트 호출
        return AIAnalysisResponse(
            success=True,
            message=f"{len(analyzed_foods)}개 음식 분석 완료",
            foods=analyzed_foods,
            saved_meal_log_id=None  # 아직 저장 안 됨
        )
        
    except Exception as e:
        print(f"❌ AI 분석 오류: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI 분석 중 오류 발생: {str(e)}"
        )
    finally:
        # 임시 파일 삭제
        if temp_file_path.exists():
            temp_file_path.unlink()


@router.post("/iot-capture", response_model=AIAnalysisResponse)
async def analyze_and_save_iot_image(
    file: UploadFile = File(...),
    member_id: int = Form(...),
    device_id: Optional[str] = Form(None),
    captured_at: Optional[str] = Form(None),
    memo: Optional[str] = Form(None),
):
    """
    라즈베리파이용 자동 분석 + 자동 저장
    device_id가 제공되면 iot_devices.json의 매핑을 우선 사용
    """
    # device_id가 있으면 등록된 member_id 우선 사용
    actual_member_id = member_id
    if device_id:
        import json
        devices_file = BASE_DIR / "iot_devices.json"
        if devices_file.exists():
            try:
                devices = json.loads(devices_file.read_text(encoding='utf-8'))
                if device_id in devices:
                    actual_member_id = devices[device_id].get('member_id', member_id)
                    print(f"📱 device_id '{device_id}'의 등록된 member_id: {actual_member_id}")
            except Exception as e:
                print(f"⚠️ 기기 매핑 로드 실패: {e}")
    
    print("🤖 IoT 식사 이미지 분석 요청")
    print(f"   요청 member_id: {member_id}")
    print(f"   실제 member_id: {actual_member_id}")
    print(f"   device_id: {device_id}")
    print(f"   captured_at: {captured_at}")
    print(f"   file: {file.filename}")
    
    member_id = actual_member_id  # 이후 로직에서 사용할 member_id 교체

    upload_dir = UPLOAD_DIR / "meals"
    upload_dir.mkdir(parents=True, exist_ok=True)
    temp_file_path = upload_dir / f"iot_{member_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}.jpg"

    conn = None
    cursor = None
    
    # mark processing start
    _set_processing(member_id, True, "processing")
    
    try:
        # 이미지 저장
        file_content = await file.read()
        with temp_file_path.open("wb") as buffer:
            buffer.write(file_content)

        if not temp_file_path.exists() or temp_file_path.stat().st_size == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미지 파일 저장 실패"
            )

        # 분석
        from services.nutrition_analyzer import get_nutrition_info_from_image
        analyzed_foods = get_nutrition_info_from_image(str(temp_file_path))

        if not analyzed_foods:
            return AIAnalysisResponse(
                success=False,
                message="음식을 탐지하지 못했습니다",
                foods=[],
                saved_meal_log_id=None,
            )

        # "알 수 없음" 제외하고 신뢰도 가장 높은 음식 1개만 선택
        valid_foods = [f for f in analyzed_foods if f.get('food_name') != '알 수 없음']
        
        if not valid_foods:
            return AIAnalysisResponse(
                success=False,
                message="인식 가능한 음식을 찾지 못했습니다",
                foods=[],
                saved_meal_log_id=None,
            )
        
        top_food = max(valid_foods, key=lambda x: x.get('confidence', 0.0))
        print(f"📌 최고 신뢰도 음식 선택: {top_food['food_name']} (신뢰도: {top_food.get('confidence', 0):.2f})")
        analyzed_foods = [top_food]  # 1개만 저장

        capture_dt = _parse_capture_time(captured_at)
        meal_type = _resolve_meal_type(capture_dt)

        # 저장
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # 동일 날짜/유형의 기존 식사 기록이 있으면 항목을 추가하고,
        # 없으면 새로 생성합니다 (중복으로 409 반환하지 않음).
        cursor.execute(
            """SELECT meal_log_id FROM meal_log 
               WHERE member_id = %s AND meal_date = %s AND meal_type = %s""",
            (member_id, capture_dt.date(), meal_type)
        )
        existing = cursor.fetchone()
        if existing:
            meal_log_id = existing['meal_log_id']
        else:
            cursor.execute(
                """INSERT INTO meal_log (meal_date, meal_type, memo, member_id, created_at) 
                   VALUES (%s, %s, %s, %s, NOW())""",
                (capture_dt.date(), meal_type, memo, member_id)
            )
            meal_log_id = cursor.lastrowid

        for item in analyzed_foods:
            # 분석기에서 sugar 키명이 다를 수 있어 두 가지를 모두 확인
            sugar_val = item.get("sugar_g") if item.get("sugar_g") is not None else item.get("sugars_g")
            cursor.execute(
                """INSERT INTO meal_item 
                   (meal_log_id, food_name, calories_kcal, carbohydrates_g, protein_g, fat_g, sugar_g, sodium_mg, created_at)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW())""",
                (
                    meal_log_id,
                    item.get("food_name"),
                    item.get("calories_kcal"),
                    item.get("carbohydrates_g"),
                    item.get("protein_g"),
                    item.get("fat_g"),
                    sugar_val,
                    item.get("sodium_mg"),
                )
            )

        conn.commit()

        return AIAnalysisResponse(
            success=True,
            message=f"음식 분석 및 저장 완료: {analyzed_foods[0]['food_name']}",
            foods=analyzed_foods,
            saved_meal_log_id=meal_log_id,
        )

    except HTTPException:
        if conn:
            conn.rollback()
        raise
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"IoT 분석 저장 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"IoT 분석 중 오류 발생: {str(e)}"
        )
    finally:
        # mark processing end
        try:
            _set_processing(member_id, False, "")
        except Exception:
            pass
        if cursor:
            cursor.close()
        if conn:
            conn.close()
        if temp_file_path.exists():
            temp_file_path.unlink()



@router.get("/iot-processing/{member_id}")
async def get_iot_processing_status(member_id: int):
    """IoT 자동분석 처리 상태 조회 (프론트엔드에서 로딩 UI용)"""
    try:
        entry = _get_processing(member_id)
        return {"member_id": member_id, "processing": bool(entry.get("processing", False)), "message": entry.get("message","")}
    except Exception as e:
        print(f"processing status read error: {e}")
        return {"member_id": member_id, "processing": False, "message": ""}

# ===================== 기존 API 엔드포인트 =====================

@router.get("/today/{member_id}", response_model=List[MealLogResponse])
async def get_today_meals(member_id: int):
    """오늘의 식사 기록 조회"""
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # 중복 식사 기록 방지 (동일 날짜/유형)
        cursor.execute(
            """SELECT meal_log_id FROM meal_log 
               WHERE member_id = %s AND meal_date = %s AND meal_type = %s""",
            (meal.member_id, meal.meal_date, meal.meal_type)
        )
        existing = cursor.fetchone()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="이미 해당 날짜와 식사 유형의 기록이 존재합니다"
            )
        
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
            total_calories = sum(item.get('calories_kcal') or 0 for item in items)
            
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
            
            total_calories = sum(item.get('calories_kcal') or 0 for item in items)
            
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
async def create_meal_log(meal: MealLogRequest):
    """식사 기록 추가"""
    print(f"📥 식사 기록 추가 요청 받음")
    print(f"   member_id: {meal.member_id}")
    print(f"   meal_date: {meal.meal_date}")
    print(f"   meal_type: {meal.meal_type}")
    print(f"   items 개수: {len(meal.items)}")
    for i, item in enumerate(meal.items):
        print(f"   item[{i}]: {item.food_name} - {item.calories_kcal}kcal")
    
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # meal_log 삽입
        cursor.execute(
            """INSERT INTO meal_log (meal_date, meal_type, memo, member_id, created_at) 
               VALUES (%s, %s, %s, %s, NOW())""",
            (meal.meal_date, meal.meal_type, meal.memo, meal.member_id)
        )
        print(f"✅ meal_log 삽입 성공 (meal_log_id: {cursor.lastrowid})")
        meal_log_id = cursor.lastrowid
        
        # meal_item들 삽입
        items_response = []
        for item in meal.items:
            cursor.execute(
                """INSERT INTO meal_item 
                   (meal_log_id, food_name, calories_kcal, 
                    carbohydrates_g, protein_g, fat_g, sugar_g, sodium_mg, created_at)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW())""",
                (meal_log_id, item.food_name, item.calories_kcal,
                 item.carbohydrates_g, item.protein_g, item.fat_g,
                 item.sugar_g, item.sodium_mg)
            )
            item_id = cursor.lastrowid
            
            # 삽입된 항목 조회하고 필드명 매핑
            cursor.execute("SELECT * FROM meal_item WHERE meal_item_id = %s", (item_id,))
            db_item = cursor.fetchone()
            
            # DB 필드명을 응답 모델 필드명으로 매핑 (동일함 - 그대로 사용)
            items_response.append(MealItemResponse(**db_item))
        
        conn.commit()
        
        # 생성된 meal_log 조회
        cursor.execute("SELECT * FROM meal_log WHERE meal_log_id = %s", (meal_log_id,))
        created_log = cursor.fetchone()
        
        total_calories = sum(item.calories_kcal or 0 for item in items_response)
        
        # 배지 자동 획득 체크
        newly_earned = []
        try:
            from services.badge_auto_award import BadgeAutoAward
            newly_earned = BadgeAutoAward.check_and_award_badges(meal.member_id)
            if newly_earned:
                print(f"🏅 새로운 배지 {len(newly_earned)}개 획득: {[b['badge_name'] for b in newly_earned]}")
        except Exception as badge_error:
            print(f"⚠️ 배지 자동 획득 체크 오류 (무시됨): {badge_error}")
        
        return MealLogResponse(
            **created_log,
            items=items_response,
            total_calories=total_calories,
            newly_earned_badges=newly_earned if newly_earned else None
        )
        
    except mysql.connector.IntegrityError as e:
        if conn:
            conn.rollback()
        print(f"식사 기록 추가 무결성 오류: {e}")
        # meal_log 유니크 키(member_id, meal_date, meal_type) 충돌 처리
        if e.errno == 1062:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="해당 날짜에 이미 같은 식사 유형이 등록되어 있습니다"
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="식사 기록 추가 중 데이터 오류가 발생했습니다"
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
                    (meal_log_id, food_name, calories_kcal, 
                    carbohydrates_g, protein_g, fat_g, sugar_g, sodium_mg, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW())""",
                (meal_log_id, item.food_name, item.calories_kcal,
                item.carbohydrates_g, item.protein_g, item.fat_g,
                item.sugar_g, item.sodium_mg)
            )
            item_id = cursor.lastrowid
            cursor.execute("SELECT * FROM meal_item WHERE meal_item_id = %s", (item_id,))
            db_item = cursor.fetchone()
            items_response.append(MealItemResponse(**db_item))
        
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


@router.get("/nutrition-scores/{member_id}")
async def get_monthly_nutrition_scores(
    member_id: int,
    year: int,
    month: int
):
    """
    월별 일일 영양 점수 조회
    
    Args:
        member_id: 회원 ID
        year: 연도
        month: 월 (1-12)
        
    Returns:
        날짜별 영양 점수 맵 {"2026-01-19": 85, ...}
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # 해당 월의 일일 영양소 합계 조회
        cursor.execute(
            """SELECT 
                   ml.meal_date,
                   SUM(mi.carbohydrates_g) as total_carbs,
                   SUM(mi.protein_g) as total_protein,
                   SUM(mi.fat_g) as total_fat,
                   SUM(mi.sugar_g) as total_sugar,
                   SUM(mi.sodium_mg) as total_sodium
               FROM meal_log ml
               LEFT JOIN meal_item mi ON ml.meal_log_id = mi.meal_log_id
               WHERE ml.member_id = %s 
                 AND YEAR(ml.meal_date) = %s
                 AND MONTH(ml.meal_date) = %s
               GROUP BY ml.meal_date""",
            (member_id, year, month)
        )
        daily_data = cursor.fetchall()
        
        # 날짜별 영양 점수 계산
        scores = {}
        for row in daily_data:
            meal_date = row['meal_date'].strftime('%Y-%m-%d')
            
            # Decimal을 float로 변환
            carbs_g = float(row['total_carbs'] or 0)
            protein_g = float(row['total_protein'] or 0)
            fat_g = float(row['total_fat'] or 0)
            sugar_g = float(row['total_sugar'] or 0)
            sodium_mg = float(row['total_sodium'] or 0)
            
            # 영양 점수 계산 (홈 화면 로직과 동일)
            macro_calories = carbs_g * 4 + protein_g * 4 + fat_g * 9
            if macro_calories <= 0:
                scores[meal_date] = 0
                continue
            
            carb_ratio = (carbs_g * 4) / macro_calories
            protein_ratio = (protein_g * 4) / macro_calories
            fat_ratio = (fat_g * 9) / macro_calories
            
            score = 100.0
            score -= (abs(carb_ratio - 0.5) + abs(protein_ratio - 0.3) + abs(fat_ratio - 0.2)) * 100
            
            if sugar_g > 50:
                score -= min((sugar_g - 50) / 5, 20)
            if sodium_mg > 2000:
                score -= min((sodium_mg - 2000) / 100, 20)
            
            scores[meal_date] = max(0, min(100, round(score)))
        
        return {
            "member_id": member_id,
            "year": year,
            "month": month,
            "scores": scores
        }
        
    except Exception as e:
        print(f"월별 영양 점수 조회 오류: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="영양 점수 조회 중 오류가 발생했습니다"
        )
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
