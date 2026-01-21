"""
통합 AI 영양 분석 모듈
YOLO (음식 분류) + ResNet (양 추정) + 영양 DB 조회
"""
import os
import sys
import json
from typing import List, Dict, Optional
from pathlib import Path
import torch
import torch.nn as nn
import torchvision.transforms as transforms
from PIL import Image
import pandas as pd
import numpy as np
import cv2

# ==================== 경로 설정 ====================
# 중앙화된 경로 설정 사용
from config.model_paths import (
    YOLO_WEIGHTS,
    RESNET_WEIGHTS,
    NUTRITION_DB_PATH,
    FOOD_CODE_MAP_PATH
)

BASE_DIR = Path(__file__).resolve().parent.parent
AI_MODELS_DIR = BASE_DIR / "ai_models"
YOLO_UTILS_DIR = BASE_DIR / "yolo_utils"

# 실제 모델 경로 선택 (yolo_utils > ai_models)
MODEL_BASE_DIR = YOLO_UTILS_DIR if YOLO_UTILS_DIR.exists() else AI_MODELS_DIR

# YOLO 관련 경로 (설정/이름 파일은 로컬에만 존재)
YOLO_DIR = MODEL_BASE_DIR / "Food_classification" / "yolov3"
YOLO_CFG = YOLO_DIR / "cfg" / "yolov3-spp-403cls.cfg"
YOLO_NAMES = YOLO_DIR / "data" / "403food.names"

print("="*80)
print("🚀 Nutrition Analyzer 모듈 초기화")
print("="*80)
print(f"📍 YOLO 설정: {YOLO_CFG}")
print(f"📍 YOLO 가중치: {YOLO_WEIGHTS}")
print(f"📍 YOLO 클래스: {YOLO_NAMES}")
print(f"📍 ResNet 가중치: {RESNET_WEIGHTS}")
print(f"📍 영양 DB: {NUTRITION_DB_PATH}")
print("="*80)

# ==================== 전역 변수 ====================
QUANTITY_MAP = {
    'Q1': 0.5,   # 매우 적음
    'Q2': 0.75,  # 적음
    'Q3': 1.0,   # 보통
    'Q4': 1.25,  # 많음
    'Q5': 1.5    # 매우 많음
}

# 영양 DB 전역 로드
NUTRITION_DB = None
FOOD_CODE_MAP = None

def load_nutrition_db():
    """영양 DB 로드 (싱글톤 패턴)"""
    global NUTRITION_DB
    if NUTRITION_DB is None:
        try:
            print("\n📊 영양 DB 로드 중...")
            NUTRITION_DB = pd.read_excel(str(NUTRITION_DB_PATH))
            print(f"✅ 영양 DB 로드 완료: {len(NUTRITION_DB)}개 음식")
            print(f"   컬럼: {list(NUTRITION_DB.columns)}")
        except Exception as e:
            print(f"❌ 영양 DB 로드 실패: {e}")
            NUTRITION_DB = pd.DataFrame()
    return NUTRITION_DB


def load_food_code_map():
    """음식 코드 -> 한글명 매핑 로드 (싱글톤)"""
    global FOOD_CODE_MAP
    if FOOD_CODE_MAP is None:
        try:
            if FOOD_CODE_MAP_PATH.exists():
                with open(FOOD_CODE_MAP_PATH, 'r', encoding='utf-8') as f:
                    FOOD_CODE_MAP = json.load(f)
                print(f"✅ 음식 코드 매핑 로드 완료: {len(FOOD_CODE_MAP)}개")
            else:
                print(f"⚠️ 음식 코드 매핑 파일 없음: {FOOD_CODE_MAP_PATH}")
                FOOD_CODE_MAP = {}
        except Exception as e:
            print(f"❌ 음식 코드 매핑 로드 실패: {e}")
            FOOD_CODE_MAP = {}
    return FOOD_CODE_MAP


# ==================== YOLO 모델 로드 ====================
# ==================== YOLO 모듈 임포트 (동적 로딩) ====================
# 전역 변수로 선언
YOLO_AVAILABLE = False
Darknet = None
LoadImages = None
non_max_suppression = None
scale_coords = None
load_classes = None
torch_utils = None

