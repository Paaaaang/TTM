#!/usr/bin/env python3
"""
Render Persistent Disk 배포 전 검증 스크립트

배포 전에 로컬에서 실행하여 모든 파일이 올바르게 설정되었는지 확인
"""
import os
import sys
from pathlib import Path

def check_file_exists(file_path: Path, description: str) -> bool:
    """파일 존재 확인"""
    if file_path.exists():
        print(f"✅ {description}: {file_path}")
        return True
    else:
        print(f"❌ {description} 없음: {file_path}")
        return False

def check_import(module_path: str, description: str) -> bool:
    """Python 모듈 임포트 가능 확인"""
    try:
        __import__(module_path)
        print(f"✅ {description} 임포트 가능")
        return True
    except ImportError as e:
        print(f"❌ {description} 임포트 실패: {e}")
        return False

def main():
    print("="*70)
    print("🔍 Render Persistent Disk 배포 전 검증")
    print("="*70)
    
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)
    
    # sys.path에 backend 추가
    sys.path.insert(0, str(backend_dir))
    
    all_checks = []
    
    # 1. 핵심 설정 파일 확인
    print("\n📁 1. 설정 파일 확인")
    all_checks.append(check_file_exists(
        backend_dir / "config" / "model_paths.py",
        "모델 경로 설정"
    ))
    all_checks.append(check_file_exists(
        backend_dir / "utils" / "model_downloader.py",
        "모델 다운로더"
    ))
    all_checks.append(check_file_exists(
        backend_dir / "services" / "model_loader.py",
        "모델 로더"
    ))
    all_checks.append(check_file_exists(
        backend_dir / "services" / "nutrition_analyzer.py",
        "영양 분석 서비스"
    ))
    all_checks.append(check_file_exists(
        backend_dir / "main.py",
        "FastAPI 메인"
    ))
    all_checks.append(check_file_exists(
        backend_dir / "start.sh",
        "Render 시작 스크립트"
    ))
    
    # 2. 모듈 임포트 확인
    print("\n📦 2. Python 모듈 임포트 확인")
    all_checks.append(check_import(
        "config.model_paths",
        "config.model_paths"
    ))
    all_checks.append(check_import(
        "utils.model_downloader",
        "utils.model_downloader"
    ))
    
    # 3. 환경 변수 기본값 확인
    print("\n🔧 3. config.model_paths 설정 확인")
    try:
        from config.model_paths import (
            AI_MODELS_BASE,
            YOLO_WEIGHTS,
            RESNET_WEIGHTS,
            YOLO_DRIVE_ID,
            RESNET_DRIVE_ID,
            YOLO_MIN_SIZE,
            RESNET_MIN_SIZE
        )
        print(f"✅ AI_MODELS_BASE: {AI_MODELS_BASE}")
        print(f"✅ YOLO_WEIGHTS: {YOLO_WEIGHTS}")
        print(f"✅ RESNET_WEIGHTS: {RESNET_WEIGHTS}")
        print(f"✅ YOLO_DRIVE_ID: {YOLO_DRIVE_ID[:20]}...")
        print(f"✅ RESNET_DRIVE_ID: {RESNET_DRIVE_ID[:20]}...")
        print(f"✅ YOLO_MIN_SIZE: {YOLO_MIN_SIZE / (1024*1024):.1f} MB")
        print(f"✅ RESNET_MIN_SIZE: {RESNET_MIN_SIZE / (1024*1024):.1f} MB")
        all_checks.append(True)
    except Exception as e:
        print(f"❌ config.model_paths 설정 오류: {e}")
        all_checks.append(False)
    
    # 4. start.sh 내용 확인
    print("\n🚀 4. start.sh 스크립트 확인")
    start_sh_path = backend_dir / "start.sh"
    if start_sh_path.exists():
        content = start_sh_path.read_text()
        
        required_lines = [
            "AI_MODELS_BASE_PATH",
            "DISABLE_AI_MODELS=false",
            "WEB_CONCURRENCY=1",
            "uvicorn main:app"
        ]
        
        for line in required_lines:
            if line in content:
                print(f"✅ start.sh: '{line}' 포함")
                all_checks.append(True)
            else:
                print(f"❌ start.sh: '{line}' 없음")
                all_checks.append(False)
    else:
        print("❌ start.sh 파일 없음")
        all_checks.append(False)
    
    # 5. requirements.txt 확인
    print("\n📦 5. requirements.txt 의존성 확인")
    req_path = backend_dir / "requirements.txt"
    if req_path.exists():
        content = req_path.read_text()
        
        required_packages = [
            "gdown",
            "torch",
            "torchvision",
            "ultralytics",
            "fastapi",
            "uvicorn"
        ]
        
        for pkg in required_packages:
            if pkg in content.lower():
                print(f"✅ requirements.txt: '{pkg}' 포함")
                all_checks.append(True)
            else:
                print(f"❌ requirements.txt: '{pkg}' 없음")
                all_checks.append(False)
    else:
        print("❌ requirements.txt 파일 없음")
        all_checks.append(False)
    
    # 6. ModelDownloader 클래스 검증
    print("\n🔒 6. ModelDownloader 파일락 구현 확인")
    try:
        from utils.model_downloader import ModelDownloader
        
        # 필수 메소드 확인
        required_methods = [
            '_acquire_lock',
            '_release_lock',
            'verify_file',
            'download_model',
            'ensure_models'
        ]
        
        for method in required_methods:
            if hasattr(ModelDownloader, method):
                print(f"✅ ModelDownloader.{method} 존재")
                all_checks.append(True)
            else:
                print(f"❌ ModelDownloader.{method} 없음")
                all_checks.append(False)
    except Exception as e:
        print(f"❌ ModelDownloader 검증 실패: {e}")
        all_checks.append(False)
    
    # 최종 결과
    print("\n" + "="*70)
    success_count = sum(all_checks)
    total_count = len(all_checks)
    
    if all(all_checks):
        print(f"✅ 모든 검증 통과 ({success_count}/{total_count})")
        print("\n🚀 배포 준비 완료!")
        print("\n다음 단계:")
        print("1. Render Dashboard에서 Persistent Disk 생성 (3GB, /var/data)")
        print("2. Web Service에 Disk 연결")
        print("3. 환경 변수 설정:")
        print("   - AI_MODELS_BASE_PATH=/var/data/ai_models")
        print("   - YOLO_DRIVE_ID=1yBITpY563jVUNmx_wIQvn3bJ5yj5OrDE")
        print("   - RESNET_DRIVE_ID=1ROaLfNs40PyESJTBP3b2bN0p_oeg46HH")
        print("   - DISABLE_AI_MODELS=false")
        print("   - WEB_CONCURRENCY=1")
        print("4. git push origin master")
        print("5. Render 자동 배포 대기")
        print("6. /api/models/status 엔드포인트 확인")
        return 0
    else:
        print(f"❌ 검증 실패 ({success_count}/{total_count})")
        print("\n위에 표시된 ❌ 항목을 먼저 수정하세요.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
