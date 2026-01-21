#!/bin/bash
# Render 시작 스크립트

# 환경 변수 설정
export PYTHONUNBUFFERED=1

# AI 모델 활성화 (Starter 플랜 이상 필요)
export DISABLE_AI_MODELS=false

echo "🤖 AI 모델 다운로드 확인 중..."
python download_models.py

# 서버 시작
uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
