from datetime import datetime

def _resolve_meal_type(captured_at: datetime) -> str:
    """식사 시간대별 분류: 아침(06~11시), 점심(11:30~16:30), 저녁(17:00~22:30)"""
    hour = captured_at.hour
    minute = captured_at.minute
    
    # 아침: 06:00 ~ 11:00 (11:00 포함)
    if 6 <= hour < 11 or (hour == 11 and minute == 0):
        return "BREAKFAST"
    # 점심: 11:30 ~ 16:59 (16:30 포함, 16:31~16:59도 포함)
    elif (hour == 11 and minute >= 30) or (12 <= hour <= 16):
        return "LUNCH"
    # 저녁: 17:00 ~ 22:30 (22:30 포함)
    elif 17 <= hour < 22 or (hour == 22 and minute <= 30):
        return "DINNER"
    else:
        return "SNACK"

# 17:04 테스트
test_time = datetime(2026, 1, 19, 17, 4, 42)
result = _resolve_meal_type(test_time)
print(f"17:04:42 → {result}")
print(f"Expected: DINNER")
print(f"Match: {result == 'DINNER'}")

# 추가 테스트
test_cases = [
    (16, 59, "LUNCH"),
    (17, 0, "DINNER"),
    (17, 4, "DINNER"),
    (22, 30, "DINNER"),
    (22, 31, "SNACK"),
]

print("\n=== 경계값 테스트 ===")
for h, m, expected in test_cases:
    dt = datetime(2026, 1, 19, h, m, 0)
    result = _resolve_meal_type(dt)
    status = "✅" if result == expected else "❌"
    print(f"{status} {h:02d}:{m:02d} → {result} (expected: {expected})")
