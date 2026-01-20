#!/bin/bash
# Render 시작 스크립트 (AI 모델 다운로드 포함)

echo "=================================="
echo "🚀 TTM Backend 시작 (AI 모델 포함)"
echo "=================================="

# 1. AI 모델 다운로드
echo ""
echo "📥 Step 1: AI 모델 다운로드 확인"
python download_models.py

# 다운로드 실패 시에도 계속 진행 (Mock 데이터로 대체)
if [ $? -ne 0 ]; then
    echo "⚠️ 모델 다운로드 실패 - Mock 데이터로 진행"
fi

# 2. 서버 시작
echo ""
echo "🌐 Step 2: FastAPI 서버 시작"
uvicorn main:app --host 0.0.0.0 --port $PORT
