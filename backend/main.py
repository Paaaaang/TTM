from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, members, meals, exercises, posts, badges, health
import uvicorn

app = FastAPI(
    title="TTM Backend API",
    description="FastAPI + MySQL 기반 REST API 서버",
    version="1.0.0"
)

# CORS 설정 (Flutter 앱에서 접근 가능)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 특정 도메인만 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 등록
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(members.router, prefix="/api/members", tags=["members"])
app.include_router(meals.router, tags=["meals"])  # prefix는 router 내부에 정의됨
app.include_router(exercises.router, tags=["exercises"])  # prefix는 router 내부에 정의됨
app.include_router(posts.router, tags=["posts"])  # prefix는 router 내부에 정의됨
app.include_router(badges.router, tags=["badges"])  # prefix는 router 내부에 정의됨
app.include_router(health.router, tags=["health"])  # prefix는 router 내부에 정의됨

@app.get("/")
async def root():
    return {"message": "TTM Backend API Server is running!"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=3000, reload=True)
