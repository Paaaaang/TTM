import mysql.connector
from mysql.connector import pooling
import os
from dotenv import load_dotenv

load_dotenv()

# MySQL 연결 풀 생성
db_config = {
    "host": os.getenv("DB_HOST", "localhost"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", ""),
    "database": os.getenv("DB_NAME", "ttm_db"),
    "port": int(os.getenv("DB_PORT", 3306))
}

connection_pool = pooling.MySQLConnectionPool(
    pool_name="ttm_pool",
    pool_size=5,
    **db_config
)

def get_db_connection():
    """데이터베이스 연결 가져오기"""
    try:
        connection = connection_pool.get_connection()
        return connection
    except mysql.connector.Error as err:
        print(f"데이터베이스 연결 오류: {err}")
        raise

def test_connection():
    """연결 테스트"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
        conn.close()
        print("✅ MySQL 데이터베이스 연결 성공")
        return True
    except Exception as e:
        print(f"❌ MySQL 데이터베이스 연결 실패: {e}")
        return False

# 앱 시작 시 연결 테스트
test_connection()
