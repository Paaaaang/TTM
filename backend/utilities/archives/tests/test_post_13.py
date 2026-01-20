"""게시글 13번 조회 테스트"""
from config.database import get_db_connection

conn = get_db_connection()
cursor = conn.cursor(dictionary=True)

print("=" * 60)
print("게시글 13번 데이터 조회")
print("=" * 60)

# 게시글 기본 정보
cursor.execute("""
    SELECT 
        p.post_id,
        p.member_id,
        m.nickname as author_nickname,
        p.category,
        p.title,
        p.content,
        p.likes_count,
        p.view_count,
        p.created_at
    FROM post p
    LEFT JOIN members m ON p.member_id = m.member_id
    WHERE p.post_id = 13
""")
post = cursor.fetchone()

if post:
    print("게시글 정보:")
    for key, value in post.items():
        print(f"  {key}: {value}")
else:
    print("게시글 13을 찾을 수 없습니다")

# 게시글 이미지
print("\n게시글 이미지:")
cursor.execute("""
    SELECT post_image_id, post_id, image_path, image_order
    FROM post_image
    WHERE post_id = 13
    ORDER BY image_order
""")
images = cursor.fetchall()
if images:
    for img in images:
        print(f"  - {img}")
else:
    print("  이미지 없음")

# 좋아요 데이터
print("\n좋아요 데이터:")
cursor.execute("""
    SELECT COUNT(*) as total_likes
    FROM post_like
    WHERE post_id = 13
""")
likes = cursor.fetchone()
print(f"  총 좋아요 수: {likes['total_likes']}")

cursor.execute("""
    SELECT pl.like_id, pl.member_id, m.nickname
    FROM post_like pl
    LEFT JOIN members m ON pl.member_id = m.member_id
    WHERE pl.post_id = 13
    LIMIT 5
""")
like_users = cursor.fetchall()
print(f"  좋아요 누른 사용자 (최대 5명):")
for user in like_users:
    print(f"    - {user}")

# member_id=4의 좋아요 여부
cursor.execute("""
    SELECT COUNT(*) as count
    FROM post_like
    WHERE post_id = 13 AND member_id = 4
""")
result = cursor.fetchone()
print(f"\nmember_id=4의 좋아요 여부: {'좋아요 함' if result['count'] > 0 else '좋아요 안함'}")

cursor.close()
conn.close()
