#!/bin/bash
# Render 시작 스크립트

# 환경 변수 설정
export PYTHONUNBUFFERED=1

# AI 모델 비활성화 (무료 플랜 메모리 제한 512MB 대응)
export DISABLE_AI_MODELS=true

echo "⏭️ AI 모델 다운로드 스킵 (메모리 제한)"
echo "   AI 식사 분석은 Mock 데이터로 동작합니다"

# 서버 시작
uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
