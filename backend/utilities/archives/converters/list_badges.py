"""DB 배지 목록 확인"""
from config.database import get_db_connection

conn = get_db_connection()
cursor = conn.cursor(dictionary=True)

cursor.execute('SELECT badge_id, badge_name, description FROM badge ORDER BY badge_id')
print("DB에 저장된 배지 목록:")
print("=" * 80)
for row in cursor.fetchall():
    print(f"[{row['badge_id']}] {row['badge_name']}: {row['description']}")

cursor.close()
conn.close()
