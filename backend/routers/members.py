from fastapi import APIRouter, HTTPException, status, UploadFile, File
from pydantic import BaseModel
from typing import List, Optional
from config.database import get_db_connection
import os
import uuid
from pathlib import Path

router = APIRouter()

# 업로드 디렉토리 설정 (main.py의 BASE_DIR 기준)
BASE_DIR = Path(__file__).resolve().parent.parent
UPLOAD_DIR = BASE_DIR / "uploads"


class ProfileUpdateRequest(BaseModel):
    member_name: Optional[str] = None
    email: Optional[str] = None
    profile_image: Optional[str] = None


class HealthInfoUpdate(BaseModel):
    gender: str  # 'M', 'F', 'O'
    height: float  # cm (DB: height_cm)
    weight: float  # kg (DB: weight_kg)
    diseases: List[str]  # disease IDs (DB: member_disease 테이블)
    exercise_frequency: str  # 'none'/'light'/'moderate'/'active' (DB: activity_level ENUM)
    sleep_duration: str  # 'low'/'normal'/'good'/'high' (DB: sleep_pattern ENUM)

class CalorieGoalUpdate(BaseModel):
    calorie_goal: int  # 일일 칼로리 목표 (kcal)


class ActivityStatsResponse(BaseModel):
    meal_count: int
    workout_count: int
    post_count: int
    like_count: int


def _format_member_row(row: dict) -> dict:
    from datetime import datetime

    def _convert(value):
        if isinstance(value, datetime):
            return value.isoformat()
        return value

    return {key: _convert(value) for key, value in row.items()}

@router.get("/{member_id}")
async def get_member(member_id: int):
    """회원 정보 조회"""
    print(f"🔵 회원 정보 조회 요청 - member_id: {member_id}")
    
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT * FROM members WHERE member_id = %s", (member_id,))
        member = cursor.fetchone()
        
        if not member:
            raise HTTPException(status_code=404, detail="Member not found")
        
        print(f"✅ 회원 정보 조회 성공: {member.get('member_name')}, profileImage: {member.get('profile_image')}")
        return _format_member_row(member)
        
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(f"❌ Get member error: {e}")
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Failed to get member: {str(e)}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.post("/upload-profile-image")
async def upload_profile_image(file: UploadFile = File(...)):
    """프로필 이미지 업로드"""
    try:
        # 이미지 파일만 허용
        allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
        file_ext = os.path.splitext(file.filename)[1].lower()
        
        if file_ext not in allowed_extensions:
            raise HTTPException(status_code=400, detail="지원하지 않는 파일 형식입니다")
        
        # 파일 크기 검사 (5MB)
        file.file.seek(0, 2)  # 파일 끝으로 이동
        file_size = file.file.tell()
        file.file.seek(0)  # 파일 시작으로 되돌리기
        
        if file_size > 5 * 1024 * 1024:  # 5MB
            raise HTTPException(status_code=400, detail="파일 크기는 5MB를 초과할 수 없습니다")
        
        # 저장 디렉토리 생성
        upload_dir = UPLOAD_DIR / "profiles"
        upload_dir.mkdir(parents=True, exist_ok=True)
        
        # 고유 파일명 생성
        unique_filename = f"{uuid.uuid4()}{file_ext}"
        file_path = upload_dir / unique_filename
        
        # 파일 저장
        with open(file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        # URL 경로 반환
        image_url = f"/uploads/profiles/{unique_filename}"
        print(f"✅ 프로필 이미지 업로드 성공: {image_url}")
        
        return {"imageUrl": image_url}
        
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(f"❌ 프로필 이미지 업로드 오류: {e}")
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"이미지 업로드 실패: {str(e)}")

