"""AI 이미지 분석 API 테스트"""
import requests
import os
from pathlib import Path

# 테스트용 이미지 경로 (실제 존재하는 이미지)
test_image_path = "C:/Users/smhrd/Desktop/App/ttm/uploads/meals"

# uploads 폴더에서 첫 번째 이미지 찾기
upload_dir = Path(test_image_path)
if not upload_dir.exists():
    upload_dir.mkdir(parents=True, exist_ok=True)
    print("⚠️ uploads 폴더 생성됨. 테스트 이미지를 넣어주세요.")
else:
    # 첫 번째 이미지 파일 찾기
    image_files = list(upload_dir.glob("*.jpg")) + list(upload_dir.glob("*.png"))
    
    if not image_files:
        print("⚠️ 테스트 이미지가 없습니다. uploads/meals 폴더에 이미지를 추가하세요.")
    else:
        test_image = image_files[0]
        print(f"✅ 테스트 이미지: {test_image}")
        
        # API 테스트
        url = "http://localhost:3000/api/meals/analyze-image"
        
        with open(test_image, 'rb') as f:
            files = {'file': f}
            data = {
                'member_id': '1',
                'meal_type': 'SNACK'
            }
            
            print(f"\n📤 API 요청: {url}")
            print(f"   member_id: 1")
            print(f"   meal_type: SNACK")
            
            try:
                response = requests.post(url, files=files, data=data)
                
                print(f"\n📥 응답:")
                print(f"   Status Code: {response.status_code}")
                print(f"   Response Body:")
                if response.status_code == 200:
                    import json
                    print(json.dumps(response.json(), indent=2, ensure_ascii=False))
                else:
                    print(response.text)
                    
            except Exception as e:
                print(f"❌ 요청 오류: {e}")
