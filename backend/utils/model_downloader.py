"""
AI 모델 다운로더
- Google Drive 대용량 파일 다운로드
- 파일 락으로 동시 다운로드 방지
- 파일 크기/무결성 검증
- HTML 저장 방지
"""
import os
import fcntl
import gdown
from pathlib import Path
from typing import Optional
import logging

logger = logging.getLogger(__name__)


class ModelDownloader:
    """모델 파일 다운로드 및 검증"""
    
    def __init__(self, lock_dir: Path = None):
        """
        Args:
            lock_dir: 락 파일 저장 디렉토리 (기본: /tmp)
        """
        self.lock_dir = lock_dir or Path("/tmp")
        self.lock_dir.mkdir(parents=True, exist_ok=True)
    
    def _acquire_lock(self, model_name: str) -> Optional[int]:
        """
        파일 락 획득 (동시 다운로드 방지)
        
        Returns:
            file descriptor (해제 시 필요)
        """
        lock_file = self.lock_dir / f"{model_name}.lock"
        try:
            fd = os.open(str(lock_file), os.O_CREAT | os.O_RDWR)
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            logger.info(f"🔒 Lock acquired: {model_name}")
            return fd
        except (IOError, OSError) as e:
            logger.info(f"⏳ Waiting for lock: {model_name}")
            # 다른 프로세스가 다운로드 중, 대기
            try:
                fd = os.open(str(lock_file), os.O_RDONLY)
                fcntl.flock(fd, fcntl.LOCK_SH)  # 공유 락 (읽기 대기)
                fcntl.flock(fd, fcntl.LOCK_UN)
                os.close(fd)
                logger.info(f"✅ Lock released (download complete): {model_name}")
                return None
            except Exception as wait_error:
                logger.error(f"❌ Lock wait error: {wait_error}")
                return None
    
    def _release_lock(self, fd: Optional[int]):
        """파일 락 해제"""
        if fd is not None:
            try:
                fcntl.flock(fd, fcntl.LOCK_UN)
                os.close(fd)
            except Exception as e:
                logger.error(f"Lock release error: {e}")
    
    def verify_file(self, file_path: Path, min_size: int) -> bool:
        """
        파일 검증
        - 존재 여부
        - 크기 체크 (HTML 저장 방지)
        - 읽기 가능 여부
        """
        if not file_path.exists():
            return False
        
        file_size = file_path.stat().st_size
        if file_size < min_size:
            logger.warning(f"⚠️ File too small: {file_path} ({file_size} bytes < {min_size} bytes)")
            return False
        
        # 파일 시작 부분이 HTML이 아닌지 확인
        try:
            with open(file_path, 'rb') as f:
                header = f.read(100)
                if b'<!DOCTYPE' in header or b'<html' in header:
                    logger.error(f"❌ File is HTML (Google Drive error page): {file_path}")
                    return False
        except Exception as e:
            logger.error(f"❌ File read error: {e}")
            return False
        
        logger.info(f"✅ File verified: {file_path} ({file_size / (1024*1024):.1f} MB)")
        return True
    
    def download_model(
        self,
        drive_id: str,
        destination: Path,
        model_name: str,
        min_size: int,
        force: bool = False
    ) -> bool:
        """
        Google Drive에서 모델 다운로드
        
        Args:
            drive_id: Google Drive 파일 ID
            destination: 저장 경로
            model_name: 모델 이름 (락 식별용)
            min_size: 최소 파일 크기 (바이트)
            force: 기존 파일 무시하고 재다운로드
        
        Returns:
            성공 여부
        """
        # 파일이 이미 존재하고 검증 통과하면 스킵
        if not force and self.verify_file(destination, min_size):
            logger.info(f"⏭️ Model already exists: {destination}")
            return True
        
        # 락 획득 시도
        lock_fd = self._acquire_lock(model_name)
        
        # 다른 프로세스가 다운로드 완료한 경우
        if lock_fd is None:
            return self.verify_file(destination, min_size)
        
        try:
            # 디렉토리 생성
            destination.parent.mkdir(parents=True, exist_ok=True)
            
            # 임시 파일로 다운로드 (원자적 이동을 위해)
            temp_dest = destination.with_suffix('.tmp')
            
            logger.info(f"📥 Downloading {model_name}...")
            logger.info(f"   From: https://drive.google.com/file/d/{drive_id}")
            logger.info(f"   To: {destination}")
            
            # gdown으로 다운로드
            url = f"https://drive.google.com/uc?id={drive_id}"
            output = gdown.download(url, str(temp_dest), quiet=False, fuzzy=True)
            
            if output is None:
                logger.error(f"❌ Download failed: gdown returned None")
                if temp_dest.exists():
                    temp_dest.unlink()
                return False
            
            # 다운로드된 파일 검증
            if not self.verify_file(temp_dest, min_size):
                logger.error(f"❌ Downloaded file verification failed")
                if temp_dest.exists():
                    temp_dest.unlink()
                return False
            
            # 임시 파일을 최종 경로로 이동
            if destination.exists():
                destination.unlink()
            temp_dest.rename(destination)
            
            logger.info(f"✅ Download complete: {destination}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Download error: {e}")
            import traceback
            traceback.print_exc()
            return False
            
        finally:
            self._release_lock(lock_fd)
    
    def ensure_models(
        self,
        models_config: list[dict]
    ) -> dict[str, bool]:
        """
        여러 모델 파일 확인/다운로드
        
        Args:
            models_config: [
                {
                    'name': 'yolo',
                    'drive_id': '...',
                    'destination': Path(...),
                    'min_size': 200000000
                },
                ...
            ]
        
        Returns:
            {model_name: success}
        """
        results = {}
        
        for config in models_config:
            name = config['name']
            success = self.download_model(
                drive_id=config['drive_id'],
                destination=config['destination'],
                model_name=name,
                min_size=config['min_size']
            )
            results[name] = success
        
        return results