def _import_yolo_modules():
    """YOLO 모듈 동적 임포트"""
    global YOLO_AVAILABLE, Darknet, LoadImages, non_max_suppression, scale_coords, load_classes, torch_utils
    
    if YOLO_AVAILABLE:  # 이미 로드됨
        return True
    
    # YOLO 디렉토리를 sys.path 맨 앞에 추가 (우선순위 최상위)
    yolo_path = str(YOLO_DIR)
    if yolo_path in sys.path:
        sys.path.remove(yolo_path)
    sys.path.insert(0, yolo_path)
    
    print(f"\n🔧 YOLO 경로 설정: {yolo_path}")
    print(f"📂 sys.path[0]: {sys.path[0]}")
    print(f"📁 utils 디렉토리 존재: {(YOLO_DIR / 'utils').exists()}")
    print(f"📄 datasets.py 존재: {(YOLO_DIR / 'utils' / 'datasets.py').exists()}")
    
    try:
        # 동적 임포트
        import importlib
        import importlib.util
        
        # utils 패키지를 Python 패키지로 등록 (중요!)
        utils_path = YOLO_DIR / "utils"
        if str(utils_path) not in sys.modules:
            utils_spec = importlib.util.spec_from_file_location(
                "utils",
                utils_path / "__init__.py",
                submodule_search_locations=[str(utils_path)]
            )
            utils_package = importlib.util.module_from_spec(utils_spec)
            sys.modules['utils'] = utils_package
            utils_spec.loader.exec_module(utils_package)
        
        # utils 서브모듈들 직접 로드
        datasets_spec = importlib.util.spec_from_file_location("utils.datasets", utils_path / "datasets.py")
        datasets_module = importlib.util.module_from_spec(datasets_spec)
        sys.modules['utils.datasets'] = datasets_module
        datasets_spec.loader.exec_module(datasets_module)
        LoadImages = datasets_module.LoadImages
        
        utils_spec = importlib.util.spec_from_file_location("utils.utils", utils_path / "utils.py")
        utils_module = importlib.util.module_from_spec(utils_spec)
        sys.modules['utils.utils'] = utils_module
        utils_spec.loader.exec_module(utils_module)
        non_max_suppression = utils_module.non_max_suppression
        scale_coords = utils_module.scale_coords
        load_classes = utils_module.load_classes
        
        torch_utils_spec = importlib.util.spec_from_file_location("utils.torch_utils", utils_path / "torch_utils.py")
        torch_utils_module = importlib.util.module_from_spec(torch_utils_spec)
        sys.modules['utils.torch_utils'] = torch_utils_module
        torch_utils_spec.loader.exec_module(torch_utils_module)
        torch_utils = torch_utils_module
        
        print("✅ utils 패키지 및 서브모듈 로드 완료")
        
        # 이제 models.py 파일 로드 (utils가 이미 로드됨)
        models_path = YOLO_DIR / "models.py"
        spec = importlib.util.spec_from_file_location("yolo_models", models_path)
        models_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(models_module)
        Darknet = models_module.Darknet
        
        print(f"✅ models.py 로드 성공: {models_path}")
        print(f"   Darknet 클래스: {Darknet}")
        
        YOLO_AVAILABLE = True
        print("✅ YOLO 모듈 전체 임포트 성공")
        return True
        
    except Exception as e:
        print(f"⚠️ YOLO 모듈 임포트 실패: {e}")
        import traceback
        traceback.print_exc()
        return False


# ==================== YOLO 모델 로드 ====================


# ==================== ResNet 모델 정의 ====================
class QuantityResNet(nn.Module):
    """음식 양 추정을 위한 ResNet 모델"""
    
    def __init__(self, num_classes=5):
        super(QuantityResNet, self).__init__()
        # ResNet-18 기본 구조
        self.conv1 = nn.Conv2d(3, 64, kernel_size=7, stride=2, padding=3)
        self.bn1 = nn.BatchNorm2d(64)
        self.relu = nn.ReLU(inplace=True)
        self.maxpool = nn.MaxPool2d(kernel_size=3, stride=2, padding=1)
        
        # ResNet blocks (simplified)
        self.layer1 = self._make_layer(64, 64, 2)
        self.layer2 = self._make_layer(64, 128, 2, stride=2)
        self.layer3 = self._make_layer(128, 256, 2, stride=2)
        self.layer4 = self._make_layer(256, 512, 2, stride=2)
        
        self.avgpool = nn.AdaptiveAvgPool2d((1, 1))
        self.fc = nn.Linear(512, num_classes)
    
    def _make_layer(self, in_channels, out_channels, blocks, stride=1):
        layers = []
        layers.append(nn.Conv2d(in_channels, out_channels, 3, stride=stride, padding=1))
        layers.append(nn.BatchNorm2d(out_channels))
        layers.append(nn.ReLU(inplace=True))
        
        for _ in range(1, blocks):
            layers.append(nn.Conv2d(out_channels, out_channels, 3, padding=1))
            layers.append(nn.BatchNorm2d(out_channels))
            layers.append(nn.ReLU(inplace=True))
        
        return nn.Sequential(*layers)
    
    def forward(self, x):
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.maxpool(x)
        
        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)
        x = self.layer4(x)
        
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        x = self.fc(x)
        
        return x


