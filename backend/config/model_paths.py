"""
AI 모델 경로 설정
환경에 따라 base path만 변경하면 되도록 중앙화
"""
import os
from pathlib import Path

# 환경 변수에서 base path 읽기 (fallback 지원)
# 우선순위: 환경변수 > /var/data (쓰기 가능 시) > 로컬
def get_models_base_path():
    env_path = os.getenv("AI_MODELS_BASE_PATH")
    if env_path:
        return Path(env_path)
    
    # /var/data 쓰기 가능 확인
    var_data = Path("/var/data/ai_models")
    try:
        var_data.mkdir(parents=True, exist_ok=True)
        # 쓰기 테스트
        test_file = var_data / ".write_test"
        test_file.touch()
        test_file.unlink()
        return var_data
    except (PermissionError, OSError):
        pass
    
    # fallback: 로컬 경로
    return Path(__file__).parent.parent / "ai_models"

AI_MODELS_BASE = get_models_base_path()

# YOLO 모델 경로
YOLO_DIR = AI_MODELS_BASE / "Food_classification" / "yolov3"
YOLO_WEIGHTS = YOLO_DIR / "weights" / "best_403food_e200b150v2.pt"
YOLO_CFG = YOLO_DIR / "cfg" / "yolov3-spp-403cls.cfg"
YOLO_NAMES = YOLO_DIR / "data" / "403food.names"

# ResNet 모델 경로
RESNET_WEIGHTS = AI_MODELS_BASE / "E_of_the_a_of_food" / "quantity_est" / "weights" / "new_opencv_ckpt_b84_e200.pth"

# 영양 DB 경로 (코드와 함께 배포됨)
DATA_DIR = Path(__file__).parent.parent / "data"
NUTRITION_DB_PATH = DATA_DIR / "Food_Classification_AI_Data_Nutrition_DB.xlsx"
FOOD_CODE_MAP_PATH = DATA_DIR / "food_code_mapping.json"

# Google Drive 파일 ID
YOLO_DRIVE_ID = os.getenv("YOLO_MODEL_DRIVE_ID", "1yBITpY563jVUNmx_wIQvn3bJ5yj5OrDE")
RESNET_DRIVE_ID = os.getenv("RESNET_MODEL_DRIVE_ID", "1ROaLfNs40PyESJTBP3b2bN0p_oeg46HH")

# 모델 파일 최소 크기 (바이트) - 검증용
YOLO_MIN_SIZE = 200 * 1024 * 1024  # 200MB
RESNET_MIN_SIZE = 80 * 1024 * 1024  # 80MB

def get_model_info():
    """모델 경로 정보 출력"""
    return {
        "base_path": str(AI_MODELS_BASE),
        "yolo_weights": str(YOLO_WEIGHTS),
        "resnet_weights": str(RESNET_WEIGHTS),
        "yolo_exists": YOLO_WEIGHTS.exists(),
        "resnet_exists": RESNET_WEIGHTS.exists(),
    }
