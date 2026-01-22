# 🔧 IoT 연결 상태 "끊김" 표시 문제 해결

## 📊 현재 상황

### ✅ 완료된 작업

- **아이콘 변경**: Material Icons → SVG 아이콘
  - 연결: `cloud_done_rounded.svg`
  - 끊김: `cloud_off_rounded.svg`
- **디버깅 로그 추가**: IoT 상태 확인 시 상세 로그 출력

### ❌ 문제 상황

```bash
# 현재 서버 상태 확인 결과
curl "https://ttm-syzk.onrender.com/api/iot/status/15"
# 결과: connected: False, seconds_ago: 155105 (약 43시간 전)
```

**원인**: 라즈베리파이가 member_id 15로 Render 서버에 heartbeat를 보내지 않고 있음

---

## 🎯 해결 방법

### 1️⃣ 라즈베리파이 서버 설정 확인

SSH로 라즈베리파이에 접속하여 다음을 확인:

```bash
# 1. 서비스 설정 확인
sudo cat /etc/systemd/system/camera_touch.service
```

**올바른 설정**:

```ini
[Service]
Environment=CAMERA_SERVER_BASE=https://ttm-syzk.onrender.com
Environment=CAMERA_MEMBER_ID=15
Environment=USE_HEARTBEAT=true  # ← 중요! true로 설정
```

**현재 설정이 다를 경우**:

```bash
# 2. 서비스 파일 수정
sudo nano /etc/systemd/system/camera_touch.service

# 3가지 환경변수를 위처럼 수정 후 저장 (Ctrl+O, Enter, Ctrl+X)

# 3. 서비스 재시작
sudo systemctl daemon-reload
sudo systemctl restart camera_touch.service

# 4. 상태 확인
sudo systemctl status camera_touch.service

# 5. 로그 확인
tail -f /home/pi/iot/camera_touch.log
```

### 2️⃣ Heartbeat 동작 확인

**기대 로그**:

```
[HB] Heartbeat sent successfully
[HB] Heartbeat sent successfully
...
```

**만약 비활성화되어 있다면**:

```
[HB] Heartbeat disabled by configuration
```

→ `USE_HEARTBEAT=true`로 변경 필요

### 3️⃣ 앱에서 연결 상태 확인

앱 실행 후 콘솔에서 다음 로그 확인:

```
📡 [IoT] Member 15 - 연결: true, 마지막: 2026-01-22T16:30:00
🔍 [IoT Status] Member 15: true, Last: 2026-01-22T16:30:00
```

- `연결: true` → 정상 연결
- `연결: false` → 30초 이상 heartbeat 없음

---

## 🧪 테스트 방법

### 단계별 테스트

1. **라즈베리파이 설정 변경 및 재시작**

   ```bash
   sudo systemctl restart camera_touch.service
   ```

2. **10초 후 서버 상태 확인**

   ```bash
   curl "https://ttm-syzk.onrender.com/api/iot/status/15" | python3 -m json.tool
   ```

   → `"connected": true` 확인

3. **앱에서 확인**
   - 앱 상단의 "TAB TO ME" 옆 아이콘 확인
   - ☁️ (cloud_done) = 연결됨
   - ☁️❌ (cloud_off) = 끊김

---

## 🔍 추가 디버깅

### 라즈베리파이 로그 실시간 모니터링

```bash
# 터미널 1: 서비스 로그
tail -f /home/pi/iot/camera_touch.log

# 터미널 2: systemd 로그
sudo journalctl -u camera_touch.service -f
```

### 서버 API 직접 테스트

```bash
# member_id 15의 상태 확인
curl "https://ttm-syzk.onrender.com/api/iot/status/15" | python3 -m json.tool

# member_id 1의 상태 확인 (비교용)
curl "https://ttm-syzk.onrender.com/api/iot/status/1" | python3 -m json.tool
```

---

## ✨ 변경사항 요약

### 프론트엔드 (이미 적용 완료)

1. **아이콘 변경**
   - `Icons.cloud_done_rounded` → `SvgPicture.asset('icons_ui/cloud_done_rounded.svg')`
   - `Icons.cloud_off_rounded` → `SvgPicture.asset('icons_ui/cloud_off_rounded.svg')`

2. **디버깅 로그 추가**
   - `home_screen.dart`: IoT 상태 체크 시 상세 정보 출력
   - `iot_service.dart`: API 응답 데이터 출력

### 라즈베리파이 (설정 필요)

```ini
Environment=CAMERA_SERVER_BASE=https://ttm-syzk.onrender.com
Environment=CAMERA_MEMBER_ID=15
Environment=USE_HEARTBEAT=true
```

---

## 📞 문제 지속 시

1. **라즈베리파이 Python 스크립트 확인**

   ```bash
   cat /home/pi/iot/camera_touch_pi.py | grep -A 10 "heartbeat"
   ```

2. **네트워크 연결 확인**

   ```bash
   ping -c 3 ttm-syzk.onrender.com
   ```

3. **수동 heartbeat 테스트**
   ```bash
   curl -X POST "https://ttm-syzk.onrender.com/api/iot/heartbeat" \
     -H "Content-Type: application/json" \
     -d '{"member_id": 15, "device_id": "raspberrypi", "status": "ok"}'
   ```