@router.put("/{member_id}/profile")
async def update_profile(member_id: int, profile: ProfileUpdateRequest):
    """프로필 정보 업데이트"""
    print(f"🔵 Profile update 요청 받음 - member_id: {member_id}")
    print(f"📦 받은 데이터: {profile.dict()}")
    
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        print(f"✅ DB 연결 성공")

        # Check if member exists
        cursor.execute("SELECT * FROM members WHERE member_id = %s", (member_id,))
        member = cursor.fetchone()
        print(f"🔍 회원 조회 결과: {member}")
        if not member:
            print(f"❌ 회원 없음: member_id={member_id}")
            raise HTTPException(status_code=404, detail="Member not found")

        # 업데이트할 필드 구성
        update_fields = []
        update_values = []
        
        if profile.member_name is not None:
            update_fields.append("member_name = %s")
            update_values.append(profile.member_name)
            
        if profile.email is not None:
            update_fields.append("email = %s")
            update_values.append(profile.email)
            
        if profile.profile_image is not None:
            update_fields.append("profile_image = %s")
            update_values.append(profile.profile_image)
        
        if not update_fields:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        # 업데이트 쿼리 실행
        update_values.append(member_id)
        query = f"UPDATE members SET {', '.join(update_fields)} WHERE member_id = %s"
        print(f"🔄 SQL: {query}")
        print(f"🔄 Values: {update_values}")
        
        cursor.execute(query, update_values)
        conn.commit()
        print(f"✅ 프로필 업데이트 완료")
        
        # 업데이트된 회원 정보 조회
        cursor.execute("SELECT * FROM members WHERE member_id = %s", (member_id,))
        updated_member = cursor.fetchone()
        
        return _format_member_row(updated_member)

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(f"❌ Profile update error: {e}")
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Failed to update profile: {str(e)}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
        print(f"🔒 DB 연결 종료")

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
        
        # 질병 및 알러지 분류
        diseases = []
        allergies = []
        
        for item in info.diseases:
            if item.startswith('allergy-'):
                allergies.append(item)
            elif item != 'none' and item != 'allergy':
                diseases.append(item)
        
        print(f"🔄 매핑 결과:")
        print(f"  - gender: {info.gender} (M/F/O)")
        print(f"  - height: {info.height} → height_cm")
        print(f"  - weight: {info.weight} → weight_kg")
        print(f"  - exercise: {info.exercise_frequency} → activity_level: {activity_level}")
        print(f"  - sleep: {info.sleep_duration} → sleep_pattern: {sleep_pattern}")
        print(f"  - diseases: {diseases} → member_disease 테이블")
        print(f"  - allergies: {allergies} → member_allergy 테이블")
        
        # Update members table (flag 없이 sleep_pattern만 추가)
        cursor.execute(
            """UPDATE members 
               SET gender = %s,
                   height_cm = %s,
                   weight_kg = %s,
                   activity_level = %s,
                   sleep_pattern = %s
               WHERE member_id = %s""",
            (
                info.gender,
                info.height,
                info.weight,
                activity_level,
                sleep_pattern,
                member_id
            )
        )
        
        # 기존 질병 정보 삭제 후 재등록
        cursor.execute("DELETE FROM member_disease WHERE member_id = %s", (member_id,))
        for disease in diseases:
            cursor.execute(
                "INSERT INTO member_disease (member_id, disease_name) VALUES (%s, %s)",
                (member_id, disease)
            )
        print(f"✅ 질병 정보 {len(diseases)}개 저장됨")
        
        # 기존 알러지 정보 삭제 후 재등록
        cursor.execute("DELETE FROM member_allergy WHERE member_id = %s", (member_id,))
        for allergy in allergies:
            cursor.execute(
                "INSERT INTO member_allergy (member_id, allergy_name) VALUES (%s, %s)",
                (member_id, allergy)
            )
        print(f"✅ 알러지 정보 {len(allergies)}개 저장됨")
        
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


