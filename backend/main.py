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
    """
    서버 시작 시 AI 모델 파일 검증/다운로드
    
    주의: torch.load는 하지 않음 (메모리 최적화)
          첫 API 요청 시 lazy loading
    """
    print("\n" + "="*60)
    print("🚀 서버 시작: AI 모델 파일 검증")
    print("="*60)
    
    # AI 모델 비활성화 설정 확인
    if os.getenv("DISABLE_AI_MODELS", "false").lower() == "true":
        print("⏭️ AI 모델 검증 스킵 (DISABLE_AI_MODELS=true)")
        print("="*60 + "\n")
        return
    
    try:
        from config.model_paths import (
            YOLO_WEIGHTS, RESNET_WEIGHTS,
            YOLO_DRIVE_ID, RESNET_DRIVE_ID,
            YOLO_MIN_SIZE, RESNET_MIN_SIZE
        )
        from utils.model_downloader import ModelDownloader
        
        # 모델 다운로더 생성
        downloader = ModelDownloader()
        
        # 모델 파일 검증/다운로드 (torch.load는 안 함)
        models_config = [
            {
                'name': 'yolo',
                'drive_id': YOLO_DRIVE_ID,
                'destination': YOLO_WEIGHTS,
                'min_size': YOLO_MIN_SIZE
            },
            {
                'name': 'resnet',
                'drive_id': RESNET_DRIVE_ID,
                'destination': RESNET_WEIGHTS,
                'min_size': RESNET_MIN_SIZE
            }
        ]
        
        results = downloader.ensure_models(models_config)
        
        # 결과 출력
        for model_name, success in results.items():
            if success:
                print(f"✅ {model_name.upper()} 모델 파일 준비 완료")
            else:
                print(f"❌ {model_name.upper()} 모델 파일 준비 실패")
        
        # 모든 모델이 준비되었는지 확인
        if all(results.values()):
            print("✅ 모든 AI 모델 파일 준비 완료 (lazy loading 대기)")
        else:
            print("⚠️ 일부 AI 모델 파일 준비 실패 (AI 기능 제한됨)")
            
    except Exception as e:
        print(f"⚠️ AI 모델 파일 검증 중 오류: {e}")
        print("   서버는 계속 실행되지만 AI 기능이 제한될 수 있습니다")
        import traceback
        traceback.print_exc()
    
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


@app.get("/api/models/status", tags=["AI"])
async def models_status():
    """
    AI 모델 파일 및 로딩 상태 확인
    
    Persistent Disk 마운트 및 모델 파일 존재 여부 확인
    """
    try:
        from config.model_paths import (
            YOLO_WEIGHTS, 
            RESNET_WEIGHTS,
            AI_MODELS_BASE
        )
        
        # 모델 파일 존재 확인
        yolo_exists = YOLO_WEIGHTS.exists()
        resnet_exists = RESNET_WEIGHTS.exists()
        
        # 모델 로딩 상태 확인 (전역 캐시)
        from services.nutrition_analyzer import _yolo_model, _resnet_model
        
        return {
            "status": "ok",
            "ai_models_base": str(AI_MODELS_BASE),
            "models": {
                "yolo": {
                    "file_exists": yolo_exists,
                    "file_path": str(YOLO_WEIGHTS),
                    "file_size_mb": round(YOLO_WEIGHTS.stat().st_size / (1024*1024), 2) if yolo_exists else None,
                    "loaded": _yolo_model is not None
                },
                "resnet": {
                    "file_exists": resnet_exists,
                    "file_path": str(RESNET_WEIGHTS),
                    "file_size_mb": round(RESNET_WEIGHTS.stat().st_size / (1024*1024), 2) if resnet_exists else None,
                    "loaded": _resnet_model is not None
                }
            },
            "persistent_disk_mounted": AI_MODELS_BASE.exists()
        }
    except Exception as e:
        import traceback
        return {
            "status": "error",
            "error": str(e),
            "traceback": traceback.format_exc()
        }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=3000,
        reload=True,
        log_level="info"
    )
