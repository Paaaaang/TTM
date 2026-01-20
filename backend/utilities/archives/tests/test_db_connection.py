"""
DB 연결 및 meal 테이블 확인 스크립트
"""
import mysql.connector
from datetime import datetime

# DB 연결 설정 (.env 파일의 실제 설정 사용)
db_config = {
    "host": "project-db-campus.smhrd.com",
    "user": "we0123",
    "password": "cand4567",
    "database": "we0123",
    "port": 3307
}

try:
    print("=" * 60)
    print("DB 연결 테스트 시작")
    print("=" * 60)
    
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    
    print("\n✅ DB 연결 성공!")
    
    # 1. meal_log 테이블 구조 확인
    print("\n[1] meal_log 테이블 구조:")
    print("-" * 60)
    cursor.execute("DESCRIBE meal_log")
    for col in cursor.fetchall():
        print(f"  {col['Field']:20s} | {col['Type']:20s} | Null: {col['Null']:3s} | Key: {col['Key']:3s}")
    
    # 2. meal_item 테이블 구조 확인
    print("\n[2] meal_item 테이블 구조:")
    print("-" * 60)
    cursor.execute("DESCRIBE meal_item")
    for col in cursor.fetchall():
        print(f"  {col['Field']:20s} | {col['Type']:20s} | Null: {col['Null']:3s} | Key: {col['Key']:3s}")
    
    # 3. members 테이블에서 테스트용 member_id 확인
    print("\n[3] 테스트용 회원 조회:")
    print("-" * 60)
    cursor.execute("SELECT member_id, login_id, nickname FROM members LIMIT 5")
    members = cursor.fetchall()
    if members:
        for member in members:
            print(f"  ID: {member['member_id']}, Login: {member['login_id']}, Nickname: {member['nickname']}")
        test_member_id = members[0]['member_id']
    else:
        print("  ⚠️ 회원 데이터가 없습니다!")
        test_member_id = None
    
    # 4. meal_log 데이터 개수 확인
    print("\n[4] meal_log 레코드 개수:")
    print("-" * 60)
    cursor.execute("SELECT COUNT(*) as cnt FROM meal_log")
    result = cursor.fetchone()
    print(f"  총 {result['cnt']}개의 식사 기록")
    
    # 5. meal_item 데이터 개수 확인
    print("\n[5] meal_item 레코드 개수:")
    print("-" * 60)
    cursor.execute("SELECT COUNT(*) as cnt FROM meal_item")
    result = cursor.fetchone()
    print(f"  총 {result['cnt']}개의 식사 항목")
    
    # 6. 테스트 데이터 삽입 시도
    if test_member_id:
        print(f"\n[6] 테스트 데이터 삽입 시도 (member_id={test_member_id}):")
        print("-" * 60)
        
        try:
            # meal_log 삽입
            cursor.execute(
                """INSERT INTO meal_log (meal_date, meal_type, memo, member_id, created_at) 
                   VALUES (CURDATE(), 'BREAKFAST', 'DB 연결 테스트', %s, NOW())""",
                (test_member_id,)
            )
            meal_log_id = cursor.lastrowid
            print(f"  ✅ meal_log 삽입 성공 (meal_log_id={meal_log_id})")
            
            # meal_item 삽입
            cursor.execute(
                """INSERT INTO meal_item 
                   (meal_log_id, food_name, estimated_portion_size, calories_kcal, 
                    carbohydrates_g, protein_g, fat_g, created_at)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())""",
                (meal_log_id, "테스트 음식", None, 100.0, 20.0, 10.0, 5.0)
            )
            meal_item_id = cursor.lastrowid
            print(f"  ✅ meal_item 삽입 성공 (meal_item_id={meal_item_id})")
            
            # 삽입된 데이터 조회
            cursor.execute(
                """SELECT ml.*, mi.food_name, mi.calories_kcal 
                   FROM meal_log ml 
                   LEFT JOIN meal_item mi ON ml.meal_log_id = mi.meal_log_id
                   WHERE ml.meal_log_id = %s""",
                (meal_log_id,)
            )
            inserted = cursor.fetchone()
            print(f"\n  삽입된 데이터:")
            print(f"    meal_log_id: {inserted['meal_log_id']}")
            print(f"    meal_date: {inserted['meal_date']}")
            print(f"    meal_type: {inserted['meal_type']}")
            print(f"    food_name: {inserted['food_name']}")
            print(f"    calories_kcal: {inserted['calories_kcal']}")
            
            # 테스트 데이터 삭제
            cursor.execute("DELETE FROM meal_item WHERE meal_log_id = %s", (meal_log_id,))
            cursor.execute("DELETE FROM meal_log WHERE meal_log_id = %s", (meal_log_id,))
            print(f"\n  🗑️ 테스트 데이터 삭제 완료")
            
            conn.commit()
            
        except Exception as e:
            print(f"  ❌ 테스트 데이터 삽입 실패: {e}")
            conn.rollback()
    
    print("\n" + "=" * 60)
    print("DB 연결 테스트 완료!")
    print("=" * 60)
    
except mysql.connector.Error as err:
    print(f"\n❌ DB 연결 오류: {err}")
    print(f"   - Host: {db_config['host']}")
    print(f"   - User: {db_config['user']}")
    print(f"   - Database: {db_config['database']}")
    print(f"   - Port: {db_config['port']}")
    
except Exception as e:
    print(f"\n❌ 예상치 못한 오류: {e}")
    import traceback
    traceback.print_exc()
    
finally:
    if 'cursor' in locals() and cursor:
        cursor.close()
    if 'conn' in locals() and conn:
        conn.close()
        print("\n🔒 DB 연결 종료")
