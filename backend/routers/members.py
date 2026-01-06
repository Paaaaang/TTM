from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import List, Optional
from config.database import get_db_connection

router = APIRouter()

class HealthInfoUpdate(BaseModel):
    gender: str  # 'M', 'F', 'O'
    height: float  # cm (DB: height_cm)
    weight: float  # kg (DB: weight_kg)
    diseases: List[str]  # disease IDs (DB: member_disease 테이블)
    exercise_frequency: str  # 'none'/'light'/'moderate'/'active' (DB: activity_level ENUM)
    sleep_duration: str  # 'low'/'normal'/'good'/'high' (DB: sleep_pattern ENUM)

@router.put("/{member_id}/health")
async def update_health_info(member_id: int, info: HealthInfoUpdate):
    print(f"🔵 Health info update 요청 받음 - member_id: {member_id}")
    print(f"📦 받은 데이터: {info.dict()}")
    
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        print(f"✅ DB 연결 성공")

        # Check if member exists
        cursor.execute("SELECT member_id FROM members WHERE member_id = %s", (member_id,))
        member = cursor.fetchone()
        print(f"🔍 회원 조회 결과: {member}")
        if not member:
            print(f"❌ 회원 없음: member_id={member_id}")
            raise HTTPException(status_code=404, detail="Member not found")

        # Map Flutter values to DB ENUM values
        activity_level_map = {
            'none': 'LOW',
            'light': 'LOW', 
            'moderate': 'NORMAL',
            'active': 'HIGH'
        }
        
        sleep_pattern_map = {
            'low': 'SHORT',      # 5시간 이하
            'normal': 'REGULAR', # 6-7시간
            'good': 'REGULAR',   # 8시간
            'high': 'LONG'       # 9시간 이상
        }
        
        activity_level = activity_level_map.get(info.exercise_frequency, 'NORMAL')
        sleep_pattern = sleep_pattern_map.get(info.sleep_duration, 'REGULAR')
        
        # disease_flag: diseases 리스트에 'none'이 아닌 항목이 있으면 1
        has_disease = 1 if info.diseases and 'none' not in info.diseases else 0
        allergy_flag = 1 if 'allergy' in info.diseases else 0
        
        print(f"🔄 매핑 결과:")
        print(f"  - gender: {info.gender} (M/F/O)")
        print(f"  - height: {info.height} → height_cm")
        print(f"  - weight: {info.weight} → weight_kg")
        print(f"  - exercise: {info.exercise_frequency} → activity_level: {activity_level}")
        print(f"  - sleep: {info.sleep_duration} → sleep_pattern: {sleep_pattern}")
        print(f"  - disease_flag: {has_disease}, allergy_flag: {allergy_flag}")
        
        # Update members table with original schema columns
        cursor.execute(
            """UPDATE members 
               SET gender = %s,
                   height_cm = %s,
                   weight_kg = %s,
                   activity_level = %s,
                   sleep_pattern = %s,
                   disease_flag = %s,
                   allergy_flag = %s
               WHERE member_id = %s""",
            (
                info.gender,
                info.height,
                info.weight,
                activity_level,
                sleep_pattern,
                has_disease,
                allergy_flag,
                member_id
            )
        )
        
        # TODO: member_disease 테이블에 질병 데이터 저장 (나중에 구현 필요)
        # 현재는 disease_flag만 설정
        
        conn.commit()
        print(f"✅ 업데이트 완료")
        
        return {"message": "Health info updated successfully"}

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(f"❌ Health info update error: {e}")
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Failed to update health info: {str(e)}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
        print(f"🔒 DB 연결 종료")
