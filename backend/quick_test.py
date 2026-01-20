import sys
sys.path.insert(0, r'C:\Users\smhrd\Desktop\App\ttm\backend')

from services.nutrition_analyzer import get_nutrition_info_from_image

image_path = r'C:\Users\smhrd\Desktop\App\ttm\backend\uploads\meals\test_meal.jpg'

print("="*80)
print("🍚 흑미밥 이미지 AI 분석")
print("="*80)

results = get_nutrition_info_from_image(image_path)

if results:
    print(f"\n✅ {len(results)}개 음식 탐지 성공!\n")
    for i, r in enumerate(results, 1):
        print(f"음식 {i}: {r['food_name']}")
        print(f"  칼로리: {r['calories_kcal']:.1f} kcal")
        print(f"  탄수화물: {r['carbohydrates_g']:.1f} g")
        print(f"  단백질: {r['protein_g']:.1f} g")
        print(f"  지방: {r['fat_g']:.1f} g")
        print(f"  양: {r['quantity_category']} (x{r['quantity_multiplier']})")
        print(f"  신뢰도: {r['confidence']:.1%}\n")
else:
    print("\n⚠️ 음식을 탐지하지 못했습니다.")