# ==================== 전역 모델 인스턴스 ====================
_yolo_model = None
_resnet_model = None
_resnet_device = None
_class_names = None


def load_yolo_model():
    """
    YOLO 모델 로드 (Lazy Loading)
    
    주의: services.model_loader를 사용하여 메모리 최적화
          첫 요청 시에만 torch.load 실행
    """
    global _yolo_model, _class_names
    
    # 이미 로드되었으면 캐시 반환
    if _yolo_model is not None:
        return _yolo_model, _class_names
    
    # YOLO 모듈 동적 임포트
    if not _import_yolo_modules():
        print("❌ YOLO 모듈을 사용할 수 없습니다")
        return None, None
    
    try:
        print("\n📦 YOLO 모델 Lazy Loading...")
        
        # 설정 파일 확인
        if not YOLO_CFG.exists():
            print(f"❌ YOLO 설정 파일 없음: {YOLO_CFG}")
            return None, None
        
        if not YOLO_WEIGHTS.exists():
            print(f"❌ YOLO 가중치 파일 없음: {YOLO_WEIGHTS}")
            print(f"   경로: {YOLO_WEIGHTS}")
            print(f"   Render Persistent Disk 마운트 확인 필요")
            return None, None
        
        # 모델 초기화
        device = torch_utils.select_device('cpu') if torch_utils else torch.device('cpu')
        img_size = 416
        
        _yolo_model = Darknet(str(YOLO_CFG), img_size)
        
        # 가중치 로드 (strict=False로 불필요한 키 무시)
        if str(YOLO_WEIGHTS).endswith('.pt'):
            checkpoint = torch.load(str(YOLO_WEIGHTS), map_location=device, weights_only=False)
            if isinstance(checkpoint, dict) and 'model' in checkpoint:
                _yolo_model.load_state_dict(checkpoint['model'], strict=False)
            else:
                _yolo_model.load_state_dict(checkpoint, strict=False)
        
        _yolo_model.to(device).eval()
        
        # 클래스 이름 로드
        if YOLO_NAMES.exists():
            _class_names = load_classes(str(YOLO_NAMES))
            print(f"✅ 클래스 로드: {len(_class_names)}개")
        else:
            print(f"⚠️ 클래스 파일 없음: {YOLO_NAMES}")
            _class_names = []
        
        print("✅ YOLO 모델 로드 완료")
        return _yolo_model, _class_names
        
    except Exception as e:
        print(f"❌ YOLO 모델 로드 실패: {e}")
        import traceback
        traceback.print_exc()
        return None, None


