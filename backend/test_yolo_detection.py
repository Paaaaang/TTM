"""
YOLO 음식 탐지 직접 테스트
"""
import sys
from pathlib import Path

# 백엔드 경로 추가
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

print("="*80)
print("🧪 YOLO 음식 탐지 테스트")
print("="*80)

# 1. YOLO 모듈 동적 임포트 테스트
print("\n[1] YOLO 모듈 로딩...")
from services.nutrition_analyzer import _import_yolo_modules, classify_food

success = _import_yolo_modules()
if not success:
    print("❌ YOLO 모듈 로딩 실패")
    sys.exit(1)

print("✅ YOLO 모듈 로딩 성공")

# 2. 테스트 이미지 생성 (간단한 흰색 사각형)
print("\n[2] 테스트 이미지 생성...")
from PIL import Image, ImageDraw, ImageFont
import numpy as np

# 640x480 이미지 생성
img = Image.new('RGB', (640, 480), color=(255, 255, 255))
draw = ImageDraw.Draw(img)

# 중앙에 빨간 원 그리기 (음식처럼 보이도록)
draw.ellipse([200, 140, 440, 340], fill=(200, 100, 50), outline=(100, 50, 25))

# 텍스트 추가
draw.text((270, 220), "밥", fill=(255, 255, 255))

# 저장
test_image_path = backend_path / "test_food_image.jpg"
img.save(test_image_path)
print(f"✅ 테스트 이미지 생성: {test_image_path}")

# 3. YOLO 탐지 테스트
print("\n[3] YOLO 음식 탐지 시작...")
detections = classify_food(str(test_image_path))

print(f"\n{'='*80}")
if detections:
    print(f"✅ 탐지 성공! {len(detections)}개 음식 발견")
    for i, det in enumerate(detections):
        print(f"\n  음식 {i+1}:")
        print(f"    이름: {det['food_name']}")
        print(f"    신뢰도: {det['confidence']:.2%}")
        print(f"    위치: {det['bbox']}")
else:
    print("⚠️ 탐지된 음식 없음")
    print("\n가능한 원인:")
    print("  1. YOLO 모델이 Mock 데이터를 반환하는 경우")
    print("  2. 신뢰도 임계값(0.3) 이상의 탐지가 없는 경우")
    print("  3. 이미지 전처리 과정에서 문제 발생")

print(f"{'='*80}")

# 정리
test_image_path.unlink()
print(f"\n🗑️ 테스트 이미지 삭제 완료")
