"""
Nutrition Analyzer 전체 테스트 스크립트
YOLO 모듈 동적 로딩 및 기능 검증
"""
import sys
from pathlib import Path

# 백엔드 경로 추가
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

print("="*80)
print("🧪 Nutrition Analyzer 테스트 시작")
print("="*80)

# 1. YOLO 모듈 동적 임포트 테스트
print("\n[1] YOLO 모듈 동적 임포트 테스트")
from services.nutrition_analyzer import _import_yolo_modules

success = _import_yolo_modules()
if success:
    print("   ✅ YOLO 모듈 동적 로딩 성공!")
else:
    print("   ❌ YOLO 모듈 로딩 실패")
    sys.exit(1)

# 2. YOLO 모델 로드 테스트
print("\n[2] YOLO 모델 로드 테스트")
try:
    from services.nutrition_analyzer import load_yolo_model
    yolo_model, device = load_yolo_model()
    if yolo_model is not None:
        print(f"   ✅ YOLO 모델 로드 성공! (Device: {device})")
    else:
        print("   ❌ YOLO 모델 로드 실패")
except Exception as e:
    print(f"   ❌ YOLO 모델 로드 오류: {e}")

# 3. ResNet 모델 로드 테스트
print("\n[3] ResNet 모델 로드 테스트")
try:
    from services.nutrition_analyzer import load_resnet_model
    resnet_model, device = load_resnet_model()
    if resnet_model is not None:
        print(f"   ✅ ResNet 모델 로드 성공! (Device: {device})")
    else:
        print("   ❌ ResNet 모델 로드 실패")
except Exception as e:
    print(f"   ❌ ResNet 모델 로드 오류: {e}")

# 4. 영양 DB 로드 테스트
print("\n[4] 영양 DB 로드 테스트")
try:
    from services.nutrition_analyzer import load_nutrition_db
    db = load_nutrition_db()
    if db is not None and len(db) > 0:
        print(f"   ✅ 영양 DB 로드 성공! ({len(db)}개 음식)")
        print(f"   📋 컬럼: {list(db.columns)[:5]}...")
    else:
        print("   ❌ 영양 DB 로드 실패")
except Exception as e:
    print(f"   ❌ 영양 DB 로드 오류: {e}")

# 5. 영양 정보 조회 테스트
print("\n[5] 영양 정보 조회 테스트 (쌀밥)")
try:
    from services.nutrition_analyzer import get_nutrition_facts
    nutrition = get_nutrition_facts("쌀밥", 1.0)
    if nutrition:
        print(f"   ✅ 영양 정보 조회 성공!")
        print(f"      음식명: {nutrition['food_name']}")
        print(f"      칼로리: {nutrition['calories_kcal']} kcal")
        print(f"      탄수화물: {nutrition['carbohydrates_g']} g")
        print(f"      단백질: {nutrition['protein_g']} g")
        print(f"      지방: {nutrition['fat_g']} g")
    else:
        print("   ❌ 영양 정보 조회 실패")
except Exception as e:
    print(f"   ❌ 영양 정보 조회 오류: {e}")

print("\n" + "="*80)
print("✅ 모든 테스트 완료!")
print("="*80)
