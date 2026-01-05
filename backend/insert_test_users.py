import sys
import os
from pathlib import Path

# 현재 파일의 디렉토리를 sys.path에 추가
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from config.database import get_db_connection

# 비밀번호: Test1234!@ (미리 해시된 값)
password = "Test1234!@"
hashed_password = "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5lBjFYVJP3NmW"

test_users = [
    {
        'email': 'test@test.com',
        'member_name': '테스트사용자',
        'phone_number': '010-1234-5678',
        'birth_date': '1990-01-01',
        'gender': 'M'
    },
    {
        'email': 'admin@ttm.com',
        'member_name': '관리자',
        'phone_number': '010-9999-9999',
        'birth_date': '1985-05-15',
        'gender': 'M'
    }
]

def insert_test_users():
    conn = None
    cursor = None
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        for user in test_users:
            # 이메일 중복 체크
            cursor.execute(
                "SELECT member_id FROM members WHERE email = %s",
                (user['email'],)
            )
            existing = cursor.fetchone()
            
            if existing:
                print(f"❌ {user['email']} 계정이 이미 존재합니다.")
                continue
            
            # 사용자 삽입
            cursor.execute(
                """INSERT INTO members (
                    email, password_hash, member_name, phone_number, 
                    birth_date, gender, region, member_status, created_at, terms_agreed
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, 'ACTIVE', NOW(), 1)""",
                (user['email'], hashed_password, user['member_name'], 
                 user['phone_number'], user['birth_date'], user['gender'], '서울')
            )
            conn.commit()
            
            print(f"✅ {user['email']} 계정 생성 완료")
            print(f"   이메일: {user['email']}")
            print(f"   비밀번호: {password}")
            print(f"   이름: {user['member_name']}")
            print()
        
        print("🎉 테스트 계정 생성 완료!")
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        if conn:
            conn.rollback()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    insert_test_users()
