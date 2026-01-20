"""
실제 흑미밥 이미지로 YOLO 탐지 테스트
"""
import sys
from pathlib import Path

# 백엔드 경로 추가
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

print("="*80)
print("🍚 흑미밥 이미지 AI 분석 테스트")
print("="*80)

# 이미지 경로
image_path = r"C:\Users\smhrd\Desktop\App\ttm\backend\uploads\meals\test_meal.jpg"

print(f"\n📸 테스트 이미지: {image_path}")
print(f"📂 파일 존재: {Path(image_path).exists()}")

if not Path(image_path).exists():
    print("❌ 이미지 파일을 찾을 수 없습니다!")
    sys.exit(1)

print(f"📏 파일 크기: {Path(image_path).stat().st_size} bytes")

# AI 분석 실행
print("\n" + "="*80)
print("🤖 AI 영양 분석 시작")
print("="*80)

from services.nutrition_analyzer import get_nutrition_info_from_image

results = get_nutrition_info_from_image(image_path)

print("\n" + "="*80)
print("📊 분석 결과")
print("="*80)

if results:
    print(f"✅ {len(results)}개 음식 탐지 성공!\n")
    
    for i, food in enumerate(results, 1):
        print(f"【음식 {i}】")
        print(f"  🍽️  음식명: {food['food_name']}")
        print(f"  🔥 칼로리: {food['calories_kcal']:.1f} kcal")
        print(f"  🍚 탄수화물: {food['carbohydrates_g']:.1f} g")
        print(f"  🥩 단백질: {food['protein_g']:.1f} g")
        print(f"  🧈 지방: {food['fat_g']:.1f} g")
        print(f"  🍬 당류: {food['sugars_g']:.1f} g")
        print(f"  🧂 나트륨: {food['sodium_mg']:.0f} mg")
        print(f"  📊 양: {food['quantity_category']} (x{food['quantity_multiplier']})")
        print(f"  ✨ 신뢰도: {food['confidence']:.1%}")
        print()
else:
    print("⚠️ 음식을 탐지하지 못했습니다.")
    print("\n가능한 원인:")
    print("  1. YOLO 모델이 해당 음식을 학습하지 않음")
    print("  2. 신뢰도 임계값보다 낮은 탐지")
    print("  3. 이미지 품질이나 각도 문제")

print("="*80)
