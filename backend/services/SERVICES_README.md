# TTM Backend Services

TTM 백엔드의 핵심 비즈니스 로직과 외부 서비스 통합을 담당하는 서비스 레이어입니다.

## 📁 구조

```
backend/services/
├── badge_auto_award.py    # 배지 자동 수여 시스템
├── fcm_service.py          # Firebase 푸시 알림
├── food_analyzer.py        # AI 음식 분석
└── __init__.py
```

---

## 🏅 badge_auto_award.py

사용자 활동을 모니터링하고 조건을 만족할 때 배지를 자동으로 수여하는 시스템입니다.

### 주요 기능

- **자동 배지 수여**: 11가지 배지 조건 실시간 체크
- **중복 수여 방지**: 이미 획득한 배지 자동 필터링
- **트랜잭션 처리**: @handle_db_transaction 데코레이터로 안전한 DB 작업

### 배지 종류 (11개)

| Badge ID | 배지명 | 조건 | 함수 |
|---------|-------|-----|------|
| 1 | 첫 걸음 | 첫 번째 식단 기록 | `_check_first_meal` |
| 2 | 운동 초보 | 운동 10회 기록 | `_check_10_exercises` |
| 3 | 꾸준함 | 7일 연속 활동 | `_check_7_day_streak` |
| 4 | 건강 마스터 | 30일 연속 활동 | `_check_30_day_streak` |
| 5 | 완벽한 하루 | 칼로리 목표 + 운동 달성 | `_check_perfect_day` |
| 6 | 운동왕 | 운동 100회 달성 | `_check_100_exercises` |
| 7 | 아침형 | 아침 식단 30회 기록 | `_check_30_breakfasts` |
| 8 | 야식 킬러 | 14일간 야식(21시 이후) 없음 | `_check_no_late_snack` |
| 9 | 칼로리왕 | 50일 칼로리 목표 달성 | `_check_50_calorie_goals` |
| 13 | 별 (소셜 스타) | 커뮤니티 글 50개 작성 | `_check_50_posts` |
| 14 | 리액션 (인기인) | 좋아요 500개 받기 | `_check_500_likes` |

### 사용 예시

```python
from services.badge_auto_award import BadgeAutoAward

# 사용자 활동 후 배지 체크 및 수여
newly_earned = BadgeAutoAward.check_and_award_badges(member_id=123)

# 새로 획득한 배지 확인
for badge in newly_earned:
    print(f"🎉 새 배지 획득: {badge['badge_name']}")
    # badge_id, badge_name, description, icon_path
```

### 호출 시점

- **식단 기록**: 식단 생성/수정 후 → 식단 관련 배지 체크
- **운동 기록**: 운동 생성/수정 후 → 운동 관련 배지 체크
- **커뮤니티 활동**: 게시글 작성/좋아요 후 → 소셜 배지 체크
- **일일 체크**: 자정 배치 작업 → 연속 활동 배지 체크

### 최적화 내역 (2026-01-14)

- ✅ **@handle_db_transaction 데코레이터 적용**
  - 수동 DB 연결 관리 제거 (`conn = get_db_connection()`, `cursor.close()`, `conn.close()`)
  - try-except-finally 블록 제거
  - 자동 커밋/롤백 처리
- ✅ **타입 힌트 추가**: 반환 타입 `List[Dict]` 명시
- ✅ **코드 라인 수 감소**: 299 → 293 lines (-6 lines, 2% 감소)

---

## 🔔 fcm_service.py

Firebase Cloud Messaging을 통한 모바일 푸시 알림 서비스입니다.

### 주요 기능

- **단일 디바이스 알림**: 특정 사용자에게 푸시 전송
- **멀티캐스트 알림**: 여러 사용자에게 동시 전송
- **댓글 알림**: 댓글/대댓글 작성 시 알림
- **좋아요 알림**: 게시글 좋아요 시 알림
- **선택적 의존성**: firebase-admin 미설치 시 graceful degradation

### 설정 방법

#### 1. Firebase Console 설정

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 → **프로젝트 설정** (⚙️)
3. **서비스 계정** 탭 → **새 비공개 키 생성**
4. JSON 파일 다운로드

#### 2. 서비스 계정 키 설정

```bash
# 방법 1: 환경 변수 설정
export FIREBASE_CREDENTIALS_PATH=/path/to/firebase-credentials.json

# 방법 2: 기본 경로에 파일 배치
cp firebase-credentials.json backend/firebase-credentials.json
```

#### 3. 패키지 설치

```bash
pip install firebase-admin
```

### 사용 예시

