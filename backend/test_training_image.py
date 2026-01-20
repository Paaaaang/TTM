import sys
from pathlib import Path

sys.path.insert(0, r'C:\Users\smhrd\Desktop\App\ttm\backend')

from services.nutrition_analyzer import get_nutrition_info_from_image

image_path = r'C:\Users\smhrd\Desktop\App\ttm\backend\uploads\meals\test_meal2.png'

print("="*80)
print("AI 음식 탐지 테스트 - 학습 데이터 이미지")
print("="*80)
print(f"이미지: {Path(image_path).name}")
print(f"크기: {Path(image_path).stat().st_size:,} bytes")
print("="*80)

results = get_nutrition_info_from_image(image_path)

print("\n" + "="*80)
print("분석 결과")
print("="*80)

if results:
    print(f"\n탐지 성공! {len(results)}개 음식\n")
    
    for i, food in enumerate(results, 1):
        print(f"[{i}] {food['food_name']}")
        print(f"    칼로리: {food['calories_kcal']:.1f} kcal")
        print(f"    탄수화물: {food['carbohydrates_g']:.1f} g")
        print(f"    단백질: {food['protein_g']:.1f} g")
        print(f"    지방: {food['fat_g']:.1f} g")
        print(f"    당류: {food['sugars_g']:.1f} g")
        print(f"    나트륨: {food['sodium_mg']:.0f} mg")
        print(f"    양: {food['quantity_category']} (x{food['quantity_multiplier']})")
        print(f"    신뢰도: {food['confidence']:.1%}")
        print()
else:
    print("\n음식을 탐지하지 못했습니다.")
    print("YOLO 모델이 해당 이미지에서 음식을 인식하지 못했습니다.")

print("="*80)