def load_resnet_model():
    """
    ResNet 모델 로드 (Lazy Loading)
    
    주의: 메모리 최적화를 위해 첫 요청 시에만 torch.load
    """
    global _resnet_model, _resnet_device
    
    if _resnet_model is not None:
        if _resnet_device is None:
            _resnet_device = torch.device('cpu')
        return _resnet_model, _resnet_device
    
    try:
        print("\n📦 ResNet 모델 Lazy Loading...")
        
        if not RESNET_WEIGHTS.exists():
            print(f"❌ ResNet 가중치 파일 없음: {RESNET_WEIGHTS}")
            print(f"   경로: {RESNET_WEIGHTS}")
            print(f"   Render Persistent Disk 마운트 확인 필요")
            return None, None
        
        device = torch.device('cpu')
        
        # 체크포인트 로드 (weights_only=False for compatibility)
        checkpoint = torch.load(str(RESNET_WEIGHTS), map_location=device, weights_only=False)
        
        # checkpoint 구조 확인 및 모델 추출
        if isinstance(checkpoint, dict):
            if 'model_ft' in checkpoint:
                # 전체 모델이 저장된 경우
                _resnet_model = checkpoint['model_ft']
                if 'state_dict' in checkpoint:
                    _resnet_model.load_state_dict(checkpoint['state_dict'], strict=False)
            elif 'model_state_dict' in checkpoint:
                _resnet_model = QuantityResNet(num_classes=5)
                _resnet_model.load_state_dict(checkpoint['model_state_dict'])
            elif 'state_dict' in checkpoint:
                _resnet_model = QuantityResNet(num_classes=5)
                _resnet_model.load_state_dict(checkpoint['state_dict'])
            else:
                # state_dict만 있는 경우
                _resnet_model = QuantityResNet(num_classes=5)
                _resnet_model.load_state_dict(checkpoint)
        else:
            # 전체 모델이 직접 저장된 경우
            _resnet_model = checkpoint
        
        # 평가 모드로 설정
        _resnet_model.to(device).eval()
        _resnet_device = device
        
        # gradient 계산 비활성화
        for param in _resnet_model.parameters():
            param.requires_grad = False
        
        print("✅ ResNet 모델 로드 완료")
        return _resnet_model, device
        
    except Exception as e:
        print(f"❌ ResNet 모델 로드 실패: {e}")
        import traceback
        traceback.print_exc()
        return None, None
        import traceback
        traceback.print_exc()
        return None, None


# ==================== 핵심 함수들 ====================

def get_nutrition_facts(food_name: str, quantity_multiplier: float) -> Dict:
    """
    영양 DB에서 음식 정보 조회 및 양에 따른 계산
    
    Args:
        food_name: 음식명
        quantity_multiplier: 양 배수 (0.5 ~ 1.5)
    
    Returns:
        영양 정보 딕셔너리
    """
    db = load_nutrition_db()
    
    if db is None or db.empty:
        return {
            'food_name': food_name,
            'calories_kcal': 0,
            'carbohydrates_g': 0,
            'protein_g': 0,
            'fat_g': 0,
            'sugar_g': 0,
            'sodium_mg': 0
        }
    
    # 음식명으로 검색 (컬럼명에 공백 포함)
    result = db[db['음 식 명'] == food_name]
    
    if result.empty:
        print(f"⚠️ 영양 DB에 '{food_name}' 정보 없음")
        return {
            'food_name': food_name,
            'calories_kcal': 0,
            'carbohydrates_g': 0,
            'protein_g': 0,
            'fat_g': 0,
            'sugar_g': 0,
            'sodium_mg': 0
        }
    
    # 첫 번째 매칭 결과 사용
    row = result.iloc[0]
    
    # meal_item 테이블 스키마에 맞는 키 이름 사용
    return {
        'food_name': food_name,
        'calories_kcal': float(row.get('에너지(kcal)', 0)) * quantity_multiplier,
        'carbohydrates_g': float(row.get('탄수화물(g)', 0)) * quantity_multiplier,
        'protein_g': float(row.get('단백질(g)', 0)) * quantity_multiplier,
        'fat_g': float(row.get('지방(g)', 0)) * quantity_multiplier,
        'sugar_g': float(row.get('당류(g)', 0)) * quantity_multiplier,
        'sodium_mg': float(row.get('나트륨(mg)', 0)) * quantity_multiplier
    }


