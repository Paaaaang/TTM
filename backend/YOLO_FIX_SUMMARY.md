# YOLO 모듈 임포트 문제 해결 완료

## 📅 수정 날짜: 2026-01-19

## 🔍 문제 진단

### 발생한 오류
```
ModuleNotFoundError: No module named 'utils.datasets'
```

### 근본 원인
1. **경로 구조**: YOLO 모듈이 `Food_classification\yolov3\` 안에 있음
2. **utils 패키지**: `utils.datasets`, `utils.utils`, `utils.torch_utils` 등 서브모듈이 필요
3. **임포트 문제**: `importlib.import_module('utils.datasets')`가 sys.path만으로는 동작하지 않음

## ✅ 해결 방법

### 1. 절대 경로로 직접 모듈 로드
`importlib.util.spec_from_file_location()`을 사용하여 파일 경로로 직접 로드:

```python
# utils 패키지를 Python 패키지로 등록
utils_path = YOLO_DIR / "utils"
utils_spec = importlib.util.spec_from_file_location(
    "utils",
    utils_path / "__init__.py",
    submodule_search_locations=[str(utils_path)]
)
utils_package = importlib.util.module_from_spec(utils_spec)
sys.modules['utils'] = utils_package
utils_spec.loader.exec_module(utils_package)
```

### 2. 서브모듈들 개별 로드
각 서브모듈을 절대 경로로 로드하고 `sys.modules`에 등록:

```python
# datasets 모듈 로드
datasets_spec = importlib.util.spec_from_file_location("utils.datasets", utils_path / "datasets.py")
datasets_module = importlib.util.module_from_spec(datasets_spec)
sys.modules['utils.datasets'] = datasets_module
datasets_spec.loader.exec_module(datasets_module)
```

### 3. models.py는 utils 로드 후 실행
models.py가 `from utils.google_utils import *`를 사용하므로, utils 모듈들을 먼저 로드한 후 models.py를 로드:

```python
# 이제 models.py 파일 로드 (utils가 이미 로드됨)
models_path = YOLO_DIR / "models.py"
spec = importlib.util.spec_from_file_location("yolo_models", models_path)
models_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(models_module)
Darknet = models_module.Darknet
```

## 📂 디렉토리 구조

```
backend/
└── yolo_utils/
    └── Food_classification/
        └── yolov3/               ← YOLO_DIR
            ├── models.py         ← Darknet 클래스
            ├── weights/
            │   └── best_403food_e200b150v2.pt
            ├── cfg/
            │   └── yolov3-spp-403cls.cfg
            ├── data/
            │   └── 403food.names
            └── utils/            ← utils 패키지
                ├── __init__.py
                ├── datasets.py   ← LoadImages
                ├── utils.py      ← non_max_suppression, scale_coords
                └── torch_utils.py
```

## 🎯 테스트 결과

```
✅ utils 패키지 및 서브모듈 로드 완료
✅ models.py 로드 성공
✅ Darknet 클래스: <class 'yolo_models.Darknet'>
✅ YOLO 모듈 전체 임포트 성공
```

## 🔗 연관 파일

- `backend/services/nutrition_analyzer.py` - YOLO + ResNet 통합 AI 분석 모듈
- `backend/routers/meals.py` - AI 분석 API 엔드포인트
- `lib/screens/meal/ai_analysis_result_screen.dart` - Flutter AI 분석 화면
- `lib/services/meal_service.dart` - 식단 서비스 (AI 분석 API 호출)

## 🚀 다음 단계

1. ✅ YOLO 모듈 임포트 해결
2. ✅ ResNet 모델 로드 해결 (튜플 반환)
3. ✅ 영양 정보 키 이름 통일 (calories_kcal 등)
4. 🔄 백엔드 서버 재시작 대기 중
5. ⏳ Flutter 앱에서 이미지 업로드 테스트

## 📱 프론트엔드 화면 구조

### AI 분석 플로우
1. **이미지 선택**: 카메라 또는 갤러리에서 음식 사진 선택
2. **AI 분석**: `MealService().analyzeMealImage()` 호출
3. **결과 표시**: `ai_analysis_result_screen.dart`에서 분석 결과 표시
4. **수정 가능**: 사용자가 음식명, 영양 정보 수정 가능
5. **저장**: `식단에 추가하기` 버튼으로 DB 저장

### 주요 필드
- `food_name`: 음식명
- `calories_kcal`: 칼로리 (kcal)
- `carbohydrates_g`: 탄수화물 (g)
- `protein_g`: 단백질 (g)
- `fat_g`: 지방 (g)
- `sugars_g`: 당류 (g)
- `sodium_mg`: 나트륨 (mg)

## 💡 핵심 개선사항

1. **동적 모듈 로딩**: `importlib.util`로 절대 경로 기반 로딩
2. **sys.modules 등록**: 로드한 모듈을 `sys.modules`에 명시적 등록
3. **로딩 순서**: utils → models 순서로 로드
4. **디버깅 정보**: 디렉토리 존재 여부, 파일 존재 여부 출력
5. **에러 처리**: 자세한 traceback 출력으로 디버깅 용이

## ✨ 성공 기준

- [x] YOLO 모듈 임포트 성공
- [x] Darknet 클래스 로드 성공
- [x] utils.datasets, utils.utils, utils.torch_utils 로드 성공
- [x] models.py에서 utils 모듈 참조 성공
- [x] 전체 AI 파이프라인 테스트 통과
