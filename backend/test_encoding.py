"""
인코딩 테스트 스크립트
"""
import sys
import mysql.connector
from config.database import db_config

print(f"Python encoding: {sys.getdefaultencoding()}")
print(f"Stdout encoding: {sys.stdout.encoding}")
print(f"DB config charset: {db_config.get('charset', 'NOT SET')}")
print(f"DB config collation: {db_config.get('collation', 'NOT SET')}")
print("-" * 50)

try:
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    
    # 한글 닉네임이 있는 사용자 조회
    cursor.execute("""
        SELECT member_id, email, nickname, profile_image, calorie_goal
        FROM members
        WHERE member_id IN (2, 7, 9, 12, 13)
        ORDER BY member_id
    """)
    
    results = cursor.fetchall()
    
    print(f"\n✅ 조회된 사용자 수: {len(results)}\n")
    for user in results:
        print(f"ID: {user['member_id']}")
        print(f"  Nickname: {user['nickname']}")
        print(f"  Email: {user['email']}")
        print(f"  Type: {type(user['nickname'])}")
        print()
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ 오류: {e}")
