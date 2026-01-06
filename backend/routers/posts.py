"""
커뮤니티 게시물 관리 API 라우터

DB 테이블 매핑:
post:
  - post_id (INT PK) → postId
  - member_id (INT FK) → memberId
  - category (VARCHAR) → category
  - title (VARCHAR) → title
  - content (TEXT) → content
  - view_count (INT) → viewCount
  - like_count (INT) → likeCount
  - created_at (TIMESTAMP) → createdAt

post_image:
  - image_id (INT PK) → imageId
  - post_id (INT FK) → postId
  - image_path (VARCHAR) → imagePath
  - display_order (INT) → displayOrder
  - created_at (TIMESTAMP) → createdAt
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from config.database import get_db_connection

router = APIRouter(prefix="/api/posts", tags=["posts"])


# Pydantic 모델
class PostImageCreate(BaseModel):
    imagePath: str = Field(..., description="이미지 파일 경로")
    displayOrder: int = Field(default=1, description="이미지 표시 순서")


class PostImageResponse(BaseModel):
    imageId: int
    postId: int
    imagePath: str
    displayOrder: int
    createdAt: str


class PostCreate(BaseModel):
    memberId: int = Field(..., description="작성자 member_id")
    category: str = Field(..., description="게시물 카테고리 (전체, 식단, 운동, 자유)")
    title: str = Field(..., max_length=200, description="게시물 제목")
    content: str = Field(..., description="게시물 내용")
    images: Optional[List[PostImageCreate]] = Field(default=None, description="첨부 이미지 목록")


class PostUpdate(BaseModel):
    category: Optional[str] = None
    title: Optional[str] = None
    content: Optional[str] = None
    images: Optional[List[PostImageCreate]] = None


class PostResponse(BaseModel):
    postId: int
    memberId: int
    authorNickname: Optional[str] = None
    category: str
    title: str
    content: str
    viewCount: int
    likeCount: int
    createdAt: str
    images: List[PostImageResponse] = []


class PostListItem(BaseModel):
    postId: int
    memberId: int
    authorNickname: Optional[str] = None
    category: str
    title: str
    viewCount: int
    likeCount: int
    imageCount: int
    createdAt: str


# GET /api/posts/list - 게시물 목록 조회 (페이지네이션, 필터링)
@router.get("/list", response_model=List[PostListItem])
async def get_posts_list(
    page: int = Query(1, ge=1, description="페이지 번호 (1부터 시작)"),
    limit: int = Query(10, ge=1, le=50, description="페이지당 게시물 수 (최대 50)"),
    category: Optional[str] = Query(None, description="카테고리 필터 (전체, 식단, 운동, 자유)"),
    member_id: Optional[int] = Query(None, description="특정 회원의 게시물만 조회")
):
    """게시물 목록을 페이지네이션과 함께 조회"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        offset = (page - 1) * limit

        # 기본 쿼리
        query = """
            SELECT 
                p.post_id,
                p.member_id,
                m.nickname as author_nickname,
                p.category,
                p.title,
                p.view_count,
                p.like_count,
                p.created_at,
                (SELECT COUNT(*) FROM post_image WHERE post_id = p.post_id) as image_count
            FROM post p
            LEFT JOIN members m ON p.member_id = m.member_id
            WHERE 1=1
        """
        params = []

        # 필터 추가
        if category and category != "전체":
            query += " AND p.category = %s"
            params.append(category)

        if member_id:
            query += " AND p.member_id = %s"
            params.append(member_id)

        # 정렬 및 페이지네이션
        query += " ORDER BY p.created_at DESC LIMIT %s OFFSET %s"
        params.extend([limit, offset])

        cursor.execute(query, params)
        posts = cursor.fetchall()

        result = []
        for post in posts:
            result.append(PostListItem(
                postId=post['post_id'],
                memberId=post['member_id'],
                authorNickname=post['author_nickname'],
                category=post['category'],
                title=post['title'],
                viewCount=post['view_count'],
                likeCount=post['like_count'],
                imageCount=post['image_count'],
                createdAt=post['created_at'].isoformat() if isinstance(post['created_at'], datetime) else post['created_at']
            ))

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"게시물 목록 조회 실패: {str(e)}")
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