@router.get("/{member_id}/activity-stats", response_model=ActivityStatsResponse)
async def get_activity_stats(member_id: int):
    """회원의 식단/운동/게시글/좋아요 누적 통계를 반환"""

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        def _fetch_count(query: str) -> int:
            cursor.execute(query, (member_id,))
            result = cursor.fetchone()
            if not result:
                return 0
            value = result.get("count")
            return int(value or 0)

        meal_count = _fetch_count("SELECT COUNT(*) AS count FROM meal_log WHERE member_id = %s")
        workout_count = _fetch_count("SELECT COUNT(*) AS count FROM exercise_log WHERE member_id = %s")
        post_count = _fetch_count("SELECT COUNT(*) AS count FROM post WHERE member_id = %s")
        like_count = _fetch_count("SELECT COUNT(*) AS count FROM post_like WHERE member_id = %s")

        return ActivityStatsResponse(
            meal_count=meal_count,
            workout_count=workout_count,
            post_count=post_count,
            like_count=like_count,
        )

    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to load activity stats: {exc}",
        ) from exc
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@router.put("/{member_id}/calorie-goal")
async def update_calorie_goal(member_id: int, goal: CalorieGoalUpdate):
    """회원의 일일 칼로리 목표 업데이트"""
    print(f"🔵 Calorie goal update 요청 받음 - member_id: {member_id}")
    print(f"📦 받은 데이터: {goal.dict()}")
    
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

        # Validate calorie goal range
        if goal.calorie_goal < 500 or goal.calorie_goal > 10000:
            print(f"❌ 잘못된 칼로리 목표 값: {goal.calorie_goal}")
            raise HTTPException(status_code=400, detail="Calorie goal must be between 500 and 10000")

        # Update calorie goal
        cursor.execute(
            """UPDATE members 
               SET calorie_goal = %s
               WHERE member_id = %s""",
            (goal.calorie_goal, member_id)
        )
        
        conn.commit()
        print(f"✅ 칼로리 목표 업데이트 완료: {goal.calorie_goal}kcal")
        
        return {"message": "Calorie goal updated successfully", "calorie_goal": goal.calorie_goal}

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(f"❌ Calorie goal update error: {e}")
        print(f"❌ Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Failed to update calorie goal: {str(e)}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
        print(f"🔒 DB 연결 종료")


@router.delete("/{member_id}")
async def delete_member(member_id: int):
    """회원 탈퇴 처리"""
    print(f"👋 회원 탈퇴 요청 - member_id: {member_id}")
    
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # 회원 존재 확인
        cursor.execute("SELECT member_id FROM members WHERE member_id = %s", (member_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Member not found")
            
        # 1. 관련 테이블 데이터 삭제
        tables = [
            "exercise_log", "meal_log", "post_like", "post_comment", 
            "post", "member_badges", "member_disease", "health_info", 
            "weight_log"
        ]
        
        for table in tables:
            cursor.execute(f"DELETE FROM {table} WHERE member_id = %s", (member_id,))
        
        # 2. 회원 삭제
        cursor.execute("DELETE FROM members WHERE member_id = %s", (member_id,))
        
        conn.commit()
        print(f"✅ 회원 탈퇴 완료: member_id={member_id}")
        return {"message": "Account deleted successfully"}
        
    except Exception as e:
        print(f"❌ 회원 탈퇴 오류: {e}")
        if conn:
            conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
        print(f"🔒 DB 연결 종료")


@router.get("/{member_id}/friends", summary="Friend List")
async def get_friends(member_id: int):
    """Get friends list for a member"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """SELECT m.member_id, m.email, m.nickname, m.profile_image, m.calorie_goal
               FROM friend f
               INNER JOIN members m ON f.friend_member_id = m.member_id
               WHERE f.member_id = %s AND f.status = 'ACCEPTED' AND m.member_status = 'ACTIVE'
               ORDER BY m.nickname""",
            (member_id,)
        )
        friends = cursor.fetchall()
        return [_format_member_row(friend) for friend in friends]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
