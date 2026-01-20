from config.database import get_db_connection
from datetime import datetime

conn = get_db_connection()
cursor = conn.cursor(dictionary=True)

# 오늘 날짜의 식단 기록 조회
cursor.execute("""
    SELECT 
        ml.meal_log_id, 
        ml.meal_date, 
        ml.meal_type, 
        ml.member_id,
        ml.created_at,
        COUNT(mi.meal_item_id) as item_count
    FROM meal_log ml 
    LEFT JOIN meal_item mi ON ml.meal_log_id = mi.meal_log_id
    WHERE ml.member_id IN (1, 15) 
    AND ml.meal_date = CURDATE()
    GROUP BY ml.meal_log_id
    ORDER BY ml.created_at DESC
""")

rows = cursor.fetchall()
print("\n=== 오늘 식단 기록 ===")
if rows:
    for r in rows:
        print(f"ID:{r['meal_log_id']} | {r['meal_date']} | {r['meal_type']} | member:{r['member_id']} | 항목:{r['item_count']}개 | 등록:{r['created_at']}")
else:
    print("기록 없음")

# 가장 최근 IoT 업로드 확인
cursor.execute("""
    SELECT meal_log_id, meal_date, meal_type, member_id, created_at
    FROM meal_log
    WHERE member_id IN (1, 15)
    ORDER BY created_at DESC
    LIMIT 5
""")
recent = cursor.fetchall()
print("\n=== 최근 5개 식단 기록 ===")
for r in recent:
    print(f"ID:{r['meal_log_id']} | {r['meal_date']} | {r['meal_type']} | member:{r['member_id']} | 등록:{r['created_at']}")

cursor.close()
conn.close()
