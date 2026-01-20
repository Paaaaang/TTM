from datetime import datetime

def _resolve_meal_type(captured_at: datetime) -> str:
    """식사 시간대별 분류: 아침(06~11시), 점심(11:30~16:30), 저녁(17:00~22:30)"""
    hour = captured_at.hour
    minute = captured_at.minute
    
    # 아침: 06:00 ~ 11:00 (11:00 포함)
    if 6 <= hour < 11 or (hour == 11 and minute == 0):
        return "BREAKFAST"
    # 점심: 11:30 ~ 16:30 (16:30 포함, 16:31~16:59도 포함)
    elif (hour == 11 and minute >= 30) or (12 <= hour <= 16):
        return "LUNCH"
    # 저녁: 17:00 ~ 22:30 (22:30 포함)
    elif 17 <= hour < 22 or (hour == 22 and minute <= 30):
        return "DINNER"
    else:
        return "SNACK"

# 테스트
test_times = [
    "2026-01-19 11:00:00",  # 아침 마지막
    "2026-01-19 11:30:00",  # 점심 시작
    "2026-01-19 16:02:00",  # 점심
    "2026-01-19 16:30:00",  # 점심 마지막
    "2026-01-19 16:31:00",  # 간식?
    "2026-01-19 17:00:00",  # 저녁 시작
    "2026-01-19 22:30:00",  # 저녁 마지막
    "2026-01-19 22:31:00",  # 간식
]

print("=== 시간대별 식사 분류 테스트 ===")
for t in test_times:
    dt = datetime.strptime(t, "%Y-%m-%d %H:%M:%S")
    meal_type = _resolve_meal_type(dt)
    print(f"{dt.strftime('%H:%M')} → {meal_type}")
