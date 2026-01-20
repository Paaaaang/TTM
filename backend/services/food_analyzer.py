"""
AI 기반 음식 분석 서비스
YOLO v3로 음식 탐지 → ResNet으로 양 추정 → 영양 DB 매칭
"""
import os
import sys
from typing import List, Dict, Optional, Tuple
import pandas as pd
from PIL import Image
import torch
import torch.nn as nn
import torchvision.transforms as transforms
import numpy as np
import cv2

# YOLO 모듈 임포트를 위한 경로 추가
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
YOLO_UTILS_DIR = os.path.join(BASE_DIR, "yolo_utils")
sys.path.insert(0, YOLO_UTILS_DIR)

# YOLO 관련 임포트
try:
    from models import models as yolo_models
    from utils import utils as yolo_utils
    from utils import datasets as yolo_datasets
    from utils import torch_utils as yolo_torch_utils
    
    Darknet = yolo_models.Darknet
    non_max_suppression = yolo_utils.non_max_suppression
    scale_coords = yolo_utils.scale_coords
    load_classes = yolo_utils.load_classes
    letterbox = yolo_datasets.letterbox
    select_device = yolo_torch_utils.select_device
    
    YOLO_AVAILABLE = True
except ImportError as e:
    print(f"⚠️ YOLO 모듈 임포트 실패: {e}")
    YOLO_AVAILABLE = False

# 경로 설정
YOLO_CFG = os.path.join(YOLO_UTILS_DIR, "cfg", "yolov3-spp-403cls.cfg")
YOLO_WEIGHTS = os.path.join(BASE_DIR, "ai_models", "yolo", "best_food_model.pt")
YOLO_NAMES = os.path.join(YOLO_UTILS_DIR, "data", "403food.names")
RESNET_WEIGHTS = os.path.join(BASE_DIR, "ai_models", "resnet", "quantity_model.pth")
NUTRITION_DB_PATH = os.path.join(BASE_DIR, "data", "nutrition_db.xlsx")

print("="*60)
print("🚀 FoodAnalyzer 모듈 초기화")
print("="*60)
print(f"📍 YOLO_CFG: {YOLO_CFG}")
print(f"📍 YOLO_WEIGHTS: {YOLO_WEIGHTS}")
print(f"📍 YOLO_NAMES: {YOLO_NAMES}")
print(f"📍 RESNET_WEIGHTS: {RESNET_WEIGHTS}")
print(f"📍 NUTRITION_DB: {NUTRITION_DB_PATH}")
print("="*60)


