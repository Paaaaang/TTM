"""
friend_group과 group_member 테이블 생성 스크립트
"""
import sys
sys.path.append('..')

from config.database import get_db_connection

def create_tables():
    """테이블 생성"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # friend_group 테이블 생성
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS friend_group (
              group_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '그룹 ID',
              group_name VARCHAR(50) NOT NULL COMMENT '그룹 이름',
              creator_member_id BIGINT UNSIGNED NOT NULL COMMENT '그룹 생성자 회원 ID',
              created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '그룹 생성일',
              updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '최종 수정일',
              INDEX idx_creator (creator_member_id) COMMENT '생성자별 그룹 조회용',
              FOREIGN KEY (creator_member_id) REFERENCES members(member_id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            COMMENT='친구 그룹 (5개 컬럼, 2026-01-19 추가)'
        """)
        
        print("✅ friend_group 테이블 생성 완료")
        
        # group_member 테이블 생성
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS group_member (
              group_member_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '그룹 멤버 ID',
              group_id BIGINT UNSIGNED NOT NULL COMMENT '그룹 ID (FK → friend_group)',
              member_id BIGINT UNSIGNED NOT NULL COMMENT '회원 ID (FK → members)',
              joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '그룹 가입일',
              UNIQUE KEY unique_group_member (group_id, member_id),
              INDEX idx_group_id (group_id) COMMENT '그룹별 멤버 조회용',
              INDEX idx_member_id (member_id) COMMENT '회원별 그룹 조회용',
              FOREIGN KEY (group_id) REFERENCES friend_group(group_id) ON DELETE CASCADE,
              FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            COMMENT='그룹-멤버 매핑 (4개 컬럼, 2026-01-19 추가)'
        """)
        
        print("✅ group_member 테이블 생성 완료")
        
        conn.commit()
        print("\n✅ 모든 테이블 생성 완료!")
        
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
    create_tables()
