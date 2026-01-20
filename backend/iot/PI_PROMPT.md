# 🚀 IoT 시스템 업데이트 - Pi 적용 가이드

## 📌 업데이트 개요
로컬 서버의 IoT 관련 코드가 업데이트되었습니다. Pi 환경에서 정상 작동하려면 아래 사항을 확인하고 적용해주세요.

---

## 🔧 서버 측 주요 변경사항

### 1. device_id 파라미터 추가 ✅ (2026-01-19)
**변경:** `/api/meals/iot-capture` 엔드포인트에 `device_id` 파라미터 추가

**의미:**
- Pi 스크립트가 자동으로 hostname을 `device_id`로 전송
- 서버 로그에서 어떤 기기에서 촬영했는지 확인 가능
- 선택적 파라미터 (없어도 작동)

### 2. 식사 시간대 분류 로직 수정 ✅
**변경 전:**
- 점심: 11:30~16:30 (16:31부터 SNACK으로 분류되는 버그)

**변경 후:**
- 아침: **06:00~11:00**
- 점심: **11:30~16:59** (16시대 전체 포함)
- 저녁: **17:00~22:30**
- 기타: 간식(SNACK)

**영향:** Pi에서 촬영 시간이 자동으로 위 분류에 따라 아침/점심/저녁에 저장됩니다.

### 3. 연결 상태 타임아웃 단축 ✅
**변경:** 120초 → **30초**

**의미:**
- Pi에서 heartbeat를 30초 이상 보내지 않으면 앱에서 "끊김" 표시
- Pi 종료 후 최대 33초 이내 앱에 반영 (3초 폴링 주기)

### 4. 중복 저장 방지 개선 ✅
**변경:** 409 에러 반환 → 기존 meal_log에 항목 추가

**의미:**
- 같은 날짜, 같은 식사 시간대에 여러 번 촬영 가능
- 각 음식이 별도 항목(meal_item)으로 추가됨

### 5. 처리 상태 API 추가 ✅
**새 엔드포인트:** `GET /api/meals/iot-processing/{member_id}`

**응답 예시:**
```json
{
  "member_id": 1,
  "processing": true,
  "message": "processing"
}
```

**용도:** 앱에서 로딩 UI 표시 ("스마트 글래스에서 정보를 받아오고 있습니다.")

---

## 🚨 중요: CAMERA_MEMBER_ID 설정 필수!

### ⚠️ 가장 흔한 문제
**증상:** Pi에서 사진 찍으면 분석은 되는데 앱에서 안 보임

**원인:** Pi의 `CAMERA_MEMBER_ID`와 앱 로그인 회원 ID가 다름
- Pi가 `CAMERA_MEMBER_ID=1`로 설정되어 있으면 → 회원 1번의 식단에 저장
- 앱이 회원 15번으로 로그인했으면 → 회원 15번 식단에는 안 보임

**해결:** Pi의 `CAMERA_MEMBER_ID`를 앱 로그인 회원 ID와 **반드시 동일하게** 설정!

```bash
# systemd 서비스 파일 수정
sudo nano /etc/systemd/system/camera_touch.service

# 아래 줄을 로그인한 회원 ID로 변경
Environment=CAMERA_MEMBER_ID=15  # ← 앱 로그인 회원 ID (예: 15)

# 저장 후 재시작
sudo systemctl daemon-reload
sudo systemctl restart camera_touch.service
```

### 설정 확인 방법
```bash
# 1. 현재 설정 확인
sudo systemctl show camera_touch.service | grep CAMERA_MEMBER_ID

# 2. 앱에서 로그인한 회원 ID 확인 (서버 로그 참고)
# - 앱 홈 화면 접속 시 서버 로그에 member_id 표시됨

# 3. 일치 확인
# Pi의 CAMERA_MEMBER_ID == 앱 로그인 회원 ID
```

---

## 📋 Pi 환경 필수 체크리스트

### ✅ 체크리스트

