"""
AI 모델 자동 다운로드 스크립트
Render 배포 시 시작 전에 실행됩니다.
"""
import os
import requests
from pathlib import Path
import sys

# 모델 다운로드 URL 설정 (Google Drive 공유 링크 또는 직접 URL)
MODEL_URLS = {
    "yolo": {
        "url": "https://drive.google.com/uc?export=download&id=1yBITpY563jVUNmx_wIQvn3bJ5yj5OrDE",  # 247MB YOLO 모델
        "path": "ai_models/Food_classification/yolov3/weights/best_403food_e200b150v2.pt"
    },
    "resnet": {
        "url": "https://drive.google.com/uc?export=download&id=1ROaLfNs40PyESJTBP3b2bN0p_oeg46HH",  # 85MB ResNet 모델
        "path": "ai_models/E_of_the_a_of_food/quantity_est/weights/new_opencv_ckpt_b84_e200.pth"
    }
}

def download_file(url: str, destination: str):
    """파일 다운로드"""
    print(f"📥 다운로드 중: {destination}")
    
    # 디렉토리 생성
    Path(destination).parent.mkdir(parents=True, exist_ok=True)
    
    # Google Drive 직접 다운로드 URL 변환
    if "drive.google.com" in url:
        file_id = url.split("/d/")[1].split("/")[0] if "/d/" in url else url.split("id=")[1].split("&")[0]
        url = f"https://drive.google.com/uc?export=download&id={file_id}"
    
    try:
        # 스트리밍 다운로드 (큰 파일 지원)
        response = requests.get(url, stream=True, timeout=300)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        downloaded = 0
        
        with open(destination, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\r진행률: {percent:.1f}%", end="", flush=True)
        
        print(f"\n✅ 다운로드 완료: {destination}")
        return True
        
    except Exception as e:
        print(f"\n❌ 다운로드 실패: {e}")
        return False

def check_models_exist():
    """모델 파일 존재 확인"""
    all_exist = True
    for name, info in MODEL_URLS.items():
        path = info["path"]
        if os.path.exists(path):
            size = os.path.getsize(path) / (1024 * 1024)  # MB
            print(f"✅ {name}: {path} ({size:.1f}MB)")
        else:
            print(f"❌ {name}: {path} (없음)")
            all_exist = False
    return all_exist

def main():
    print("="*60)
    print("🤖 AI 모델 다운로드 시작")
    print("="*60)
    
    # 환경 변수로 다운로드 비활성화 가능
    if os.getenv("SKIP_MODEL_DOWNLOAD") == "true":
        print("⏭️ 모델 다운로드 스킵 (SKIP_MODEL_DOWNLOAD=true)")
        return
    
    # 이미 모델이 있는지 확인
    if check_models_exist():
        print("\n✅ 모든 모델이 이미 존재합니다.")
        return
    
    print("\n📥 모델 다운로드를 시작합니다...")
    
    # 각 모델 다운로드
    for name, info in MODEL_URLS.items():
        url = info["url"]
        path = info["path"]
        
        # URL이 설정되지 않은 경우
        if "YOUR_GOOGLE_DRIVE_LINK_HERE" in url:
            print(f"\n⚠️ {name} 모델 URL이 설정되지 않았습니다.")
            print(f"   download_models.py에서 {name} URL을 설정해주세요.")
            continue
        
        # 이미 파일이 있으면 스킵
        if os.path.exists(path):
            print(f"\n⏭️ {name} 모델이 이미 존재합니다.")
            continue
        
        # 다운로드 시도
        success = download_file(url, path)
        if not success:
            print(f"❌ {name} 모델 다운로드 실패")
            sys.exit(1)
    
    print("\n" + "="*60)
    print("✅ AI 모델 다운로드 완료")
    print("="*60)
    
    # 최종 확인
    check_models_exist()

if __name__ == "__main__":
    main()