class FoodAnalyzer:
    """음식 이미지 분석 클래스"""
    
    def __init__(self):
        """모델 초기화"""
        print("\n🔧 FoodAnalyzer 초기화 시작...")
        
        # Device 설정
        if YOLO_AVAILABLE:
            self.device = select_device('cpu')
        else:
            self.device = torch.device('cpu')
        
        self.yolo_model = None
        self.resnet_model = None
        self.nutrition_db = None
        self.food_classes = []
        self.food_mapping = {}  # 음식 코드 -> 한글명
        
        # 1. YOLO 모델 로드
        self._load_yolo_model()
        
        # 2. ResNet 모델 로드
        self._load_resnet_model()
        
        # 3. 영양 DB 로드
        self._load_nutrition_db()
        
        print("\n✅ FoodAnalyzer 초기화 완료")
        print("="*60)
    
    def _load_yolo_model(self):
        """YOLO v3 모델 로드"""
        try:
            if not YOLO_AVAILABLE:
                print("❌ YOLO 모듈을 사용할 수 없습니다")
                return
            
            print("\n📦 YOLO 모델 로딩 중...")
            
            # 설정 파일 확인
            if not os.path.exists(YOLO_CFG):
                print(f"❌ YOLO 설정 파일 없음: {YOLO_CFG}")
                return
            
            # 가중치 파일 확인
            if not os.path.exists(YOLO_WEIGHTS):
                print(f"❌ YOLO 가중치 파일 없음: {YOLO_WEIGHTS}")
                return
            
            # 클래스 이름 로드
            if os.path.exists(YOLO_NAMES):
                self.food_classes = load_classes(YOLO_NAMES)
                print(f"✅ 음식 클래스 로드: {len(self.food_classes)}개")
            else:
                print(f"⚠️ 클래스 파일 없음: {YOLO_NAMES}")
            
            # Darknet 모델 생성
            img_size = 512
            self.yolo_model = Darknet(YOLO_CFG, img_size)
            print(f"✅ Darknet 모델 생성: {YOLO_CFG}")
            
            # 가중치 로드
            checkpoint = torch.load(YOLO_WEIGHTS, map_location=self.device)
            if isinstance(checkpoint, dict) and 'model' in checkpoint:
                self.yolo_model.load_state_dict(checkpoint['model'])
                print("✅ 가중치 로드 (dict['model'])")
            else:
                self.yolo_model.load_state_dict(checkpoint)
                print("✅ 가중치 로드 (state_dict)")
            
            # 평가 모드
            self.yolo_model.to(self.device).eval()
            print("✅ YOLO 모델 로드 완료")
            
        except Exception as e:
            print(f"❌ YOLO 모델 로드 실패: {e}")
            import traceback
            traceback.print_exc()
            self.yolo_model = None
    
    def _load_resnet_model(self):
        """ResNet 모델 로드"""
        try:
            print("\n📦 ResNet 모델 로딩 중...")
            
            if not os.path.exists(RESNET_WEIGHTS):
                print(f"❌ ResNet 가중치 파일 없음: {RESNET_WEIGHTS}")
                return
            
            # 체크포인트 로드 (PyTorch 2.6+에서 weights_only=False 필요)
            checkpoint = torch.load(RESNET_WEIGHTS, map_location='cpu', weights_only=False)
            
            if isinstance(checkpoint, dict) and 'model_ft' in checkpoint:
                # 전체 모델이 저장된 경우
                self.resnet_model = checkpoint['model_ft']
                print("✅ ResNet 모델 로드 (checkpoint['model_ft'])")
                
                # state_dict 추가 로드
                if 'state_dict' in checkpoint:
                    self.resnet_model.load_state_dict(checkpoint['state_dict'], strict=False)
                    print("✅ state_dict 추가 로드")
            else:
                print("⚠️ 예상치 못한 체크포인트 형식")
                print(f"체크포인트 키: {checkpoint.keys() if isinstance(checkpoint, dict) else type(checkpoint)}")
                return
            
            # 평가 모드
            self.resnet_model.eval()
            for param in self.resnet_model.parameters():
                param.requires_grad = False
            
            print("✅ ResNet 모델 로드 완료")
            
        except Exception as e:
            print(f"❌ ResNet 모델 로드 실패: {e}")
            import traceback
            traceback.print_exc()
            self.resnet_model = None
    
    def _load_nutrition_db(self):
        """영양 DB 로드"""
        try:
            print("\n📦 영양 DB 로딩 중...")
            
            if not os.path.exists(NUTRITION_DB_PATH):
                print(f"❌ 영양 DB 파일 없음: {NUTRITION_DB_PATH}")
                return
            
            self.nutrition_db = pd.read_excel(NUTRITION_DB_PATH)
            print(f"✅ 영양 DB 로드: {len(self.nutrition_db)}개 음식")
            print(f"컬럼: {list(self.nutrition_db.columns)}")
            
        except Exception as e:
            print(f"❌ 영양 DB 로드 실패: {e}")
            self.nutrition_db = None
    
    def detect_food_yolo(self, image_path: str, conf_thres: float = 0.3, iou_thres: float = 0.6) -> List[Dict]:
        """
        YOLO로 음식 탐지
        
        Returns:
            List[Dict]: [{"food_code": "01012001", "bbox": [x1,y1,x2,y2], "confidence": 0.88}, ...]
        """
        if self.yolo_model is None:
            print("⚠️ YOLO 모델 없음 - Mock 데이터 반환")
            return []
        
        try:
            print(f"\n🔍 YOLO 탐지 시작: {image_path}")
            
            # 이미지 로드
            img0 = cv2.imread(image_path)
            if img0 is None:
                print(f"❌ 이미지 로드 실패: {image_path}")
                return []
            
            h0, w0 = img0.shape[:2]
            print(f"원본 이미지: {w0}x{h0}")
            
            # 이미지 전처리
            img_size = 512
            img = letterbox(img0, new_shape=img_size)[0]
            img = img[:, :, ::-1].transpose(2, 0, 1)  # BGR to RGB, HWC to CHW
            img = np.ascontiguousarray(img)
            
            # Tensor 변환
            img = torch.from_numpy(img).to(self.device)
            img = img.float() / 255.0  # 0-255 → 0-1
            if img.ndimension() == 3:
                img = img.unsqueeze(0)
            
            print(f"입력 Tensor: {img.shape}")
            
            # 추론
            with torch.no_grad():
                pred = self.yolo_model(img)[0]
            
            # NMS 적용
            pred = non_max_suppression(pred, conf_thres, iou_thres)
            
            # 결과 파싱
            detections = []
            for i, det in enumerate(pred):
                if det is not None and len(det):
                    # bbox 좌표 원본 이미지 크기로 변환
                    det[:, :4] = scale_coords(img.shape[2:], det[:, :4], img0.shape).round()
                    
                    for *xyxy, conf, cls in reversed(det):
                        cls_idx = int(cls)
                        food_code = self.food_classes[cls_idx] if cls_idx < len(self.food_classes) else str(cls_idx)
                        
                        detection = {
                            "food_code": food_code,
                            "bbox": [int(x) for x in xyxy],  # [x1, y1, x2, y2]
                            "confidence": float(conf)
                        }
                        detections.append(detection)
                        print(f"  ✅ 탐지: {food_code}, 신뢰도: {conf:.2f}, bbox: {detection['bbox']}")
            
            print(f"총 {len(detections)}개 음식 탐지")
            return detections
            
        except Exception as e:
            print(f"❌ YOLO 탐지 실패: {e}")
            import traceback
            traceback.print_exc()
            return []
    
    def estimate_quantity_resnet(self, image_path: str, bbox: List[int]) -> float:
        """
        ResNet으로 음식 양 추정
        
        Args:
            image_path: 이미지 경로
            bbox: [x1, y1, x2, y2]
        
        Returns:
            float: 양 배수 (Q) - 예: 1.2 = 기준량의 1.2배
        """
        if self.resnet_model is None:
            print("⚠️ ResNet 모델 없음 - 기본값 1.0 반환")
            return 1.0
        
        try:
            print(f"\n📊 ResNet 양 추정: bbox={bbox}")
            
            # 이미지 로드 및 크롭
            img = Image.open(image_path).convert('RGB')
            x1, y1, x2, y2 = bbox
            cropped = img.crop((x1, y1, x2, y2))
            
            # 전처리
            transform = transforms.Compose([
                transforms.Resize(256),
                transforms.CenterCrop(224),
                transforms.ToTensor(),
                transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
            ])
            
            input_tensor = transform(cropped).unsqueeze(0)
            
            # 추론
            with torch.no_grad():
                output = self.resnet_model(input_tensor)
            
            # Q1~Q5 중 가장 높은 확률의 클래스 선택
            # Q1=0.5, Q2=0.75, Q3=1.0, Q4=1.25, Q5=1.5
            Q_mapping = {0: 0.5, 1: 0.75, 2: 1.0, 3: 1.25, 4: 1.5}
            pred_class = torch.argmax(output, dim=1).item()
            Q = Q_mapping.get(pred_class, 1.0)
            
            print(f"  ✅ 양 추정: Q={Q} (클래스: Q{pred_class+1})")
            return Q
            
        except Exception as e:
            print(f"❌ ResNet 양 추정 실패: {e}")
            import traceback
            traceback.print_exc()
            return 1.0
    
    def get_nutrition_info(self, food_code: str, food_name: str = None) -> Optional[Dict]:
        """
        영양 DB에서 음식 정보 조회
        
        Args:
            food_code: 음식 코드 (예: "01012001")
            food_name: 음식 한글명 (예: "쌀밥") - YOLO가 반환한 경우
        
        Returns:
            Dict 또는 None: {"food_name": "쌀밥", "calories": 312, "carbs": 68.4, ...}
        """
        if self.nutrition_db is None:
            print(f"⚠️ 영양 DB 없음: {food_code}")
            return None
        
        try:
            # 영양 DB 컬럼: ['음 식 명', '중량(g)', '에너지(kcal)', '탄수화물(g)', ...]
            
            # 1. 음식 코드로 매핑 시도 (추후 매핑 테이블 추가 시)
            # 현재는 코드→한글명 매핑 파일이 없으므로 스킵
            
            # 2. 음식명으로 직접 매칭 (임시 방법)
            # food_code가 실제로는 한글명일 수도 있으므로 양쪽 다 시도
            match = None
            
            if food_name:
                # 한글 음식명이 제공된 경우
                match = self.nutrition_db[self.nutrition_db['음 식 명'].str.contains(food_name, na=False)]
            
            if match is None or match.empty:
                # 음식 코드 자체가 한글명인 경우도 시도
                match = self.nutrition_db[self.nutrition_db['음 식 명'].str.contains(food_code, na=False)]
            
            if match.empty:
                print(f"⚠️ 영양 정보 없음: {food_code} / {food_name}")
                # 기본 음식 정보 반환 (0값)
                return {
                    "food_name": food_name or food_code,
                    "calories": 0,
                    "carbohydrates": 0,
                    "protein": 0,
                    "fat": 0,
                    "sodium": 0,
                }
            
            # 첫 번째 매칭 결과 사용
            row = match.iloc[0]
            
            # 영양 정보 추출
            nutrition = {
                "food_name": str(row['음 식 명']),
                "calories": float(row['에너지(kcal)']),
                "carbohydrates": float(row['탄수화물(g)']),
                "protein": float(row['단백질(g)']),
                "fat": float(row['지방(g)']),
                "sodium": float(row['나트륨(mg)']),
            }
            
            print(f"  ✅ 영양 정보: {nutrition['food_name']} - {nutrition['calories']} kcal")
            return nutrition
            
        except Exception as e:
            print(f"❌ 영양 정보 조회 실패: {food_code}, {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def analyze_meal_image(self, image_path: str) -> List[Dict]:
        """
        식사 이미지 종합 분석
        
        Workflow:
            1. YOLO로 음식 탐지 → food_code, bbox
            2. 각 bbox에 대해 ResNet으로 양 추정 → Q
            3. food_code로 영양 DB 조회 → base nutrition
            4. 최종 영양소 = base × Q
        
        Args:
            image_path: 분석할 이미지 경로
        
        Returns:
            List[Dict]: [{
                "food_name": "쌀밥",
                "calories": 374.4,  # 312 * 1.2
                "carbohydrates": 82.08,
                "protein": 7.2,
                "fat": 1.44,
                "quantity_multiplier": 1.2,
                "confidence": 0.88
            }, ...]
        """
        print(f"\n{'='*60}")
        print(f"🍽️ 식사 이미지 분석 시작: {image_path}")
        print(f"{'='*60}")
        
        results = []
        
        # 1. YOLO 탐지
        detections = self.detect_food_yolo(image_path)
        
        if not detections:
            print("⚠️ 탐지된 음식 없음 - Mock 데이터 사용")
            # YOLO가 작동하지 않을 때 기본 Mock 데이터 반환
            from PIL import Image
            img = Image.open(image_path)
            width, height = img.size
            
            # 이미지 전체를 하나의 음식으로 간주
            detections = [{
                "food_code": "밥",
                "bbox": [0, 0, width, height],
                "confidence": 0.5
            }]
            print(f"  → Mock 탐지 생성: {detections[0]['food_code']}")
        
        # 2. 각 탐지 결과에 대해 ResNet 양 추정 + 영양 DB 조회
        for i, det in enumerate(detections):
            print(f"\n--- 음식 {i+1}/{len(detections)} ---")
            
            food_code = det['food_code']
            bbox = det['bbox']
            confidence = det['confidence']
            
            # ResNet 양 추정
            Q = self.estimate_quantity_resnet(image_path, bbox)
            
            # 영양 DB 조회 (음식 코드 전달, 한글명은 없음)
            nutrition = self.get_nutrition_info(food_code, food_name=None)
            
            if nutrition:
                # 최종 영양소 = 기준 × Q
                result = {
                    "food_name": nutrition['food_name'],
                    "calories_kcal": round(nutrition['calories'] * Q, 2),
                    "carbohydrates_g": round(nutrition['carbohydrates'] * Q, 2),
                    "protein_g": round(nutrition['protein'] * Q, 2),
                    "fat_g": round(nutrition['fat'] * Q, 2),
                    "sugars_g": round(nutrition.get('sugars', 0) * Q, 2),
                    "sodium_mg": round(nutrition['sodium'] * Q, 2),
                    "quantity_multiplier": Q,
                    "confidence": confidence
                }
                results.append(result)
                print(f"✅ {result['food_name']}: {result['calories_kcal']} kcal (Q={Q})")
            else:
                # 영양 정보 없으면 기본값
                result = {
                    "food_name": food_code,
                    "calories_kcal": 0,
                    "carbohydrates_g": 0,
                    "protein_g": 0,
                    "fat_g": 0,
                    "sugars_g": 0,
                    "sodium_mg": 0,
                    "quantity_multiplier": Q,
                    "confidence": confidence
                }
                results.append(result)
                print(f"⚠️ {food_code}: 영양 정보 없음")
        
        print(f"\n{'='*60}")
        print(f"✅ 분석 완료: 총 {len(results)}개 음식")
        print(f"{'='*60}")
        
        return results


# 싱글톤 인스턴스
_analyzer_instance = None

def get_food_analyzer() -> FoodAnalyzer:
    """싱글톤 FoodAnalyzer 인스턴스 반환"""
    global _analyzer_instance
    if _analyzer_instance is None:
        _analyzer_instance = FoodAnalyzer()
    return _analyzer_instance