def classify_food(image_path: str) -> List[Dict]:
    """
    YOLO로 음식 탐지 및 분류
    
    Args:
        image_path: 이미지 경로
    
    Returns:
        [{food_name, bbox, confidence}, ...]
    """
    # YOLO 모듈 동적 임포트
    if not _import_yolo_modules():
        print("⚠️ YOLO 모듈 사용 불가 - Mock 데이터 반환")
        # Mock 데이터 반환
        img = Image.open(image_path)
        width, height = img.size
        return [{
            'food_name': '밥',
            'bbox': [0, 0, width, height],
            'confidence': 0.5
        }]
    
    model, class_names = load_yolo_model()
    
    if model is None or not class_names:
        print("⚠️ YOLO 모델 사용 불가 - Mock 데이터 반환")
        # Mock 데이터 반환
        img = Image.open(image_path)
        width, height = img.size
        return [{
            'food_name': '밥',
            'bbox': [0, 0, width, height],
            'confidence': 0.5
        }]
    
    try:
        device = torch.device('cpu')
        img_size = 416
        conf_thres = 0.01  # 신뢰도 임계값을 매우 낮춤 (1%)
        iou_thres = 0.5
        
        print(f"📸 이미지 파일: {image_path}")
        print(f"📂 파일 존재: {Path(image_path).exists()}")
        
        # 이미지 로드
        img0 = cv2.imread(image_path)
        if img0 is None:
            print(f"❌ 이미지 로드 실패: {image_path}")
            return []
        
        print(f"📐 원본 이미지 크기: {img0.shape}")
        
        img = cv2.resize(img0, (img_size, img_size))
        img = img[:, :, ::-1].transpose(2, 0, 1)  # BGR to RGB, to 3xHxW
        img = np.ascontiguousarray(img)
        img = torch.from_numpy(img).to(device)
        img = img.float() / 255.0
        if img.ndimension() == 3:
            img = img.unsqueeze(0)
        
        print(f"🔍 YOLO 추론 시작...")
        
        # 추론
        with torch.no_grad():
            pred = model(img)[0]
        
        print(f"🎯 추론 결과 shape: {pred.shape}")
        print(f"📊 최대 신뢰도: {pred[..., 4].max():.6f}")
        print(f"📊 평균 신뢰도: {pred[..., 4].mean():.6f}")
        print(f"📊 신뢰도 > 0.01: {(pred[..., 4] > 0.01).sum()}")
        
        # NMS 적용
        pred = non_max_suppression(pred, conf_thres, iou_thres)
        
        detections = []
        
        # 결과 처리
        for i, det in enumerate(pred):
            print(f"🔎 Detection {i}: {det.shape if det is not None else 'None'}")
            if det is not None and len(det):
                print(f"   탐지된 객체 수: {len(det)}")
                # 좌표 스케일 조정
                det[:, :4] = scale_coords(img.shape[2:], det[:, :4], img0.shape).round()
                
                for *xyxy, conf, cls in det:
                    x1, y1, x2, y2 = map(int, xyxy)
                    class_idx = int(cls)
                    
                    print(f"   -> 클래스 인덱스: {class_idx}, 신뢰도: {conf:.2f}")
                    
                    if class_idx < len(class_names):
                        raw_name = class_names[class_idx]
                        code_map = load_food_code_map()
                        mapped_name = code_map.get(raw_name)
                        if mapped_name:
                            food_name = mapped_name
                        elif raw_name.isdigit():
                            food_name = "알 수 없음"
                        else:
                            food_name = raw_name
                        print(f"   -> 음식명: {food_name}")
                        detections.append({
                            'food_name': food_name,
                            'bbox': [x1, y1, x2, y2],
                            'confidence': float(conf)
                        })
            else:
                print(f"   탐지된 객체 없음")
        
        print(f"✅ YOLO 탐지 완료: {len(detections)}개 음식")
        return detections
        
    except Exception as e:
        print(f"❌ YOLO 탐지 오류: {e}")
        import traceback
        traceback.print_exc()
        return []


def estimate_quantity(image: Image.Image) -> Dict:
    """
    ResNet으로 음식 양 추정
    
    Args:
        image: PIL Image 객체
    
    Returns:
        {quantity_category: 'Q3', probability: 0.85}
    """
    model_result = load_resnet_model()
    
    if model_result is None:
        print("⚠️ ResNet 모델 사용 불가 - 기본값 Q3 반환")
        return {'quantity_category': 'Q3', 'probability': 1.0}
    
    model, device = model_result  # 튜플 언패킹
    if model is None:
        print("⚠️ ResNet 모델 사용 불가 - 기본값 Q3 반환")
        return {'quantity_category': 'Q3', 'probability': 1.0}
    
    try:
        
        # 이미지 전처리
        transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                               std=[0.229, 0.224, 0.225])
        ])
        
        img_tensor = transform(image).unsqueeze(0).to(device)
        
        # 추론
        with torch.no_grad():
            outputs = model(img_tensor)
            probabilities = torch.nn.functional.softmax(outputs, dim=1)
            max_prob, predicted = torch.max(probabilities, 1)
        
        quantity_classes = ['Q1', 'Q2', 'Q3', 'Q4', 'Q5']
        predicted_class = quantity_classes[predicted.item()]
        probability = max_prob.item()
        
        return {
            'quantity_category': predicted_class,
            'probability': probability
        }
        
    except Exception as e:
        print(f"❌ ResNet 양 추정 오류: {e}")
        return {'quantity_category': 'Q3', 'probability': 0.5}


