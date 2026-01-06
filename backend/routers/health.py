"""
건강정보 API 라우터

member_disease, member_allergy 테이블 엔드포인트 제공:
- GET /api/health/diseases/{member_id} - 회원 질병 정보 조회
- POST /api/health/diseases/ - 질병 정보 추가
- DELETE /api/health/diseases/{member_disease_id} - 질병 정보 삭제
- GET /api/health/allergies/{member_id} - 회원 알레르기 정보 조회
- POST /api/health/allergies/ - 알레르기 정보 추가
- DELETE /api/health/allergies/{allergy_id} - 알레르기 정보 삭제
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from config.database import get_db_connection

router = APIRouter(prefix="/api/health", tags=["health"])


# ============================================================
# Pydantic 모델 정의
# ============================================================

class DiseaseCreate(BaseModel):
    """질병 정보 추가 요청"""
    member_id: int
    disease_name: str
    description: Optional[str] = None


class DiseaseResponse(BaseModel):
    """질병 정보 응답"""
    member_disease_id: int
    member_id: int
    disease_name: str
    description: Optional[str]
    created_at: Optional[str]


class AllergyCreate(BaseModel):
    """알레르기 정보 추가 요청"""
    member_id: int
    allergy_name: str
    description: Optional[str] = None


class AllergyResponse(BaseModel):
    """알레르기 정보 응답"""
    allergy_id: int
    member_id: int
    allergy_name: str
    description: Optional[str]


# ============================================================
# 질병 정보 API
# ============================================================

@router.get("/diseases/{member_id}", response_model=List[DiseaseResponse])
async def get_member_diseases(member_id: int):
    """
    회원 질병 정보 조회
    
    Args:
        member_id: 회원 ID
        
    Returns:
        회원의 질병 정보 리스트
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        query = """
            SELECT 
                member_disease_id,
                member_id,
                disease_name,
                description,
                created_at
            FROM member_disease
            WHERE member_id = %s
            ORDER BY created_at DESC
        """
        
        cursor.execute(query, (member_id,))
        diseases = cursor.fetchall()
        
        # datetime을 문자열로 변환
        for disease in diseases:
            if disease['created_at']:
                disease['created_at'] = disease['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return diseases
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"질병 정보 조회 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.post("/diseases/", response_model=DiseaseResponse)
async def add_disease(request: DiseaseCreate):
    """
    질병 정보 추가
    
    Args:
        request: 질병 정보 추가 요청
        
    Returns:
        추가된 질병 정보
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        insert_query = """
            INSERT INTO member_disease (member_id, disease_name, description, created_at)
            VALUES (%s, %s, %s, NOW())
        """
        
        cursor.execute(insert_query, (
            request.member_id,
            request.disease_name,
            request.description
        ))
        
        member_disease_id = cursor.lastrowid
        conn.commit()
        
        # 추가된 정보 조회
        cursor.execute("""
            SELECT 
                member_disease_id,
                member_id,
                disease_name,
                description,
                created_at
            FROM member_disease
            WHERE member_disease_id = %s
        """, (member_disease_id,))
        
        result = cursor.fetchone()
        
        if result['created_at']:
            result['created_at'] = result['created_at'].strftime('%Y-%m-%d %H:%M:%S')
        
        return result
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"질병 정보 추가 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.delete("/diseases/{member_disease_id}")
async def delete_disease(member_disease_id: int):
    """
    질병 정보 삭제
    
    Args:
        member_disease_id: 질병 정보 ID
        
    Returns:
        삭제 성공 메시지
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 존재 확인
        cursor.execute(
            "SELECT member_disease_id FROM member_disease WHERE member_disease_id = %s",
            (member_disease_id,)
        )
        disease = cursor.fetchone()
        
        if not disease:
            raise HTTPException(status_code=404, detail="질병 정보를 찾을 수 없습니다")
        
        # 삭제
        cursor.execute("DELETE FROM member_disease WHERE member_disease_id = %s", (member_disease_id,))
        conn.commit()
        
        return {"message": "질병 정보가 삭제되었습니다"}
        
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"질병 정보 삭제 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


# ============================================================
# 알레르기 정보 API
# ============================================================

@router.get("/allergies/{member_id}", response_model=List[AllergyResponse])
async def get_member_allergies(member_id: int):
    """
    회원 알레르기 정보 조회
    
    Args:
        member_id: 회원 ID
        
    Returns:
        회원의 알레르기 정보 리스트
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        query = """
            SELECT 
                allergy_id,
                member_id,
                allergy_name,
                description
            FROM member_allergy
            WHERE member_id = %s
            ORDER BY allergy_id
        """
        
        cursor.execute(query, (member_id,))
        allergies = cursor.fetchall()
        
        return allergies
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"알레르기 정보 조회 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.post("/allergies/", response_model=AllergyResponse)
async def add_allergy(request: AllergyCreate):
    """
    알레르기 정보 추가
    
    Args:
        request: 알레르기 정보 추가 요청
        
    Returns:
        추가된 알레르기 정보
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        insert_query = """
            INSERT INTO member_allergy (member_id, allergy_name, description)
            VALUES (%s, %s, %s)
        """
        
        cursor.execute(insert_query, (
            request.member_id,
            request.allergy_name,
            request.description
        ))
        
        allergy_id = cursor.lastrowid
        conn.commit()
        
        # 추가된 정보 조회
        cursor.execute("""
            SELECT 
                allergy_id,
                member_id,
                allergy_name,
                description
            FROM member_allergy
            WHERE allergy_id = %s
        """, (allergy_id,))
        
        result = cursor.fetchone()
        
        return result
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"알레르기 정보 추가 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()


@router.delete("/allergies/{allergy_id}")
async def delete_allergy(allergy_id: int):
    """
    알레르기 정보 삭제
    
    Args:
        allergy_id: 알레르기 정보 ID
        
    Returns:
        삭제 성공 메시지
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 존재 확인
        cursor.execute(
            "SELECT allergy_id FROM member_allergy WHERE allergy_id = %s",
            (allergy_id,)
        )
        allergy = cursor.fetchone()
        
        if not allergy:
            raise HTTPException(status_code=404, detail="알레르기 정보를 찾을 수 없습니다")
        
        # 삭제
        cursor.execute("DELETE FROM member_allergy WHERE allergy_id = %s", (allergy_id,))
        conn.commit()
        
        return {"message": "알레르기 정보가 삭제되었습니다"}
        
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"알레르기 정보 삭제 실패: {str(e)}")
    finally:
        cursor.close()
        conn.close()