#### 1. Pi 스크립트 버전 확인
Pi의 `/home/pi/iot/camera_touch_pi.py` (또는 `camera_touch.py`) 파일이 다음 기능을 지원하는지 확인:

```python
# 필수 환경변수 지원
CAMERA_SERVER_BASE = os.getenv('CAMERA_SERVER_BASE', "http://192.168.219.163:3000")
CAMERA_MEMBER_ID = int(os.getenv('CAMERA_MEMBER_ID', '1'))
USE_HEARTBEAT = os.getenv('USE_HEARTBEAT', 'false').lower() in ('1', 'true', 'yes')
```

**확인 방법:**
```bash
grep "CAMERA_MEMBER_ID" /home/pi/iot/camera_touch_pi.py
```

#### 2. systemd 서비스 설정
`/etc/systemd/system/camera_touch.service` 파일 내용:

```ini
[Unit]
Description=Camera Touch IoT Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/iot
Environment=CAMERA_SERVER_BASE=http://192.168.219.163:3000
Environment=CAMERA_MEMBER_ID=1
Environment=USE_HEARTBEAT=false
ExecStart=/usr/bin/python3 /home/pi/iot/camera_touch_pi.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**⚠️ 중요:** `CAMERA_MEMBER_ID` 값을 **실제 로그인된 회원 ID**로 변경하세요!

예: 회원 ID가 15번이면 → `Environment=CAMERA_MEMBER_ID=15`

#### 3. 서비스 재시작
설정 변경 후 반드시 재시작:

```bash
sudo systemctl daemon-reload
sudo systemctl restart camera_touch.service
sudo systemctl status camera_touch.service
```

#### 4. 로그 확인
정상 동작 확인:

```bash
tail -f /home/pi/iot/camera_touch.log
```

**기대 로그:**
```
>>> System Ready! Press the touch sensor.
[HB] Heartbeat disabled by configuration
[Step 1] Capturing to /home/pi/iot/food_20260119_123456.jpg
[Step 2] Sending photo to AI Server...
[UI] 스마트 글래스에서 정보를 받아오고 있습니다.
Saved Meal ID : 58
[1] 일반비빔밥 | 1054.49 kcal
Waiting for next touch...
```

---

## 🌐 API 엔드포인트 정리

### 사진 업로드 & 분석 & 저장
**엔드포인트:** `POST /api/meals/iot-capture`

**요청 (Form-Data):**
```
file: (이미지 바이너리)
member_id: 1
device_id: raspberrypi
captured_at: 2026-01-19T12:34:56
```

**응답 (성공):**
```json
{
  "success": true,
  "message": "1개 음식 분석 및 저장 완료",
  "foods": [
    {
      "food_name": "일반비빔밥",
      "calories_kcal": 1054.49,
      "carbohydrates_g": 143.53,
      "protein_g": 33.89,
      "fat_g": 37.93,
      "sugars_g": 5.16,
      "sodium_mg": 1851.13
    }
  ],
  "saved_meal_log_id": 57
}
```

### Heartbeat (선택사항)
**엔드포인트:** `POST /api/iot/heartbeat`

**요청 (JSON):**
```json
{
  "member_id": 1,
  "device_id": "raspberrypi",
  "status": "ok",
  "timestamp": "2026-01-19T06:33:54.779160"
}
```

**응답:**
```json
{
  "success": true,
  "member_id": 1,
  "device_id": "raspberrypi",
  "last_seen": "2026-01-19T06:33:54.779160"
}
```

### 연결 상태 조회
**엔드포인트:** `GET /api/iot/status/{member_id}`

**응답:**
```json
{
  "member_id": 1,
  "last_seen": "2026-01-19T06:33:54.779160",
  "seconds_ago": 15.2,
  "connected": true,
  "devices": [...]
}
```

**연결 판정:** `seconds_ago < 30` → connected = true

---

## 🎯 전체 동작 흐름

```
[Pi 터치 센서]
    ↓