```python
from services.fcm_service import FCMService

# 1. 앱 시작 시 초기화 (main.py에서 한 번만 실행)
FCMService.initialize()

# 2. 단일 디바이스 알림 전송
await FCMService.send_notification(
    token="user_fcm_token_here",
    title="새로운 메시지",
    body="안녕하세요!",
    data={
        "type": "message",
        "targetId": "123"
    }
)

# 3. 멀티캐스트 알림 (여러 디바이스)
result = await FCMService.send_multicast(
    tokens=["token1", "token2", "token3"],
    title="공지사항",
    body="시스템 점검 안내",
    data={"type": "announcement"}
)
print(f"성공: {result['success']}, 실패: {result['failure']}")

# 4. 댓글 알림
await FCMService.send_comment_notification(
    fcm_token="post_author_token",
    commenter_name="김철수",
    post_id=456,
    is_reply=False  # True면 대댓글
)

# 5. 좋아요 알림
await FCMService.send_like_notification(
    fcm_token="post_author_token",
    liker_name="이영희",
    post_id=789
)
```

### FCM 토큰 관리

사용자의 FCM 토큰은 `members` 테이블의 `fcm_token` 컬럼에 저장됩니다.

```sql
-- FCM 토큰 저장
UPDATE members SET fcm_token = %s WHERE member_id = %s

-- FCM 토큰 조회 (알림 전송 시)
SELECT fcm_token FROM members WHERE member_id = %s
```

Flutter 앱에서 FCM 토큰 등록:
```dart
// lib/services/fcm_service.dart
final token = await FirebaseMessaging.instance.getToken();
// API로 토큰 전송 → DB 저장
```

### 알림 데이터 구조

```json
{
  "notification": {
    "title": "새로운 댓글",
    "body": "김철수님이 댓글을 남겼습니다."
  },
  "data": {
    "type": "comment",     // "comment" | "reply" | "like" | "message"
    "targetId": "123"      // 게시글 ID, 메시지 ID 등
  },
  "android": {
    "priority": "high",
    "notification": {
      "sound": "default",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

### 최적화 내역 (2026-01-14)

- ✅ **상세 docstring 추가**
  - 모듈 레벨: 기능, 의존성, 설정 방법 설명
  - initialize(): 환경 변수, Firebase Console 가이드
- ✅ **Example 코드 추가**: 실제 사용법 명시
- ✅ **선택적 의존성 처리**: firebase-admin 미설치 시 경고만 출력

---

## 🍽️ food_analyzer.py

YOLO 객체 탐지 + ResNet 양 추정 + 영양 DB 조회를 통합한 AI 음식 분석 서비스입니다.

### Architecture

```
[식사 이미지]
    ↓
┌─────────────────────────────────┐
│ 1. YOLO v8 객체 탐지            │ → 음식명, bbox (x1,y1,x2,y2)
│    - 403개 음식 클래스           │    confidence (0~1)
│    - best_food_model.pt (247MB) │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│ 2. ResNet 양 추정               │ → Q (기준량 대비 배수)
│    - quantity_model.pth (85MB)  │    ratio (신뢰도)
│    - bbox 기반 crop 이미지 사용 │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│ 3. 영양 DB 조회                 │ → 100g 기준 영양소
│    - nutrition_db.xlsx (400개)  │    칼로리, 탄수화물, 단백질 등
│    - 음식명 매칭 (정확 + 부분)  │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│ 4. 영양소 계산                  │ → 최종 영양 정보
│    - 영양소 * Q = 실제 섭취량   │    (calories_kcal, protein_g 등)
└─────────────────────────────────┘
```

### AI 모델 준비

#### 모델 파일 위치
```
backend/
├── ai_models/
│   ├── yolo/
│   │   └── best_food_model.pt      # 247MB, 403 classes
│   └── resnet/
│       └── quantity_model.pth       # 85MB, quantity estimation
└── data/
    └── nutrition_db.xlsx            # 400 foods, 영양소 정보
```

#### 모델 다운로드 (필요 시)
```bash
# YOLO 모델 (예시 - 실제 경로는 프로젝트에 따라 다름)
# wget https://your-model-storage/best_food_model.pt -P backend/ai_models/yolo/

# ResNet 모델
# wget https://your-model-storage/quantity_model.pth -P backend/ai_models/resnet/
```

### 의존성 설치

```bash
# PyTorch (CUDA 버전은 환경에 맞게 선택)
pip install torch torchvision

# YOLO v8
pip install ultralytics