def get_nutrition_info_from_image(image_path: str) -> List[Dict]:
    """
    메인 함수: 이미지에서 영양 정보 추출
    
    Args:
        image_path: 분석할 이미지 경로
    
    Returns:
        [{
            food_name: "쌀밥",
            calories_kcal: 374.4,
            carbohydrates_g: 82.08,
            protein_g: 7.2,
            fat_g: 1.44,
            sugars_g: 0.0,
            sodium_mg: 0.6,
            quantity_category: "Q4",
            quantity_multiplier: 1.25,
            confidence: 0.88
        }, ...]
    """
    print(f"\n{'='*80}")
    print(f"🍽️ 영양 분석 시작: {image_path}")
    print(f"{'='*80}")
    
    # Step 1: YOLO로 음식 분류
    food_detections = classify_food(image_path)
    
    if not food_detections:
        print("⚠️ 탐지된 음식 없음")
        return []
    
    # 신뢰도 기준 정렬 (알 수 없음은 뒤로)
    food_detections = sorted(
        food_detections,
        key=lambda f: (
            f.get('food_name') == '알 수 없음',
            -float(f.get('confidence', 0.0))
        )
    )

    # Step 2: 원본 이미지 로드
    original_image = Image.open(image_path)
    
    # Step 3: 각 탐지된 음식 처리
    final_results = []
    
    for idx, food in enumerate(food_detections):
        print(f"\n--- 음식 {idx + 1}/{len(food_detections)} ---")
        print(f"  음식명: {food['food_name']}")
        print(f"  신뢰도: {food['confidence']:.2f}")
        
        # 이미지 크롭
        bbox = food['bbox']
        cropped_image = original_image.crop(bbox)
        
        # ResNet으로 양 추정
        quantity_result = estimate_quantity(cropped_image)
        quantity_category = quantity_result['quantity_category']
        quantity_prob = quantity_result['probability']
        
        print(f"  양 추정: {quantity_category} (확률: {quantity_prob:.2f})")
        
        # 양 배수 가져오기
        quantity_multiplier = QUANTITY_MAP.get(quantity_category, 1.0)
        
        # 영양 정보 조회
        nutrition = get_nutrition_facts(food['food_name'], quantity_multiplier)
        
        # 최종 결과 조합
        result = {
            'food_name': nutrition['food_name'],
            'calories_kcal': round(nutrition['calories_kcal'], 2),
            'carbohydrates_g': round(nutrition['carbohydrates_g'], 2),
            'protein_g': round(nutrition['protein_g'], 2),
            'fat_g': round(nutrition['fat_g'], 2),
            'sugars_g': round(nutrition['sugar_g'], 2),
            'sodium_mg': round(nutrition['sodium_mg'], 2),
            'quantity_category': quantity_category,
            'quantity_multiplier': quantity_multiplier,
            'confidence': food['confidence']
        }
        
        final_results.append(result)
        
        print(f"  ✅ {result['food_name']}: {result['calories_kcal']} kcal")
    
    print(f"\n{'='*80}")
    print(f"✅ 분석 완료: 총 {len(final_results)}개 음식")
    print(f"{'='*80}")
    
    return final_results


# ==================== 테스트 코드 ====================
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='음식 이미지 영양 분석')
    parser.add_argument('--image', type=str, required=True, help='분석할 이미지 경로')
    parser.add_argument('--output', type=str, help='결과 저장 경로 (JSON)')
    
    args = parser.parse_args()
    
    # 분석 실행
    results = get_nutrition_info_from_image(args.image)
    
    # 결과 출력
    print("\n" + "="*80)
    print("📊 최종 영양 분석 결과")
    print("="*80)
    print(json.dumps(results, ensure_ascii=False, indent=2))
    
    # 파일로 저장 (옵션)
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
        print(f"\n💾 결과 저장 완료: {args.output}")
