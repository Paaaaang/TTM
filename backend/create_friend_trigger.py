"""
friend 관계 검증 트리거 추가 스크립트
group_member에 멤버 추가 시 friend 관계 확인
"""
import sys
sys.path.append('..')

from config.database import get_db_connection

def create_trigger():
    """트리거 생성"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 기존 트리거 삭제 (있다면)
        cursor.execute("DROP TRIGGER IF EXISTS check_friend_before_add_group_member")
        
        # 트리거 생성: group_member INSERT 전에 friend 관계 확인
        trigger_sql = """
        CREATE TRIGGER check_friend_before_add_group_member
        BEFORE INSERT ON group_member
        FOR EACH ROW
        BEGIN
            DECLARE creator_id BIGINT;
            DECLARE is_friend INT;
            
            -- 그룹 생성자 ID 가져오기
            SELECT creator_member_id INTO creator_id
            FROM friend_group
            WHERE group_id = NEW.group_id;
            
            -- 생성자 본인이면 통과
            IF NEW.member_id = creator_id THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'OK';
            END IF;
            
            -- 생성자의 친구인지 확인
            SELECT COUNT(*) INTO is_friend
            FROM friend
            WHERE member_id = creator_id 
              AND friend_member_id = NEW.member_id 
              AND status = 'ACCEPTED';
            
            -- 친구가 아니면 에러
            IF is_friend = 0 THEN
                SIGNAL SQLSTATE '45000' 
                SET MESSAGE_TEXT = 'Can only add friends to the group';
            END IF;
        END
        """
        
        cursor.execute(trigger_sql)
        conn.commit()
        
        print("✅ 트리거 생성 완료: check_friend_before_add_group_member")
        print("   - group_member INSERT 시 friend 관계 검증")
        print("   - 그룹 생성자의 친구만 추가 가능")
        
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
    create_trigger()