# GET /api/posts/{post_id} - 게시물 상세 조회 (이미지 포함)
@router.get("/{post_id}", response_model=PostResponse)
async def get_post(post_id: int):
    """게시물 상세 정보 조회 (조회수 +1)"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 조회수 증가
        cursor.execute("UPDATE post SET view_count = view_count + 1 WHERE post_id = %s", (post_id,))
        connection.commit()

        # 게시물 조회
        cursor.execute("""
            SELECT 
                p.post_id,
                p.member_id,
                m.nickname as author_nickname,
                p.category,
                p.title,
                p.content,
                p.view_count,
                p.like_count,
                p.created_at
            FROM post p
            LEFT JOIN members m ON p.member_id = m.member_id
            WHERE p.post_id = %s
        """, (post_id,))
        post = cursor.fetchone()

        if not post:
            raise HTTPException(status_code=404, detail="게시물을 찾을 수 없습니다")

        # 이미지 조회
        cursor.execute("""
            SELECT image_id, post_id, image_path, display_order, created_at
            FROM post_image
            WHERE post_id = %s
            ORDER BY display_order
        """, (post_id,))
        images = cursor.fetchall()

        image_list = [
            PostImageResponse(
                imageId=img['image_id'],
                postId=img['post_id'],
                imagePath=img['image_path'],
                displayOrder=img['display_order'],
                createdAt=img['created_at'].isoformat() if isinstance(img['created_at'], datetime) else img['created_at']
            )
            for img in images
        ]

        return PostResponse(
            postId=post['post_id'],
            memberId=post['member_id'],
            authorNickname=post['author_nickname'],
            category=post['category'],
            title=post['title'],
            content=post['content'],
            viewCount=post['view_count'],
            likeCount=post['like_count'],
            createdAt=post['created_at'].isoformat() if isinstance(post['created_at'], datetime) else post['created_at'],
            images=image_list
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"게시물 조회 실패: {str(e)}")
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


# POST /api/posts/ - 게시물 생성
@router.post("/", response_model=PostResponse)
async def create_post(post_data: PostCreate):
    """새 게시물 생성 (이미지 포함 가능)"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 회원 존재 확인
        cursor.execute("SELECT member_id FROM members WHERE member_id = %s", (post_data.memberId,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="존재하지 않는 회원입니다")

        # 게시물 생성
        cursor.execute("""
            INSERT INTO post (member_id, category, title, content, view_count, like_count)
            VALUES (%s, %s, %s, %s, 0, 0)
        """, (post_data.memberId, post_data.category, post_data.title, post_data.content))
        
        post_id = cursor.lastrowid

        # 이미지 저장
        image_list = []
        if post_data.images:
            for img in post_data.images:
                cursor.execute("""
                    INSERT INTO post_image (post_id, image_path, display_order)
                    VALUES (%s, %s, %s)
                """, (post_id, img.imagePath, img.displayOrder))
                
                image_id = cursor.lastrowid
                cursor.execute("SELECT * FROM post_image WHERE image_id = %s", (image_id,))
                saved_img = cursor.fetchone()
                
                image_list.append(PostImageResponse(
                    imageId=saved_img['image_id'],
                    postId=saved_img['post_id'],
                    imagePath=saved_img['image_path'],
                    displayOrder=saved_img['display_order'],
                    createdAt=saved_img['created_at'].isoformat() if isinstance(saved_img['created_at'], datetime) else saved_img['created_at']
                ))

        connection.commit()

        # 생성된 게시물 조회
        cursor.execute("""
            SELECT 
                p.post_id,
                p.member_id,
                m.nickname as author_nickname,
                p.category,
                p.title,
                p.content,
                p.view_count,
                p.like_count,
                p.created_at
            FROM post p
            LEFT JOIN members m ON p.member_id = m.member_id
            WHERE p.post_id = %s
        """, (post_id,))
        post = cursor.fetchone()

        return PostResponse(
            postId=post['post_id'],
            memberId=post['member_id'],
            authorNickname=post['author_nickname'],
            category=post['category'],
            title=post['title'],
            content=post['content'],
            viewCount=post['view_count'],
            likeCount=post['like_count'],
            createdAt=post['created_at'].isoformat() if isinstance(post['created_at'], datetime) else post['created_at'],
            images=image_list
        )

    except HTTPException:
        if connection:
            connection.rollback()
        raise
    except Exception as e:
        if connection:
            connection.rollback()
        raise HTTPException(status_code=500, detail=f"게시물 생성 실패: {str(e)}")
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


# PUT /api/posts/{post_id} - 게시물 수정
@router.put("/{post_id}", response_model=PostResponse)
async def update_post(post_id: int, post_data: PostUpdate):
    """게시물 수정 (이미지 포함)"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 게시물 존재 확인
        cursor.execute("SELECT post_id, member_id FROM post WHERE post_id = %s", (post_id,))
        existing_post = cursor.fetchone()
        if not existing_post:
            raise HTTPException(status_code=404, detail="게시물을 찾을 수 없습니다")

        # 업데이트할 필드 구성
        updates = []
        params = []

        if post_data.category is not None:
            updates.append("category = %s")
            params.append(post_data.category)
        if post_data.title is not None:
            updates.append("title = %s")
            params.append(post_data.title)
        if post_data.content is not None:
            updates.append("content = %s")
            params.append(post_data.content)

        if updates:
            query = f"UPDATE post SET {', '.join(updates)} WHERE post_id = %s"
            params.append(post_id)
            cursor.execute(query, params)

        # 이미지 업데이트 (기존 이미지 삭제 후 새로 추가)
        if post_data.images is not None:
            cursor.execute("DELETE FROM post_image WHERE post_id = %s", (post_id,))
            
            for img in post_data.images:
                cursor.execute("""
                    INSERT INTO post_image (post_id, image_path, display_order)
                    VALUES (%s, %s, %s)
                """, (post_id, img.imagePath, img.displayOrder))

        connection.commit()

        # 수정된 게시물 조회
        cursor.execute("""
            SELECT 
                p.post_id,
                p.member_id,
                m.nickname as author_nickname,
                p.category,
                p.title,
                p.content,
                p.view_count,
                p.like_count,
                p.created_at
            FROM post p
            LEFT JOIN members m ON p.member_id = m.member_id
            WHERE p.post_id = %s
        """, (post_id,))
        post = cursor.fetchone()

        # 이미지 조회
        cursor.execute("""
            SELECT image_id, post_id, image_path, display_order, created_at
            FROM post_image
            WHERE post_id = %s
            ORDER BY display_order
        """, (post_id,))
        images = cursor.fetchall()

        image_list = [
            PostImageResponse(
                imageId=img['image_id'],
                postId=img['post_id'],
                imagePath=img['image_path'],
                displayOrder=img['display_order'],
                createdAt=img['created_at'].isoformat() if isinstance(img['created_at'], datetime) else img['created_at']
            )
            for img in images
        ]

        return PostResponse(
            postId=post['post_id'],
            memberId=post['member_id'],
            authorNickname=post['author_nickname'],
            category=post['category'],
            title=post['title'],
            content=post['content'],
            viewCount=post['view_count'],
            likeCount=post['like_count'],
            createdAt=post['created_at'].isoformat() if isinstance(post['created_at'], datetime) else post['created_at'],
            images=image_list
        )

    except HTTPException:
        if connection:
            connection.rollback()
        raise
    except Exception as e:
        if connection:
            connection.rollback()
        raise HTTPException(status_code=500, detail=f"게시물 수정 실패: {str(e)}")
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


# DELETE /api/posts/{post_id} - 게시물 삭제
@router.delete("/{post_id}")
async def delete_post(post_id: int):
    """게시물 삭제 (이미지도 함께 삭제)"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        # 게시물 존재 확인
        cursor.execute("SELECT post_id FROM post WHERE post_id = %s", (post_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="게시물을 찾을 수 없습니다")

        # 이미지 먼저 삭제 (FK 제약)
        cursor.execute("DELETE FROM post_image WHERE post_id = %s", (post_id,))
        
        # 게시물 삭제
        cursor.execute("DELETE FROM post WHERE post_id = %s", (post_id,))
        
        connection.commit()
        
        return {"message": "게시물이 삭제되었습니다", "postId": post_id}

    except HTTPException:
        if connection:
            connection.rollback()
        raise
    except Exception as e:
        if connection:
            connection.rollback()
        raise HTTPException(status_code=500, detail=f"게시물 삭제 실패: {str(e)}")
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


# GET /api/posts/search - 게시물 검색
@router.get("/search", response_model=List[PostListItem])
async def search_posts(
    q: str = Query(..., min_length=1, description="검색어"),
    page: int = Query(1, ge=1, description="페이지 번호"),
    limit: int = Query(10, ge=1, le=50, description="페이지당 게시물 수")
):
    """제목 또는 내용으로 게시물 검색"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        offset = (page - 1) * limit
        search_pattern = f"%{q}%"

        cursor.execute("""
            SELECT 
                p.post_id,
                p.member_id,
                m.nickname as author_nickname,
                p.category,
                p.title,
                p.view_count,
                p.like_count,
                p.created_at,
                (SELECT COUNT(*) FROM post_image WHERE post_id = p.post_id) as image_count
            FROM post p
            LEFT JOIN members m ON p.member_id = m.member_id
            WHERE p.title LIKE %s OR p.content LIKE %s
            ORDER BY p.created_at DESC
            LIMIT %s OFFSET %s
        """, (search_pattern, search_pattern, limit, offset))

        posts = cursor.fetchall()

        result = []
        for post in posts:
            result.append(PostListItem(
                postId=post['post_id'],
                memberId=post['member_id'],
                authorNickname=post['author_nickname'],
                category=post['category'],
                title=post['title'],
                viewCount=post['view_count'],
                likeCount=post['like_count'],
                imageCount=post['image_count'],
                createdAt=post['created_at'].isoformat() if isinstance(post['created_at'], datetime) else post['created_at']
            ))

        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"게시물 검색 실패: {str(e)}")
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


# POST /api/posts/{post_id}/like - 좋아요 추가
@router.post("/{post_id}/like")
async def like_post(post_id: int):
    """게시물 좋아요 추가"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 게시물 존재 확인
        cursor.execute("SELECT post_id, like_count FROM post WHERE post_id = %s", (post_id,))
        post = cursor.fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="게시물을 찾을 수 없습니다")

        # 좋아요 수 증가
        cursor.execute("UPDATE post SET like_count = like_count + 1 WHERE post_id = %s", (post_id,))
        connection.commit()

        return {"message": "좋아요가 추가되었습니다", "postId": post_id, "likeCount": post['like_count'] + 1}

    except HTTPException:
        if connection:
            connection.rollback()
        raise
    except Exception as e:
        if connection:
            connection.rollback()
        raise HTTPException(status_code=500, detail=f"좋아요 추가 실패: {str(e)}")
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()


# DELETE /api/posts/{post_id}/like - 좋아요 취소
@router.delete("/{post_id}/like")
async def unlike_post(post_id: int):
    """게시물 좋아요 취소"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 게시물 존재 확인
        cursor.execute("SELECT post_id, like_count FROM post WHERE post_id = %s", (post_id,))
        post = cursor.fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="게시물을 찾을 수 없습니다")

        # 좋아요 수 감소 (0 이하로 내려가지 않도록)
        new_count = max(0, post['like_count'] - 1)
        cursor.execute("UPDATE post SET like_count = %s WHERE post_id = %s", (new_count, post_id))
        connection.commit()

        return {"message": "좋아요가 취소되었습니다", "postId": post_id, "likeCount": new_count}

    except HTTPException:
        if connection:
            connection.rollback()
        raise
    except Exception as e:
        if connection:
            connection.rollback()
        raise HTTPException(status_code=500, detail=f"좋아요 취소 실패: {str(e)}")
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()
