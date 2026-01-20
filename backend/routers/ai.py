from fastapi import APIRouter, HTTPException, Body
import google.generativeai as genai
import os
from pydantic import BaseModel
from typing import Optional, List
from config.database import get_db_connection

class ChatRequest(BaseModel):
    message: str
    member_id: Optional[int] = None

class ChatResponse(BaseModel):
    reply: str

class MealAnalysisRequest(BaseModel):
    member_id: int
    food_name: str
    amount: Optional[str] = None

class MealAnalysisResponse(BaseModel):
    warning: str

router = APIRouter()

# 환경 변수에서 API 키 로드 (또는 직접 입력)
# 실제 배포 시에는 환경 변수 사용 권장
GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY")

# API 키가 없으면 경고 출력 (개발용)
if not GOOGLE_API_KEY:
    print("⚠️ WARNING: GOOGLE_API_KEY not found in environment variables.")

# Gemini 설정
try:
    if GOOGLE_API_KEY:
        genai.configure(api_key=GOOGLE_API_KEY)
        # 'gemini-pro' -> 'gemini-2.0-flash' (최신 안정 모델)
        model = genai.GenerativeModel('gemini-2.0-flash') 
    else:
        model = None
except Exception as e:
    print(f"❌ Gemini Setup Error: {e}")
    model = None

def get_user_health_context(member_id: int) -> str:
    """사용자의 질병 및 알러지 정보를 가져옵니다."""
    if not member_id:
        return ""
    
    conn = None
    cursor = None
    context_str = ""
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # 질병 조회
        cursor.execute("SELECT disease_name FROM member_disease WHERE member_id = %s", (member_id,))
        diseases = [row['disease_name'] for row in cursor.fetchall()]
        
        # 알러지 조회
        cursor.execute("SELECT allergy_name FROM member_allergy WHERE member_id = %s", (member_id,))
        allergies = [row['allergy_name'] for row in cursor.fetchall()]
        
        # 기본 정보 조회
        cursor.execute("SELECT gender, height_cm, weight_kg, birth_date FROM members WHERE member_id = %s", (member_id,))
        member = cursor.fetchone()
        
        if member:
             context_str += f"\n[사용자 신체 정보]\n- 성별: {member.get('gender')}\n- 키: {member.get('height_cm')}cm\n- 몸무게: {member.get('weight_kg')}kg"

        if diseases:
            context_str += f"\n- 보유 질환: {', '.join(diseases)}"
        
        if allergies:
            context_str += f"\n- 알레르기: {', '.join(allergies)}"
            
    except Exception as e:
        print(f"❌ Health Context Error: {e}")
    finally:
        if cursor: cursor.close()
        if conn: conn.close()
        
    return context_str

@router.post("/chat", response_model=ChatResponse)
async def chat_with_ai(request: ChatRequest):
    """Gemini AI와 대화"""
    if not model:
        return ChatResponse(reply="AI 서비스가 현재 설정되지 않았습니다. (API Key Missing)")
    
    try:
        health_context = ""
        if request.member_id:
            health_context = get_user_health_context(request.member_id)

        prompt = f"""
        당신은 건강, 피트니스, 영양 관련 전문 AI 코치입니다.
        사용자의 질문에 친절하고 전문적으로 답변해 주세요.
        
        [사용자 정보]
        {health_context}
        
        [답변 가이드라인]
        1. 사용자의 신체 정보(키, 몸무게 등)는 단순 나열하거나 직접 언급하지 말고, 조언을 생성하기 위한 참고 자료로만 활용하세요.
        2. [중요] 사용자의 '질환'이나 '알러지' 정보와 관련된 음식이거나 운동이라면, 반드시 경고 문구를 답변 최상단에 굵은 글씨(**경고**)와 이모지(🚨)를 사용하여 강력하게 표시해 주세요. 섭취하거나 행동하지 말 것을 명시적으로 권고해야 합니다.
        3. 답변은 가독성을 위해 마크다운(Markdown) 형식을 적극 활용해 주세요. (소제목, 볼드체, 리스트 등)
        
        사용자 질문: {request.message}
        """
        
        response = model.generate_content(prompt)
        return ChatResponse(reply=response.text)
        
    except Exception as e:
        print(f"❌ AI Generation Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/analyze-meal-warning", response_model=MealAnalysisResponse)
async def analyze_meal_warning(request: MealAnalysisRequest):
    """음식 데이터와 사용자 건강 정보를 바탕으로 주의사항을 1-3줄로 요약"""
    if not model:
        return MealAnalysisResponse(warning="AI 서비스 미설정")
        
    try:
        health_context = get_user_health_context(request.member_id)
        
        prompt = f"""
        당신은 영양 전문가입니다.
        다음 사용자가 '{request.food_name}'을(를) 섭취하려고 합니다.
        
        {health_context}
        
        이 사용자의 질병 및 알러지 정보를 바탕으로 이 음식을 먹을 때 주의해야 할 점을
        간단하게 1~3줄로 요약해서 답변해 주세요.
        특별한 주의사항이 없다면 영양학적인 조언을 짧게 해주세요.
        경어체(해요체)를 사용하세요.
        """
        
        response = model.generate_content(prompt)
        return MealAnalysisResponse(warning=response.text.strip())
        
    except Exception as e:
        print(f"❌ Meal Analysis Error: {e}")
        return MealAnalysisResponse(warning="분석 중 오류가 발생했습니다.")

