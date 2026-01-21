"""배지 자동 획득 체크 및 부여 로직"""
from datetime import datetime, timedelta, date
from typing import List, Dict
from config.database import get_db_connection
from utils.common import handle_db_transaction

class BadgeAutoAward:
    """배지 자동 획득 시스템"""
    
    @staticmethod
    @handle_db_transaction
    async def check_and_award_badges(member_id: int, cursor=None, conn=None) -> List[Dict]:
        """
        회원의 활동을 체크하고 획득 가능한 배지를 자동으로 부여
        
        Args:
            member_id: 회원 ID
            cursor: DB 커서 (데코레이터가 자동 주입)
            conn: DB 연결 (데코레이터가 자동 주입)
        
        Returns:
            새로 획득한 배지 목록
        """
        newly_earned = []
        
        # 이미 획득한 배지 조회
        cursor.execute("""
            SELECT badge_id FROM member_badge 
            WHERE member_id = %s
        """, (member_id,))
        earned_badge_ids = {row['badge_id'] for row in cursor.fetchall()}
        
        # 각 배지 조건 체크
        badges_to_check = [
            (1, BadgeAutoAward._check_first_meal),     # 첫 걸음
            (2, BadgeAutoAward._check_10_exercises),   # 운동 초보
            (3, BadgeAutoAward._check_7_day_streak),   # 꾸준함
            (4, BadgeAutoAward._check_30_day_streak),  # 건강 마스터
            (5, BadgeAutoAward._check_perfect_day),    # 완벽한 하루
            (6, BadgeAutoAward._check_100_exercises),  # 운동왕
            (7, BadgeAutoAward._check_30_breakfasts),  # 아침형
            (8, BadgeAutoAward._check_no_late_snack),  # 채식 러버 (야식 킬러)
            (9, BadgeAutoAward._check_50_calorie_goals), # 칼로리왕
            (13, BadgeAutoAward._check_50_posts),      # 별 (소셜 스타)
            (14, BadgeAutoAward._check_500_likes),     # 리액션 (인기인)
        ]
        
        for badge_id, check_func in badges_to_check:
            # 이미 획득한 배지는 건너뛰기
            if badge_id in earned_badge_ids:
                continue
                
            # 조건 체크
            if check_func(cursor, member_id):
                # 배지 부여
                cursor.execute("""
                    INSERT INTO member_badge (member_id, badge_id, acquired_at)
                    VALUES (%s, %s, NOW())
                """, (member_id, badge_id))
                
                # 배지 정보 조회
                cursor.execute("""
                    SELECT badge_id, badge_name, description, icon_path
                    FROM badge WHERE badge_id = %s
                """, (badge_id,))
                badge_info = cursor.fetchone()
                newly_earned.append(badge_info)
        
        return newly_earned
    
    # 개별 배지 조건 체크 함수들
    
    @staticmethod
    def _check_first_meal(cursor, member_id: int) -> bool:
        """첫 걸음: 첫 번째 식단 기록"""
        cursor.execute(
            """
            SELECT COUNT(*) AS count
            FROM meal_log
            WHERE member_id = %s
            """,
            (member_id,),
        )
        return cursor.fetchone()['count'] >= 1
    
    @staticmethod
    def _check_10_exercises(cursor, member_id: int) -> bool:
        """운동 초보: 운동 10회 달성"""
        cursor.execute(
            """
            SELECT COUNT(*) AS count
            FROM exercise_log
            WHERE member_id = %s
            """,
            (member_id,),
        )
        return cursor.fetchone()['count'] >= 10
    
    @staticmethod
    def _check_7_day_streak(cursor, member_id: int) -> bool:
        """꾸준함: 7일 연속 기록"""
        cursor.execute(
            """
            SELECT activity_date
            FROM (
                SELECT DISTINCT meal_date AS activity_date
                FROM meal_log
                WHERE member_id = %s
                UNION
                SELECT DISTINCT exercise_date AS activity_date
                FROM exercise_log
                WHERE member_id = %s
            ) AS activities
            ORDER BY activity_date DESC
            LIMIT 7
            """,
            (member_id, member_id),
        )

        raw_dates = [row['activity_date'] for row in cursor.fetchall()]
        dates = [d if isinstance(d, date) else d.date() for d in raw_dates]
        if len(dates) < 7:
            return False
        
        # 연속 7일 체크
        for i in range(len(dates) - 1):
            if (dates[i] - dates[i+1]).days != 1:
                return False
        return True
    
    @staticmethod
    def _check_30_day_streak(cursor, member_id: int) -> bool:
        """건강 마스터: 30일 연속 기록"""
        cursor.execute(
            """
            SELECT activity_date
            FROM (
                SELECT DISTINCT meal_date AS activity_date
                FROM meal_log
                WHERE member_id = %s
                UNION
                SELECT DISTINCT exercise_date AS activity_date
                FROM exercise_log
                WHERE member_id = %s
            ) AS activities
            ORDER BY activity_date DESC
            LIMIT 30
            """,
            (member_id, member_id),
        )

        raw_dates = [row['activity_date'] for row in cursor.fetchall()]
        dates = [d if isinstance(d, date) else d.date() for d in raw_dates]
        if len(dates) < 30:
            return False
        
        # 연속 30일 체크
        for i in range(len(dates) - 1):
            if (dates[i] - dates[i+1]).days != 1:
                return False
        return True
    
    @staticmethod
    def _check_perfect_day(cursor, member_id: int) -> bool:
        """완벽한 하루: 칼로리 + 운동 목표 달성"""
        # 오늘 날짜
        today = datetime.now().date()
        
        # 목표 칼로리 조회
        cursor.execute("""
            SELECT calorie_goal FROM members WHERE member_id = %s
        """, (member_id,))
        result = cursor.fetchone()
        if not result:
            return False
        calorie_goal = result['calorie_goal'] or 2000
        
        # 오늘 식단 칼로리 합계
        cursor.execute(
            """
            SELECT COALESCE(SUM(mi.calories_kcal), 0) AS total_calories
            FROM meal_log ml
            LEFT JOIN meal_item mi ON ml.meal_log_id = mi.meal_log_id
            WHERE ml.member_id = %s AND ml.meal_date = %s
            """,
            (member_id, today),
        )
        meal_result = cursor.fetchone()
        total_calories = float(meal_result['total_calories'] or 0)

        # 오늘 운동 기록 있는지
        cursor.execute(
            """
            SELECT COUNT(*) AS count
            FROM exercise_log
            WHERE member_id = %s AND exercise_date = %s
            """,
            (member_id, today),
        )
        exercise_count = cursor.fetchone()['count']
        
        return abs(total_calories - calorie_goal) <= 200 and exercise_count > 0
    
    @staticmethod
    def _check_100_exercises(cursor, member_id: int) -> bool:
        """운동왕: 운동 100회 달성"""
        cursor.execute(
            """
            SELECT COUNT(*) AS count
            FROM exercise_log
            WHERE member_id = %s
            """,
            (member_id,),
        )
        return cursor.fetchone()['count'] >= 100
    
    @staticmethod
    def _check_30_breakfasts(cursor, member_id: int) -> bool:
        """아침형: 아침 식단 30회 기록"""
        cursor.execute(
            """
            SELECT COUNT(*) AS count
            FROM meal_log
            WHERE member_id = %s AND meal_type = 'BREAKFAST'
            """,
            (member_id,),
        )
        return cursor.fetchone()['count'] >= 30
    
    @staticmethod
    def _check_no_late_snack(cursor, member_id: int) -> bool:
        """채식 러버 (야식 킬러): 14일 동안 저녁 9시 이후 음식 기록 없음"""
        two_weeks_ago = datetime.now() - timedelta(days=14)

        cursor.execute(
            """
            SELECT COUNT(*) AS count
            FROM meal_log
            WHERE member_id = %s
              AND created_at >= %s
              AND HOUR(created_at) >= 21
            """,
            (member_id, two_weeks_ago),
        )

        return cursor.fetchone()['count'] == 0
    
    @staticmethod
    def _check_50_calorie_goals(cursor, member_id: int) -> bool:
        """칼로리왕: 50일 동안 칼로리 목표 달성"""
        cursor.execute("""
            SELECT calorie_goal FROM members WHERE member_id = %s
        """, (member_id,))
        result = cursor.fetchone()
        if not result:
            return False
        calorie_goal = result['calorie_goal'] or 2000
        
        cursor.execute(
            """
            SELECT ml.meal_date AS meal_date,
                   COALESCE(SUM(mi.calories_kcal), 0) AS total_calories
            FROM meal_log ml
            LEFT JOIN meal_item mi ON ml.meal_log_id = mi.meal_log_id
            WHERE ml.member_id = %s
            GROUP BY ml.meal_date
            HAVING ABS(COALESCE(SUM(mi.calories_kcal), 0) - %s) <= 200
            """,
            (member_id, calorie_goal),
        )

        qualifying_days = cursor.fetchall()
        return len(qualifying_days) >= 50
    
    @staticmethod
    def _check_50_posts(cursor, member_id: int) -> bool:
        """별 (소셜 스타): 커뮤니티 글 50개 작성"""
        cursor.execute("""
            SELECT COUNT(*) as count FROM post 
            WHERE member_id = %s
        """, (member_id,))
        return cursor.fetchone()['count'] >= 50
    
    @staticmethod
    def _check_500_likes(cursor, member_id: int) -> bool:
        """리액션 (인기인): 좋아요 500개 받기"""
        cursor.execute("""
            SELECT SUM(p.likes_count) as total_likes
            FROM post p
            WHERE p.member_id = %s
        """, (member_id,))
        result = cursor.fetchone()
        total_likes = result['total_likes'] or 0
        return total_likes >= 500
