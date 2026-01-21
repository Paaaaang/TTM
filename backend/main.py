"""
TTM Backend API Server

FastAPI + MySQL 기반 건강 관리 애플리케이션 백엔드 서버

Features:
    - 회원 인증 및 관리
    - 식단 기록 및 AI 분석
    - 운동 기록 및 체중 추적
    - 커뮤니티 (게시글, 댓글)
    - 배지 시스템
    - FCM 푸시 알림
    
Environment:
    - DB_HOST: MySQL 호스트
    - DB_USER: MySQL 사용자
    - DB_PASSWORD: MySQL 비밀번호
    - DB_NAME: 데이터베이스 이름
    - SECRET_KEY: JWT 시크릿 키
    
Run:
    python main.py
    or
    uvicorn main:app --host 0.0.0.0 --port 3000 --reload
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routers import (
    auth, members, meals, exercises, posts, 
    badges, health, weight, ai, comments, notifications, friend_groups
)
from routers import iot
import uvicorn
from pathlib import Path
from dotenv import load_dotenv
import os

# 환경 변수 로드
load_dotenv()

# FastAPI 앱 생성
app = FastAPI(
    title="TTM Backend API",
    description="건강 관리 애플리케이션 REST API 서버",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# 서버 시작 시 실행되는 이벤트
@app.on_event("startup")
async def startup_event():
    """서버 시작 시 AI 모델 미리 로드"""
    print("\n" + "="*60)
    print("🚀 서버 시작: AI 모델 사전 로딩")
    print("="*60)
    
    # AI 모델 비활성화 설정 확인
    if os.getenv("DISABLE_AI_MODELS", "false").lower() == "true":
        print("⏭️ AI 모델 로딩 스킵 (DISABLE_AI_MODELS=true)")
        return
    
    try:
        # nutrition_analyzer 모듈에서 모델 로드 함수 임포트
        from services.nutrition_analyzer import load_yolo_model, load_resnet_model, load_nutrition_db
        
        # 영양 DB 로드
        load_nutrition_db()
        
        # YOLO 모델 로드
        yolo_model, class_names = load_yolo_model()
        if yolo_model:
            print("✅ YOLO 모델 사전 로딩 완료")
        else:
            print("⚠️ YOLO 모델 로드 실패 (Mock 모드로 실행)")
        
        # ResNet 모델 로드
        resnet_model = load_resnet_model()
        if resnet_model:
            print("✅ ResNet 모델 사전 로딩 완료")
        else:
            print("⚠️ ResNet 모델 로드 실패")
            
    except Exception as e:
        print(f"⚠️ AI 모델 사전 로딩 중 오류: {e}")
        print("   서버는 계속 실행되지만 AI 기능이 제한될 수 있습니다")
    
    print("="*60)
    print("✅ 서버 시작 완료")
    print("="*60 + "\n")

# CORS 미들웨어 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: 프로덕션에서는 특정 도메인만 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 업로드 디렉토리 설정
BASE_DIR = Path(__file__).resolve().parent
UPLOAD_DIR = BASE_DIR / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)

# 정적 파일 서빙 (업로드된 이미지/파일)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")

# 라우터 등록
app.include_router(auth.router, prefix="/api/auth", tags=["인증"])
app.include_router(members.router, prefix="/api/members", tags=["회원"])
app.include_router(meals.router, prefix="/api/meals", tags=["식단"])
app.include_router(exercises.router, prefix="/api/exercises", tags=["운동"])
app.include_router(weight.router, prefix="/api/weight", tags=["체중"])
app.include_router(health.router, prefix="/api/health", tags=["건강"])
app.include_router(posts.router, prefix="/api/posts", tags=["커뮤니티"])
app.include_router(comments.router, tags=["댓글"])  # comments.py에 이미 /api 경로 포함됨
app.include_router(badges.router, prefix="/api/badges", tags=["배지"])
app.include_router(ai.router, prefix="/api/ai", tags=["AI"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["알림"])
app.include_router(iot.router, prefix="/api/iot", tags=["IoT"])
app.include_router(friend_groups.router, tags=["친구 그룹"])  # /api/groups 경로 포함됨

@app.get("/", tags=["Root"])
async def root():
    """
    서버 상태 확인
    
    Returns:
        서버 실행 상태 메시지
    """
    return {
        "message": "TTM Backend API Server is running!",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc"
    }

@app.get("/health", tags=["Root"])
async def health_check():
    """
    헬스 체크 엔드포인트
    
    Returns:
        서버 상태
    """
    return {"status": "healthy", "service": "TTM Backend"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=3000,
        reload=True,
        log_level="info"
    )
