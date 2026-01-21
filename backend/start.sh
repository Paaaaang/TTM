#!/bin/bash
# Render 시작 스크립트 (Persistent Disk + 2GB Standard)

# 환경 변수 설정
export PYTHONUNBUFFERED=1

# Persistent Disk 경로 설정 (Render에서 /var/data에 마운트됨)
export AI_MODELS_BASE_PATH="${AI_MODELS_BASE_PATH:-/var/data/ai_models}"

# AI 모델 활성화 (Standard 플랜 2GB + Persistent Disk)
export DISABLE_AI_MODELS=false

# 워커 수 제한 (메모리 최적화)
export WEB_CONCURRENCY=1

echo "="*60
echo "🚀 Render 서버 시작 (Persistent Disk)"
echo "="*60
echo "📂 AI 모델 경로: $AI_MODELS_BASE_PATH"
echo "👷 워커 수: $WEB_CONCURRENCY"
echo "💾 메모리 제한: 2GB (Standard)"
echo "="*60

# 서버 시작 (FastAPI가 startup 이벤트에서 모델 검증)
uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000} --workers ${WEB_CONCURRENCY:-1}
