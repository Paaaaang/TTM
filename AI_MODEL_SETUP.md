# AI 모델 배포 가이드

## 문제 상황

GitHub에 AI 모델 파일(667MB+)을 올릴 수 없어서 제외했는데, Render에서 어떻게 AI 모델을 실행할 수 있나요?

## 해결 방법

### 방법 1: Google Drive/Dropbox 자동 다운로드 ⭐ (권장)

#### Step 1: 모델 파일을 클라우드에 업로드

1. **Google Drive 업로드**
   - YOLO 모델: `backend/ai_models/Food_classification/yolov3/weights/best_403food_e200b150v2.pt` (667MB)
   - ResNet 모델: `backend/ai_models/E_of_the_a_of_food/quantity_est/weights/new_opencv_ckpt_b84_e200.pth` (85MB)

2. **공유 링크 생성**

   ```
   우클릭 → 공유 → 링크 복사
   예: https://drive.google.com/file/d/1aBcDeFgHiJkLmNoPqRsTuVwXyZ/view?usp=sharing
   ```

3. **직접 다운로드 링크로 변환**
   ```
   원본: https://drive.google.com/file/d/FILE_ID/view?usp=sharing
   변환: https://drive.google.com/uc?export=download&id=FILE_ID
   ```

#### Step 2: download_models.py 수정

```python
# backend/download_models.py

MODEL_URLS = {
    "yolo": {
        "url": "https://drive.google.com/uc?export=download&id=YOUR_YOLO_FILE_ID",
        "path": "ai_models/Food_classification/yolov3/weights/best_403food_e200b150v2.pt"
    },
    "resnet": {
        "url": "https://drive.google.com/uc?export=download&id=YOUR_RESNET_FILE_ID",
        "path": "ai_models/E_of_the_a_of_food/quantity_est/weights/new_opencv_ckpt_b84_e200.pth"
    }
}
```

#### Step 3: Render 설정 변경

`backend/render.yaml` 수정:

```yaml
services:
  - type: web
    name: ttm-backend
    runtime: python
    plan: starter # AI 모델 사용 시 유료 플랜 필수
    buildCommand: pip install -r requirements.txt # requirements.render.txt → requirements.txt
    startCommand: bash start_with_models.sh # start.sh → start_with_models.sh
    envVars:
      - key: PYTHON_VERSION
        value: 3.11
      - key: DATABASE_URL
        sync: false
      - key: JWT_SECRET_KEY
        generateValue: true
      - key: GOOGLE_API_KEY
        sync: false # Gemini AI 코치용
```

#### Step 4: Git 커밋 및 Push

```bash
git add backend/download_models.py backend/start_with_models.sh backend/render.yaml AI_MODEL_SETUP.md
git commit -m "Add AI model auto-download for Render deployment"
git push origin master
```

#### Step 5: Render에서 재배포

Render Dashboard → 서비스 선택 → **Manual Deploy** → **Deploy latest commit**

배포 로그에서 확인:

```
📥 Step 1: AI 모델 다운로드 확인
📥 다운로드 중: ai_models/Food_classification/yolov3/weights/best_403food_e200b150v2.pt
진행률: 100.0%
✅ 다운로드 완료
```

---

### 방법 2: Render Disk (영구 스토리지)

1. **Render Dashboard** → 서비스 선택 → **Disks** 탭
2. **Add Disk** 클릭
   ```
   Name: ai-models
   Mount Path: /opt/render/project/src/ai_models
   Size: 2 GB (모델 크기에 맞게)
   ```
3. 디스크 생성 후, SSH로 접속하여 모델 파일 수동 업로드
4. 한 번만 업로드하면 재배포 시에도 유지됨

**단점**: 초기 설정이 복잡하고, 수동 업로드 필요

---

### 방법 3: AWS S3/다른 클라우드 스토리지

```python
# backend/download_models.py
import boto3

def download_from_s3():
    s3 = boto3.client('s3',
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY'),
        aws_secret_access_key=os.getenv('AWS_SECRET_KEY')
    )

    s3.download_file(
        'your-bucket-name',
        'models/best_403food_e200b150v2.pt',
        'ai_models/Food_classification/yolov3/weights/best_403food_e200b150v2.pt'
    )
```

**환경 변수 설정 필요**:

- `AWS_ACCESS_KEY`
- `AWS_SECRET_KEY`

---

## 주의사항

### 1. 메모리 요구사항

- **YOLO + ResNet 실행**: 최소 2GB RAM 필요
- **Render Starter Plan**: $7/월 (2GB RAM) ✅
- **Free Plan**: 512MB RAM ❌ (AI 모델 실행 불가)

### 2. 다운로드 시간

- 첫 배포 시 모델 다운로드: 약 2-5분 소요
- 재배포 시 모델이 이미 있으면 스킵

### 3. 디스크 공간

- Render 기본 디스크: 2GB
- AI 모델 크기: 약 750MB
- 충분한 여유 공간 확보 필요

### 4. 대안: AI 기능 비활성화

모델 다운로드가 실패하거나 불필요하면:

```python
# backend/services/nutrition_analyzer.py
DISABLE_AI = os.getenv("DISABLE_AI_MODELS", "false").lower() == "true"

if DISABLE_AI:
    # Mock 데이터 반환
    return {
        "detected_foods": ["음식 인식 비활성화"],
        "nutrition": {"calories": 0}
    }
```

Render 환경 변수:

```
DISABLE_AI_MODELS=true
```

---

## 빠른 시작 (방법 1 권장)

```bash
# 1. 모델 파일 Google Drive에 업로드
# 2. download_models.py에 링크 설정
# 3. Git 커밋 & Push
git add backend/download_models.py backend/start_with_models.sh
git commit -m "Setup AI model auto-download"
git push origin master

# 4. Render에서 재배포
# 5. 로그 확인
```

---

## 문제 해결

### 다운로드 실패 시

```bash
# Render 로그 확인
❌ 다운로드 실패: HTTPError 404

# 해결: Google Drive 링크 확인
# - 공유 설정: 링크가 있는 모든 사용자
# - 직접 다운로드 URL 사용
```

### 메모리 부족

```bash
# Render 로그
Killed (OOM - Out of Memory)

# 해결: Starter Plan ($7/월) 이상 사용
```

### 모델 로드 실패

```bash
# 백엔드 로그
❌ YOLO 가중치 파일 없음

# 확인:
# 1. download_models.py 실행됐는지
# 2. 파일 경로가 올바른지
# 3. 다운로드가 완료됐는지
```

---

## 요약

✅ **권장 방식**: Google Drive 자동 다운로드

- 간단하고 무료
- 재배포 시 자동화
- 유지보수 쉬움

❌ **비권장**: Git에 직접 커밋

- GitHub 용량 제한 (50MB)
- Git LFS는 복잡하고 유료

🎯 **결론**: `download_models.py` + `start_with_models.sh` 사용
