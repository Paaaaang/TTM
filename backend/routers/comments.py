from fastapi import APIRouter, HTTPException, Query, Body
from pydantic import BaseModel, Field
from typing import List, Optional
from config.database import get_db_connection
from services.fcm_service import FCMService

router = APIRouter()

# --- Models ---

class CommentCreate(BaseModel):
    memberId: int = Field(..., description="작성자 member_id")
    content: str = Field(..., description="댓글 내용")
    parentCommentId: Optional[int] = Field(None, description="대댓글일 경우 부모 댓글 ID")

class CommentResponse(BaseModel):
    commentId: int
    postId: int
    memberId: int
    parentCommentId: Optional[int]
    content: str
    authorNickname: str
    authorProfileImage: Optional[str]
    likeCount: int
    isLiked: bool
    createdAt: str
    replies: List['CommentResponse'] = []

class CommentUpdate(BaseModel):
    content: str

# --- Endpoints ---

# 1. 댓글 목록 조회 (유튜브 스타일: 부모 댓글 + 대댓글 구조)
@router.get("/api/posts/{post_id}/comments", response_model=List[CommentResponse])
async def get_comments(
    post_id: int,
    current_member_id: Optional[int] = Query(None, description="현재 로그인한 사용자 ID (좋아요 여부 확인용)")
):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 댓글 조회 (작성자 정보 포함) - 탈퇴한 회원도 조회하기 위해 LEFT JOIN 사용
        query = """
            SELECT 
                c.comment_id, c.post_id, c.member_id, c.parent_comment_id, 
                c.content, c.like_count, c.created_at, c.deleted_at,
                m.nickname, m.profile_image, m.member_status, m.deleted_at as member_deleted_at,
                CASE WHEN cl.comment_like_id IS NOT NULL THEN 1 ELSE 0 END as is_liked
            FROM post_comment c
            LEFT JOIN members m ON c.member_id = m.member_id
            LEFT JOIN post_comment_like cl ON c.comment_id = cl.comment_id AND cl.member_id = %s
            WHERE c.post_id = %s
            ORDER BY c.parent_comment_id IS NULL DESC, c.created_at ASC
        """
        cursor.execute(query, (current_member_id, post_id))
        rows = cursor.fetchall()
        
        # 댓글 맵핑 및 계층 구조 생성
        comment_map = {}
        roots = []
        
        # 3. 댓글 맵핑 및 계층 구조 생성 (전체 순회)
        all_comments = []

        for row in rows:
            # 1. 탈퇴한 회원 처리
            # member_id가 없거나(Hard delete 된 경우), status가 DELETED거나, deleted_at이 있는 경우
            nickname = row['nickname']
            profile_image = row['profile_image']
            
            is_withdrawn = (
                row['member_id'] is None or 
                row['member_status'] == 'DELETED' or 
                row['member_deleted_at'] is not None
            )
            
            if is_withdrawn:
                nickname = "알수없음"
                profile_image = None # 혹은 기본 이미지를 줄 수도 있음

            # 2. 삭제된 댓글 처리 (삭제되었지만 대댓글이 있는 경우 "삭제된 댓글입니다" 표시)
            content = row['content']
            if row['deleted_at']:
                content = "삭제된 댓글입니다."
            
            comment = CommentResponse(
                commentId=row['comment_id'],
                postId=row['post_id'],
                memberId=row['member_id'] if row['member_id'] else 0, # 탈퇴시 0 또는 유지
                parentCommentId=row['parent_comment_id'],
                content=content,
                authorNickname=nickname if nickname else "알수없음",
                authorProfileImage=profile_image,
                likeCount=row['like_count'],
                isLiked=bool(row['is_liked']),
                createdAt=row['created_at'].strftime("%Y-%m-%d %H:%M:%S") if row['created_at'] else "",
                replies=[]
            )
            
            # comment_map에 저장
            # (Note: 이전 코드의 comment_map 로직을 단순화하여 2-pass 방식으로 변경)
            all_comments.append(comment)

        # Map 생성
        comment_map_v2 = {c.commentId: c for c in all_comments}
        root_comments = []

        # 트리 구조 연결
        for comment in all_comments:
            if comment.parentCommentId:
                if comment.parentCommentId in comment_map_v2:
                    comment_map_v2[comment.parentCommentId].replies.append(comment)
                # 부모가 없으면(삭제됨?) root로 취급하거나 버림. 여기선 일단 root로 보이지 않게 처리될 것임.
            else:
                root_comments.append(comment)
                 
        return root_comments

    except Exception as e:
        print(f"Error fetching comments: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

# 2. 댓글 작성
@router.post("/api/posts/{post_id}/comments")
async def create_comment(post_id: int, comment: CommentCreate):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 게시글 존재 확인
        cursor.execute("SELECT post_id FROM post WHERE post_id = %s", (post_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다")
            
        # 댓글 저장
        query = """
            INSERT INTO post_comment (post_id, member_id, parent_comment_id, content)
            VALUES (%s, %s, %s, %s)
        """
        cursor.execute(query, (post_id, comment.memberId, comment.parentCommentId, comment.content))
        
        # 게시글 댓글 수 업데이트 (trigger가 없다면 수동 업데이트)
        # post 테이블에 comments_count 컬럼이 있다고 가정했으나, 실제로는 없어서 500 에러 발생하므로 주석 처리함.
        # 필요시 ALTER TABLE로 컬럼 추가 후 주석 해제.
        # cursor.execute("UPDATE post SET comments_count = comments_count + 1 WHERE post_id = %s", (post_id,))
        
        # ID 조회 (commit 전에도 lastrowid는 유효함, 하지만 안전하게 바로 확보)
        new_comment_id = cursor.lastrowid
        print(f"DEBUG: New comment inserted. ID: {new_comment_id}")

        conn.commit()
        
        # 생성된 댓글 조회 (frontend에서 바로 표시하기 위해)
        # new_comment_id = cursor.lastrowid # 이동함
        
        select_query = """
            SELECT 
                c.comment_id, c.post_id, c.member_id, c.parent_comment_id, 
                c.content, c.like_count, c.created_at, 
                m.nickname, m.profile_image
            FROM post_comment c
            JOIN members m ON c.member_id = m.member_id
            WHERE c.comment_id = %s
        """
        cursor.execute(select_query, (new_comment_id,))
        row = cursor.fetchone()
        
        if not row:
             raise HTTPException(status_code=500, detail="댓글이 등록되었으나 로드에 실패했습니다.")
        
        # 🔔 알림 전송: 게시글 작성자에게 댓글 알림
        try:
            # 게시글 작성자 정보 조회
            cursor.execute("""
                SELECT p.member_id, m.fcm_token, m.nickname as post_author_nickname
                FROM post p
                JOIN members m ON p.member_id = m.member_id
                WHERE p.post_id = %s
            """, (post_id,))
            post_author = cursor.fetchone()
            
            # 자기 게시글에 자기가 댓글 단 경우 제외
            if post_author and post_author['member_id'] != comment.memberId:
                if post_author.get('fcm_token'):
                    is_reply = comment.parentCommentId is not None
                    await FCMService.send_comment_notification(
                        fcm_token=post_author['fcm_token'],
                        commenter_name=row['nickname'],
                        post_id=post_id,
                        is_reply=is_reply
                    )
                    print(f"🔔 댓글 알림 전송 완료: {row['nickname']} -> {post_author['post_author_nickname']}")
        except Exception as e:
            print(f"⚠️ 알림 전송 실패 (댓글): {e}")

        # CommentResponse 형식으로 반환
        return {
            "commentId": row['comment_id'],
            "postId": row['post_id'],
            "memberId": row['member_id'],
            "parentCommentId": row['parent_comment_id'],
            "content": row['content'],
            "authorNickname": row['nickname'],
            "authorProfileImage": row['profile_image'],
            "likeCount": row['like_count'] if row['like_count'] is not None else 0,
            "isLiked": False,
            "createdAt": row['created_at'].strftime("%Y-%m-%d %H:%M:%S") if row['created_at'] else "",
            "replies": []
        }
        
    except Exception as e:
        conn.rollback()
        print(f"Error creating comment: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

# 3. 댓글 좋아요/취소
@router.post("/api/comments/{comment_id}/like")
async def toggle_comment_like(
    comment_id: int, 
    member_id: int = Body(..., embed=True, alias="memberId") # JSON body: { "memberId": 123 }
):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # 이미 좋아요 했는지 확인
        cursor.execute(
            "SELECT comment_like_id FROM post_comment_like WHERE comment_id = %s AND member_id = %s",
            (comment_id, member_id)
        )
        existing_like = cursor.fetchone()
        
        if existing_like:
            # 좋아요 취소
            cursor.execute(
                "DELETE FROM post_comment_like WHERE comment_id = %s AND member_id = %s",
                (comment_id, member_id)
            )
            cursor.execute(
                "UPDATE post_comment SET like_count = like_count - 1 WHERE comment_id = %s",
                (comment_id,)
            )
            message = "좋아요 취소"
            liked = False
        else:
            # 좋아요 등록
            cursor.execute(
                "INSERT INTO post_comment_like (comment_id, member_id) VALUES (%s, %s)",
                (comment_id, member_id)
            )
            cursor.execute(
                "UPDATE post_comment SET like_count = like_count + 1 WHERE comment_id = %s",
                (comment_id,)
            )
            message = "좋아요 등록"
            liked = True
            
        conn.commit()
        
        # 변경된 좋아요 수 조회
        cursor.execute("SELECT like_count FROM post_comment WHERE comment_id = %s", (comment_id,))
        result = cursor.fetchone()
        new_count = result[0] if result else 0
        
        return {"message": message, "isLiked": liked, "likeCount": new_count}
        
    except Exception as e:
        conn.rollback()
        print(f"Error toggling comment like: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()

# 4. 댓글 삭제
@router.delete("/api/comments/{comment_id}")
async def delete_comment(comment_id: int, member_id: int = Query(..., alias="memberId")):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 댓글 확인
        cursor.execute("SELECT member_id, post_id FROM post_comment WHERE comment_id = %s", (comment_id,))
        comment = cursor.fetchone()
        
        if not comment:
            raise HTTPException(status_code=404, detail="댓글을 찾을 수 없습니다")
            
        if comment['member_id'] != member_id:
            raise HTTPException(status_code=403, detail="삭제 권한이 없습니다")
            
        # 대댓글 존재 여부 확인
        cursor.execute("SELECT COUNT(*) as reply_count FROM post_comment WHERE parent_comment_id = %s", (comment_id,))
        result = cursor.fetchone()
        reply_count = result['reply_count']

        if reply_count > 0:
            # 대댓글이 있으면 Soft Delete
            cursor.execute("UPDATE post_comment SET deleted_at = NOW() WHERE comment_id = %s", (comment_id,))
            message = "댓글이 삭제되었습니다. (대댓글 존재로 인해 내용은 유지됨)"
        else:
            # 대댓글이 없으면 Hard Delete
            cursor.execute("DELETE FROM post_comment WHERE comment_id = %s", (comment_id,))
            message = "댓글이 완전히 삭제되었습니다."
        
        conn.commit()
        return {"message": message}
        
    except HTTPException as he:
        raise he
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()
