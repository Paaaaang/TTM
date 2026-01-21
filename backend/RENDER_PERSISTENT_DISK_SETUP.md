# Render Persistent Disk 설정 가이드

## 1. Persistent Disk 생성

Render Dashboard → Storage → New Persistent Disk

**설정:**
- Name: `ttm-ai-models`
- Size: `3 GB` (YOLO 247MB + ResNet 85MB + 여유공간)
- Region: 서비스와 동일 리전 선택

## 2. Web Service에 연결

Web Service → Settings → Disks

**Mount 설정:**
- Disk: `ttm-ai-models`
- Mount Path: `/var/data`

## 3. 환경 변수 설정

Render Dashboard → Environment Variables

```bash
# AI 모델 저장 경로 (Persistent Disk)
AI_MODELS_BASE_PATH=/var/data/ai_models

# AI 모델 활성화
DISABLE_AI_MODELS=false

# Google Drive 파일 ID
YOLO_MODEL_DRIVE_ID=1yBITpY563jVUNmx_wIQvn3bJ5yj5OrDE
RESNET_MODEL_DRIVE_ID=1ROaLfNs40PyESJTBP3b2bN0p_oeg46HH
```

## 4. 디렉터리 구조

```
/var/data/                          (Persistent Disk - 재시작 시 유지)
└── ai_models/
    ├── Food_classification/
    │   └── yolov3/
    │       ├── cfg/
    │       ├── data/
    │       └── weights/
    │           └── best_403food_e200b150v2.pt  (247MB)
    └── E_of_the_a_of_food/
        └── quantity_est/
            └── weights/
                └── new_opencv_ckpt_b84_e200.pth  (85MB)

/opt/render/project/src/backend/    (임시 파일 시스템 - 재시작 시 초기화)
├── main.py
├── config/
├── services/
└── utils/
```

## 5. 메모리 최적화 전략 (2GB 제한)

**모델 로드 순서:**
1. ResNet만 로드 (85MB) - 양 추정용
2. YOLO 로드 시도 (247MB + inference 메모리)
3. 메모리 부족 시 YOLO는 Mock 데이터 사용

**권장 설정:**
```bash
# Render 환경 변수
WEB_CONCURRENCY=1           # 단일 워커
WORKERS=1
WORKER_CLASS=sync
MAX_REQUESTS=1000          # 메모리 누수 방지
```

## 6. 배포 플로우

1. 첫 배포 시: 
   - Persistent Disk 비어있음
   - startup에서 Google Drive 다운로드 (약 3-5분)
   - 파일 검증 후 완료

2. 재배포/재시작 시:
   - Persistent Disk에 모델 파일 존재
   - 파일 검증만 수행 (빠름)
   - 다운로드 스킵

3. API 요청 시:
   - 첫 요청에서만 torch.load (lazy loading)
   - 이후 요청은 캐시된 모델 사용

## 7. 주의사항

- Persistent Disk는 **유료** ($0.25/GB/month, 3GB = $0.75/month)
- 디스크 삭제 시 모델 파일 모두 삭제됨
- 백업 필요 시 Google Drive 원본 유지
