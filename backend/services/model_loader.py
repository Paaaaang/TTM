"""
AI 모델 Lazy Loader (메모리 최적화)
- 첫 요청 시에만 torch.load
- 싱글톤 패턴으로 전역 캐싱
- 스레드 안전성 보장
"""
import threading
import logging
from typing import Optional
from pathlib import Path

logger = logging.getLogger(__name__)

# 전역 모델 캐시
_yolo_model = None
_resnet_model = None
_load_lock = threading.Lock()


class ModelLoader:
    """모델 Lazy Loading 관리"""
    
    @staticmethod
    def load_yolo_model(weights_path: Path):
        """
        YOLO 모델 로드 (lazy)
        
        Args:
            weights_path: .pt 파일 경로
        
        Returns:
            torch.nn.Module
        """
        global _yolo_model
        
        if _yolo_model is not None:
            logger.debug("♻️ Using cached YOLO model")
            return _yolo_model
        
        with _load_lock:
            # Double-check (다른 스레드가 로드 완료했을 수 있음)
            if _yolo_model is not None:
                return _yolo_model
            
            logger.info(f"📦 Loading YOLO model from {weights_path}...")
            
            try:
                import torch
                from ultralytics import YOLO
                
                # YOLO 모델 로드
                model = YOLO(str(weights_path))
                
                # GPU 사용 가능 시 이동
                if torch.cuda.is_available():
                    model.to('cuda')
                    logger.info("🚀 YOLO model loaded on GPU")
                else:
                    logger.info("💻 YOLO model loaded on CPU")
                
                _yolo_model = model
                return _yolo_model
                
            except Exception as e:
                logger.error(f"❌ YOLO load error: {e}")
                raise
    
    @staticmethod
    def load_resnet_model(weights_path: Path):
        """
        ResNet 모델 로드 (lazy)
        
        Args:
            weights_path: .pth 파일 경로
        
        Returns:
            torch.nn.Module
        """
        global _resnet_model
        
        if _resnet_model is not None:
            logger.debug("♻️ Using cached ResNet model")
            return _resnet_model
        
        with _load_lock:
            # Double-check
            if _resnet_model is not None:
                return _resnet_model
            
            logger.info(f"📦 Loading ResNet model from {weights_path}...")
            
            try:
                import torch
                import torch.nn as nn
                from torchvision import models
                
                # ResNet50 구조 생성
                model = models.resnet50(weights=None)
                num_ftrs = model.fc.in_features
                model.fc = nn.Linear(num_ftrs, 1)  # 회귀 (양 예측)
                
                # 체크포인트 로드
                checkpoint = torch.load(
                    str(weights_path),
                    map_location=torch.device('cuda' if torch.cuda.is_available() else 'cpu')
                )
                
                # state_dict 추출 (체크포인트 구조에 따라)
                if 'state_dict' in checkpoint:
                    state_dict = checkpoint['state_dict']
                elif 'model_state_dict' in checkpoint:
                    state_dict = checkpoint['model_state_dict']
                else:
                    state_dict = checkpoint
                
                model.load_state_dict(state_dict)
                model.eval()
                
                # GPU 사용 가능 시 이동
                if torch.cuda.is_available():
                    model.to('cuda')
                    logger.info("🚀 ResNet model loaded on GPU")
                else:
                    logger.info("💻 ResNet model loaded on CPU")
                
                _resnet_model = model
                return _resnet_model
                
            except Exception as e:
                logger.error(f"❌ ResNet load error: {e}")
                raise
    
    @staticmethod
    def unload_models():
        """
        모델 메모리 해제 (테스트/개발용)
        
        주의: 프로덕션에서는 사용하지 말 것
        """
        global _yolo_model, _resnet_model
        
        with _load_lock:
            if _yolo_model is not None:
                del _yolo_model
                _yolo_model = None
                logger.info("🗑️ YOLO model unloaded")
            
            if _resnet_model is not None:
                del _resnet_model
                _resnet_model = None
                logger.info("🗑️ ResNet model unloaded")
            
            # CUDA 캐시 정리
            try:
                import torch
                if torch.cuda.is_available():
                    torch.cuda.empty_cache()
            except:
                pass
    
    @staticmethod
    def get_model_status() -> dict:
        """
        모델 로드 상태 확인
        
        Returns:
            {
                'yolo_loaded': bool,
                'resnet_loaded': bool
            }
        """
        return {
            'yolo_loaded': _yolo_model is not None,
            'resnet_loaded': _resnet_model is not None
        }
