"""
모든 회원을 서로 친구로 추가하는 스크립트
실행: python add_all_friends.py
"""
import sys
sys.path.append('..')

from config.database import get_db_connection

def add_all_friends():
    """모든 회원을 서로 친구로 추가"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # 모든 회원 조회
        cursor.execute("SELECT member_id FROM members WHERE member_status = 'ACTIVE'")
        members = cursor.fetchall()
        member_ids = [m['member_id'] for m in members]
        
        print(f"총 {len(member_ids)}명의 회원을 찾았습니다: {member_ids}")
        
        added_count = 0
        skipped_count = 0
        
        # 각 회원끼리 친구 관계 추가 (양방향)
        for i, member_id in enumerate(member_ids):
            for j, friend_id in enumerate(member_ids):
                if i >= j:  # 자기 자신이거나 이미 처리한 쌍은 건너뜀
                    continue
                
                try:
                    # member_id -> friend_id 방향
                    cursor.execute(
                        """INSERT IGNORE INTO friend (member_id, friend_member_id, status)
                           VALUES (%s, %s, 'ACCEPTED')""",
                        (member_id, friend_id)
                    )
                    
                    # friend_id -> member_id 방향 (양방향)
                    cursor.execute(
                        """INSERT IGNORE INTO friend (member_id, friend_member_id, status)
                           VALUES (%s, %s, 'ACCEPTED')""",
                        (friend_id, member_id)
                    )
                    
                    if cursor.rowcount > 0:
                        added_count += 1
                        print(f"✓ {member_id} ↔ {friend_id} 친구 추가됨")
                    else:
                        skipped_count += 1
                        print(f"- {member_id} ↔ {friend_id} 이미 친구임 (건너뜀)")
                        
                except Exception as e:
                    print(f"✗ {member_id} ↔ {friend_id} 추가 실패: {e}")
        
        conn.commit()
        
        print(f"\n{'='*50}")
        print(f"완료!")
        print(f"- 새로 추가된 친구 관계: {added_count}개")
        print(f"- 이미 존재하는 관계: {skipped_count}개")
        print(f"{'='*50}")
        
    except Exception as e:
        print(f"오류 발생: {e}")
        if conn:
            conn.rollback()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

if __name__ == "__main__":
    print("모든 회원을 친구로 추가합니다...")
    add_all_friends()