[사진 촬영] rpicam-still
    ↓
[POST /api/meals/iot-capture]
    - member_id (환경변수)
    - device_id (hostname)
    - captured_at (현재시간)
    - file (이미지)
    ↓
[서버 AI 분석]
    - YOLO: 음식 탐지
    - ResNet: 양 추정
    - 영양DB: 영양소 계산
    ↓
[DB 저장]
    - 시간대별 자동 분류
    - meal_log + meal_item
    ↓
[앱 반영]
    - 로딩 표시
    - 자동 새로고침
```

---

## 🚨 문제 해결

### 1. 앱에서 404 에러 / 분석은 되는데 저장 안 보임
**증상:** 
- 서버 로그에 "분석 완료" 표시
- Pi 로그에 "Saved Meal ID" 표시
- 하지만 앱에서 식단에 안 보임

**원인:** `CAMERA_MEMBER_ID` ≠ 앱 로그인 회원 ID

**해결:**
```bash
# 1. 앱에서 로그인한 회원 ID 확인 (서버 로그 확인)
# 서버 로그에 "GET /api/iot/status/15" ← 여기서 15가 로그인 회원 ID

# 2. Pi 설정 변경
sudo nano /etc/systemd/system/camera_touch.service
# Environment=CAMERA_MEMBER_ID=15  ← 위에서 확인한 ID로 변경

# 3. 재시작
sudo systemctl daemon-reload
sudo systemctl restart camera_touch.service

# 4. 확인
tail -f /home/pi/iot/camera_touch.log
# "member_id: 15" 로 표시되는지 확인
```

### 2. 연결 상태가 "끊김"
**원인:** Pi 스크립트 미실행 또는 네트워크 문제

**확인:**
```bash
sudo systemctl status camera_touch.service
ping 192.168.219.163
```

### 3. 시간대 분류가 이상함
**원인:** Pi의 시간대 설정 문제

**확인:**
```bash
timedatectl
# Asia/Seoul로 설정되어 있는지 확인
sudo timedatectl set-timezone Asia/Seoul
```

### 4. AI 분석 실패
**원인:** 서버 문제 (모델 로드 실패, 영양DB 문제 등)

**확인:** 로컬 서버 콘솔에서 에러 로그 확인

---

## 📝 핵심 요약

| 항목 | 값 | 비고 |
|------|-----|------|
| 서버 주소 | http://192.168.219.163:3000 | 로컬 네트워크 |
| 업로드 엔드포인트 | POST /api/meals/iot-capture | 필수 |
| Heartbeat 엔드포인트 | POST /api/iot/heartbeat | 선택 (기본 비활성) |
| 연결 타임아웃 | 30초 | 30초 이상 미응답 시 끊김 |
| 아침 시간대 | 06:00~11:00 | 자동 분류 |
| 점심 시간대 | 11:30~16:30 | 자동 분류 |
| 저녁 시간대 | 17:00~22:30 | 자동 분류 |
| 환경변수 | CAMERA_MEMBER_ID | **반드시 설정** |

---

## ✅ 최종 확인

Pi 환경에서 다음을 확인하세요:

```bash
# 1. 서비스 실행 중인지 확인
sudo systemctl status camera_touch.service

# 2. 환경변수 올바른지 확인
sudo systemctl show camera_touch.service -p Environment

# 3. 로그에서 에러 없는지 확인
tail -n 50 /home/pi/iot/camera_touch.log

# 4. 네트워크 연결 확인
ping -c 3 192.168.219.163

# 5. 수동 테스트 (선택)
curl -X POST http://192.168.219.163:3000/api/iot/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"member_id":1,"device_id":"test","status":"ok"}'
```

모든 항목이 정상이면 터치 센서를 눌러 실제 촬영 테스트를 진행하세요!

---

**작성일:** 2026-01-19  
**버전:** v1.0 (최종)  
**문의:** 로그 또는 에러 메시지를 확인 후 서버 담당자에게 전달