# 데이터 처리
pip install pandas openpyxl pillow numpy
```

### 사용 예시

```python
from services.food_analyzer import get_food_analyzer

# 싱글톤 인스턴스 사용
analyzer = get_food_analyzer()

# 식사 이미지 분석
image_path = "/path/to/meal_image.jpg"
results = analyzer.analyze_meal_image(image_path)

# 결과 구조
for food in results:
    print(f"음식: {food['food_name']}")
    print(f"칼로리: {food['calories_kcal']} kcal")
    print(f"탄수화물: {food['carbohydrates_g']} g")
    print(f"단백질: {food['protein_g']} g")
    print(f"지방: {food['fat_g']} g")
    print(f"나트륨: {food['sodium_mg']} mg")
    print(f"당류: {food['sugars_g']} g")
    print(f"중량: {food['weight_g']} g")
    print(f"양 배수: {food['quantity_multiplier']}")  # Q값
    print(f"신뢰도: {food['confidence']}")
    print(f"위치: {food['bbox']}")  # [x1, y1, x2, y2]
    print()
```

### API 통합 예시 (routers/meal.py)

```python
from services.food_analyzer import get_food_analyzer

@router.post("/meal/analyze")
async def analyze_meal(file: UploadFile):
    """식사 이미지 AI 분석 API"""
    # 1. 이미지 저장
    image_path = save_uploaded_file(file)
    
    # 2. AI 분석
    analyzer = get_food_analyzer()
    results = analyzer.analyze_meal_image(image_path)
    
    # 3. DB 저장
    for food in results:
        # meal_item 테이블에 저장
        insert_meal_item(
            meal_log_id=meal_log_id,
            food_name=food['food_name'],
            calories_kcal=food['calories_kcal'],
            carbohydrates_g=food['carbohydrates_g'],
            protein_g=food['protein_g'],
            fat_g=food['fat_g'],
            # ...
        )
    
    return {"foods": results, "total_calories": sum(f['calories_kcal'] for f in results)}
```

### Mock 모드

AI 모델이 없거나 로드 실패 시 자동으로 Mock 모드로 전환됩니다.

```python
# Mock 모드 동작
- YOLO: 기본 음식명 반환 ("알 수 없는 음식", confidence=0.5)
- ResNet: Q=1.0 (기준량), ratio=0.85 반환
- 영양 DB: 정상 작동 (Excel 파일만 있으면 됨)
```

### 응답 구조

```python
[
    {
        "food_name": "쌀밥",           # YOLO 탐지
        "bbox": [120, 80, 250, 200],  # [x1, y1, x2, y2]
        "quantity_multiplier": 1.2,    # ResNet 추정 (Q)
        "confidence": 0.88,            # ResNet 신뢰도
        "weight_g": 240.0,             # 100g * 2 * 1.2 = 240g
        "calories_kcal": 312.0,        # 영양 DB * Q
        "carbohydrates_g": 68.4,
        "protein_g": 6.0,
        "fat_g": 1.2,
        "sodium_mg": 2.4,
        "sugars_g": 0.6,
        "success": true,
        "message": "분석 완료"
    },
    {
        "food_name": "김치찌개",
        "bbox": [300, 100, 450, 280],
        "quantity_multiplier": 0.8,
        "confidence": 0.91,
        "weight_g": 200.0,
        "calories_kcal": 120.0,
        "carbohydrates_g": 8.5,
        "protein_g": 10.2,
        "fat_g": 4.8,
        "sodium_mg": 850.0,
        "sugars_g": 2.1,
        "success": true,
        "message": "분석 완료"
    }
]
```

### 영양 DB 구조

`backend/data/nutrition_db.xlsx`:

| 음 식 명 | 중량(g) | 에너지(kcal) | 탄수화물(g) | 단백질(g) | 지방(g) | 나트륨(mg) | 당류(g) |
|---------|--------|------------|-----------|---------|--------|----------|--------|
| 쌀밥 | 200 | 260 | 57.0 | 5.0 | 1.0 | 2.0 | 0.5 |
| 김치찌개 | 250 | 150 | 10.6 | 12.8 | 6.0 | 1062 | 2.6 |
| 삼겹살 | 100 | 331 | 0.0 | 17.2 | 29.0 | 71 | 0.0 |

### 최적화 내역 (2026-01-14)

- ✅ **상세 docstring 추가**
  - 모듈 레벨: Architecture, 모델 정보, 의존성, Example
  - 클래스 레벨: 통합 시스템 설명
- ✅ **주석 개선**: 각 단계별 처리 로직 명확화
- ✅ **Mock 모드 안정성**: 이미 구현된 에러 핸들링 유지

---

## 🔧 서비스 레이어 패턴

### 1. 싱글톤 패턴

**FoodAnalyzer**: AI 모델은 메모리를 많이 사용하므로 싱글톤으로 관리

```python
# food_analyzer.py
_food_analyzer_instance = None

def get_food_analyzer() -> FoodAnalyzer:
    global _food_analyzer_instance
    if _food_analyzer_instance is None:
        _food_analyzer_instance = FoodAnalyzer()
    return _food_analyzer_instance
```

### 2. 클래스 레벨 초기화

**FCMService**: Firebase SDK는 앱당 한 번만 초기화

```python
# fcm_service.py
class FCMService:
    _initialized = False
    
    @classmethod
    def initialize(cls):
        if cls._initialized:
            return
        # Firebase 초기화
        firebase_admin.initialize_app(cred)
        cls._initialized = True
```

### 3. 트랜잭션 데코레이터

**BadgeAutoAward**: DB 트랜잭션 자동 관리

```python
# badge_auto_award.py
@handle_db_transaction
def check_and_award_badges(member_id: int, cursor=None, conn=None):
    # cursor와 conn은 데코레이터가 자동 주입
    # 자동 커밋/롤백 처리
```

### 4. 선택적 의존성

**FCMService, FoodAnalyzer**: 의존성 패키지 미설치 시에도 앱 실행 가능

```python
try:
    import firebase_admin
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False
    print("⚠️ firebase-admin 미설치")
```

---

## 📊 서비스별 의존성

| 서비스 | 필수 패키지 | 선택 패키지 | 외부 자원 |
|--------|-----------|-----------|----------|
| **badge_auto_award** | - | - | DB (MySQL) |
| **fcm_service** | - | firebase-admin | Firebase 프로젝트, 서비스 계정 키 |
| **food_analyzer** | torch, torchvision, pandas, openpyxl, pillow, numpy | ultralytics | AI 모델 파일 (332MB), 영양 DB (Excel) |

### 설치 명령어

```bash
# 필수 의존성
pip install torch torchvision pandas openpyxl pillow numpy

# 선택적 의존성 (기능별 설치)
pip install firebase-admin    # FCM 푸시 알림
pip install ultralytics       # YOLO 음식 분석
```

---

## 🚀 초기화 순서 (main.py)

```python
from fastapi import FastAPI
from services.fcm_service import FCMService
from services.food_analyzer import get_food_analyzer

app = FastAPI()

@app.on_event("startup")
async def startup_event():
    print("🚀 TTM Backend 시작")
    
    # 1. FCM 초기화 (한 번만)
    FCMService.initialize()
    
    # 2. FoodAnalyzer 초기화 (싱글톤)
    analyzer = get_food_analyzer()
    print(f"✅ AI 모델 로드 완료")
    
    print("✅ 모든 서비스 초기화 완료")
```

---

## 📈 성능 고려사항

### FoodAnalyzer
- **메모리**: YOLO (247MB) + ResNet (85MB) = 약 332MB
- **추론 속도**: 
  - GPU: ~0.1초/이미지
  - CPU: ~1-2초/이미지
- **권장**: GPU 환경 (CUDA)

### BadgeAutoAward
- **호출 빈도**: 사용자 활동 시마다 (식단/운동/게시글)
- **DB 쿼리**: 평균 5-8개 쿼리/호출
- **최적화**: 이미 획득한 배지는 건너뛰기

### FCMService
- **비동기 처리**: async/await 사용
- **멀티캐스트**: 최대 500개 토큰/요청 (Firebase 제한)
- **실패 처리**: 개별 토큰 실패 시에도 계속 진행

---

## 📝 변경 이력

### 2026-01-14: Services 폴더 최적화
- **badge_auto_award.py**: @handle_db_transaction 적용, 코드 6줄 감소
- **fcm_service.py**: docstring 대폭 강화, 설정 가이드 추가
- **food_analyzer.py**: Architecture 다이어그램, Example 추가
- **SERVICES_README.md**: 서비스별 상세 문서 생성 (300+ lines)

---

## 📚 참고 자료

- **Firebase Admin SDK**: https://firebase.google.com/docs/admin/setup
- **YOLO v8**: https://docs.ultralytics.com/
- **PyTorch**: https://pytorch.org/docs/stable/index.html
- **TTM Database Schema**: [backend/database/DATABASE.md](../database/DATABASE.md)
- **TTM Routers**: [backend/routers/ROUTERS_README.md](../routers/ROUTERS_README.md)
