"""
커뮤니티 게시물 관리 API 라우터

DB 테이블 매핑:
post:
  - post_id (INT PK) → postId
  - member_id (INT FK) → memberId
  - category (VARCHAR) → category
  - title (VARCHAR) → title
  - content (TEXT) → content
  - likes_count (INT) → likeCount
  - created_at (TIMESTAMP) → createdAt

post_image:
  - post_image_id (INT PK) → imageId
  - post_id (INT FK) → postId
  - image_path (VARCHAR) → imagePath
  - image_order (INT) → displayOrder
  - created_at (TIMESTAMP) → createdAt
"""

from fastapi import APIRouter, HTTPException, Query, UploadFile, File
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from config.database import get_db_connection
from services.fcm_service import FCMService
import os
import uuid
from pathlib import Path

router = APIRouter()

# 업로드 디렉토리 설정
BASE_DIR = Path(__file__).resolve().parent.parent
UPLOAD_DIR = BASE_DIR / "uploads"


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
    authorProfileImage: Optional[str] = None
    category: str
    title: str
    content: str
    likeCount: int
    viewCount: int
    isLiked: bool = False
    createdAt: str
    images: List[PostImageResponse] = []


class PostListItem(BaseModel):
    postId: int
    memberId: int
    authorNickname: Optional[str] = None
    authorProfileImage: Optional[str] = None
    category: str
    title: str
    likeCount: int
    viewCount: int
    imageCount: int
    isLiked: bool = False
    createdAt: str


# POST /api/posts/upload-image - 이미지 업로드
@router.post("/upload-image")
async def upload_post_image(file: UploadFile = File(...)):
    """게시글 이미지 업로드"""
    try:
        # 이미지 파일만 허용
        allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
        file_ext = os.path.splitext(file.filename)[1].lower()
        
        if file_ext not in allowed_extensions:
            raise HTTPException(status_code=400, detail="지원하지 않는 파일 형식입니다")
        
        # 파일 크기 제한 (5MB)
        content = await file.read()
        if len(content) > 5 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="파일 크기는 5MB를 초과할 수 없습니다")
        
        # 저장 디렉토리 생성
        upload_dir = UPLOAD_DIR / "posts"
        upload_dir.mkdir(parents=True, exist_ok=True)
        
        # 고유 파일명 생성
        unique_filename = f"{uuid.uuid4()}{file_ext}"
        file_path = upload_dir / unique_filename
        
        # 파일 저장
        with open(file_path, "wb") as f:
            f.write(content)
        
        # 접근 가능한 URL 경로 반환
        image_url = f"/uploads/posts/{unique_filename}"
        
        return {
            "imagePath": image_url,
            "filename": unique_filename
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"이미지 업로드 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"이미지 업로드 실패: {str(e)}")


# GET /api/posts/list - 게시물 목록 조회 (페이지네이션, 필터링)
@router.get("/list", response_model=List[PostListItem])
async def get_posts_list(
    page: int = Query(1, ge=1, description="페이지 번호 (1부터 시작)"),
    limit: int = Query(10, ge=1, le=50, description="페이지당 게시물 수 (최대 50)"),
    category: Optional[str] = Query(None, description="카테고리 필터 (전체, 식단, 운동, 자유)"),
    member_id: Optional[int] = Query(None, description="특정 회원의 게시물만 조회"),
    current_member_id: Optional[int] = Query(None, description="현재 로그인한 사용자 ID (좋아요 여부 확인용)"),
    liked_only: bool = Query(False, alias="liked_only", description="좋아요한 게시물만 조회")
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
                m.profile_image as author_profile_image,
                p.category,
                p.title,
                p.likes_count as like_count,
                p.view_count,
                p.created_at,
                (SELECT COUNT(*) FROM post_image WHERE post_id = p.post_id) as image_count"""
        params: List = []

        if liked_only and not current_member_id:
            raise HTTPException(status_code=400, detail="liked_only는 current_member_id와 함께 사용해야 합니다")
        
        # 현재 사용자의 좋아요 여부 확인
        if current_member_id:
            query += """,
                (SELECT COUNT(*) FROM post_like WHERE post_id = p.post_id AND member_id = %s) > 0 as is_liked
            """
            params.append(current_member_id)
        else:
            query += """,
                0 as is_liked
            """
        
        query += """
            FROM post p
            LEFT JOIN members m ON p.member_id = m.member_id
            WHERE 1=1
        """

        # 필터 추가
        if category and category != "전체":
            query += " AND p.category = %s"
            params.append(category)

        if member_id:
            query += " AND p.member_id = %s"
            params.append(member_id)

        if liked_only:
            query += " AND EXISTS (SELECT 1 FROM post_like pl WHERE pl.post_id = p.post_id AND pl.member_id = %s)"
            params.append(current_member_id)

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
                authorProfileImage=post['author_profile_image'],
                category=post['category'],
                title=post['title'],
                likeCount=post['like_count'],
                viewCount=post['view_count'],
                imageCount=post['image_count'],
                isLiked=bool(post.get('is_liked', 0)),
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
async def get_post(
    post_id: int,
    current_member_id: Optional[int] = Query(None, description="현재 로그인한 사용자 ID (좋아요 여부 확인용)")
):
    """게시물 상세 정보 조회"""
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
                m.profile_image as author_profile_image,
                p.category,
                p.title,
                p.content,
                p.likes_count as like_count,
                p.view_count,
                p.created_at
            FROM post p
            LEFT JOIN members m ON p.member_id = m.member_id
            WHERE p.post_id = %s
        """, (post_id,))
        post = cursor.fetchone()

        if not post:
            raise HTTPException(status_code=404, detail="게시물을 찾을 수 없습니다")
        
        # 현재 사용자의 좋아요 여부 확인
        is_liked = False
        if current_member_id:
            cursor.execute("""
                SELECT COUNT(*) as count FROM post_like 
                WHERE post_id = %s AND member_id = %s
            """, (post_id, current_member_id))
            like_result = cursor.fetchone()
            is_liked = like_result['count'] > 0 if like_result else False

        # 이미지 조회
        cursor.execute("""
            SELECT post_image_id, post_id, image_path, image_order, created_at
            FROM post_image
            WHERE post_id = %s
            ORDER BY image_order
        """, (post_id,))
        images = cursor.fetchall()

        image_list = [
            PostImageResponse(
                imageId=img['post_image_id'],
                postId=img['post_id'],
                imagePath=img['image_path'],
                displayOrder=img['image_order'],
                createdAt=img['created_at'].isoformat() if isinstance(img['created_at'], datetime) else img['created_at']
            )
            for img in images
        ]

        return PostResponse(
            postId=post['post_id'],
            memberId=post['member_id'],
            authorNickname=post['author_nickname'],
            authorProfileImage=post['author_profile_image'],
            category=post['category'],
            title=post['title'],
            content=post['content'],
            likeCount=post['like_count'],
            viewCount=post['view_count'],
            isLiked=is_liked,
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
        print(f"게시글 작성 요청 받음: {post_data.dict()}")  # 디버깅용
        
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 회원 존재 확인
        cursor.execute("SELECT member_id FROM members WHERE member_id = %s", (post_data.memberId,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="존재하지 않는 회원입니다")

        # 게시물 생성
        cursor.execute("""
            INSERT INTO post (member_id, category, title, content, likes_count, comments_count)
            VALUES (%s, %s, %s, %s, 0, 0)
        """, (post_data.memberId, post_data.category, post_data.title, post_data.content))
        
        post_id = cursor.lastrowid
        print(f"게시글 생성 완료: post_id={post_id}")  # 디버깅용

        # 이미지 저장
        image_list = []
        if post_data.images:
            print(f"이미지 {len(post_data.images)}개 저장 시작")  # 디버깅용
            for img in post_data.images:
                print(f"이미지 저장: {img.dict()}")  # 디버깅용
                cursor.execute("""
                    INSERT INTO post_image (post_id, image_path, image_order, created_at)
                    VALUES (%s, %s, %s, NOW())
                """, (post_id, img.imagePath, img.displayOrder))
                
                image_id = cursor.lastrowid
                cursor.execute("SELECT * FROM post_image WHERE post_image_id = %s", (image_id,))
                saved_img = cursor.fetchone()
                
                image_list.append(PostImageResponse(
                    imageId=saved_img['post_image_id'],
                    postId=saved_img['post_id'],
                    imagePath=saved_img['image_path'],
                    displayOrder=saved_img['image_order'],
                    createdAt=saved_img['created_at'].isoformat() if isinstance(saved_img['created_at'], datetime) else saved_img['created_at']
                ))

        connection.commit()

        # 생성된 게시물 조회
        cursor.execute("""
            SELECT 
                p.post_id,
                p.member_id,
                m.nickname as author_nickname,
                m.profile_image as author_profile_image,
                p.category,
                p.title,
                p.content,
                p.likes_count as like_count,
                p.view_count,
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
            authorProfileImage=post['author_profile_image'],
            category=post['category'],
            title=post['title'],
            content=post['content'],
            likeCount=post['like_count'],
            viewCount=post['view_count'],
            createdAt=post['created_at'].isoformat() if isinstance(post['created_at'], datetime) else post['created_at'],
            images=image_list
        )

    except HTTPException:
        if connection:
            connection.rollback()
        raise
    except Exception as e:
        print(f"게시글 작성 중 오류 발생: {str(e)}")  # 디버깅용
        print(f"오류 타입: {type(e)}")  # 디버깅용
        import traceback
        traceback.print_exc()  # 디버깅용
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
                    INSERT INTO post_image (post_id, image_path, image_order)
                    VALUES (%s, %s, %s)
                """, (post_id, img.imagePath, img.displayOrder))

        connection.commit()

        # 수정된 게시물 조회
        cursor.execute("""
            SELECT 
                p.post_id,
                p.member_id,
                m.nickname as author_nickname,
                m.profile_image as author_profile_image,
                p.category,
                p.title,
                p.content,
                p.likes_count as like_count,
                p.view_count,
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
            authorProfileImage=post['author_profile_image'],
            category=post['category'],
            title=post['title'],
            content=post['content'],
            likeCount=post['like_count'],
            viewCount=post['view_count'],
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
                m.profile_image as author_profile_image,
                p.category,
                p.title,
                p.likes_count as like_count,
                p.view_count,
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
                authorProfileImage=post['author_profile_image'],
                category=post['category'],
                title=post['title'],
                likeCount=post['like_count'],
                viewCount=post['view_count'],
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
async def like_post(
    post_id: int,
    member_id: int = Query(..., description="좋아요를 누르는 사용자 ID")
):
    """게시물 좋아요 추가 (인스타그램 스타일)"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 게시물 존재 확인
        cursor.execute("SELECT post_id FROM post WHERE post_id = %s", (post_id,))
        post = cursor.fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="게시물을 찾을 수 없습니다")

        # 이미 좋아요 눌렀는지 확인
        cursor.execute("""
            SELECT like_id FROM post_like 
            WHERE post_id = %s AND member_id = %s
        """, (post_id, member_id))
        existing_like = cursor.fetchone()
        
        if existing_like:
            # 이미 좋아요를 누른 경우 - 중복 방지
            return {"message": "이미 좋아요를 눌렀습니다", "postId": post_id, "isLiked": True}

        # post_like 테이블에 추가
        cursor.execute("""
            INSERT INTO post_like (post_id, member_id)
            VALUES (%s, %s)
        """, (post_id, member_id))
        
        # likes_count 증가
        cursor.execute("""
            UPDATE post SET likes_count = likes_count + 1 
            WHERE post_id = %s
        """, (post_id,))
        
        connection.commit()

        # 최신 좋아요 수 조회
        cursor.execute("SELECT likes_count FROM post WHERE post_id = %s", (post_id,))
        updated_post = cursor.fetchone()
        
        # 🔔 알림 전송: 게시글 작성자에게 좋아요 알림
        try:
            # 게시글 작성자 정보 조회
            cursor.execute("""
                SELECT p.member_id, m.fcm_token, m.nickname as post_author_nickname
                FROM post p
                JOIN members m ON p.member_id = m.member_id
                WHERE p.post_id = %s
            """, (post_id,))
            post_author = cursor.fetchone()
            
            # 자기 게시글에 자기가 좋아요 누른 경우 제외
            if post_author and post_author['member_id'] != member_id:
                if post_author.get('fcm_token'):
                    # 좋아요 누른 사용자 닉네임 조회
                    cursor.execute("SELECT nickname FROM members WHERE member_id = %s", (member_id,))
                    liker = cursor.fetchone()
                    
                    if liker:
                        await FCMService.send_like_notification(
                            fcm_token=post_author['fcm_token'],
                            liker_name=liker['nickname'],
                            post_id=post_id
                        )
                        print(f"🔔 좋아요 알림 전송 완료: {liker['nickname']} -> {post_author['post_author_nickname']}")
        except Exception as e:
            print(f"⚠️ 알림 전송 실패 (좋아요): {e}")

        return {
            "message": "좋아요가 추가되었습니다", 
            "postId": post_id, 
            "likeCount": updated_post['likes_count'],
            "isLiked": True
        }

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
async def unlike_post(
    post_id: int,
    member_id: int = Query(..., description="좋아요를 취소하는 사용자 ID")
):
    """게시물 좋아요 취소 (인스타그램 스타일)"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        # 게시물 존재 확인
        cursor.execute("SELECT post_id FROM post WHERE post_id = %s", (post_id,))
        post = cursor.fetchone()
        if not post:
            raise HTTPException(status_code=404, detail="게시물을 찾을 수 없습니다")

        # 좋아요 기록 삭제
        cursor.execute("""
            DELETE FROM post_like 
            WHERE post_id = %s AND member_id = %s
        """, (post_id, member_id))
        
        deleted_rows = cursor.rowcount
        
        # 좋아요가 있었던 경우에만 count 감소
        if deleted_rows > 0:
            cursor.execute("""
                UPDATE post 
                SET likes_count = GREATEST(0, likes_count - 1)
                WHERE post_id = %s
            """, (post_id,))
        
        connection.commit()

        # 최신 좋아요 수 조회
        cursor.execute("SELECT likes_count FROM post WHERE post_id = %s", (post_id,))
        updated_post = cursor.fetchone()

        return {
            "message": "좋아요가 취소되었습니다", 
            "postId": post_id, 
            "likeCount": updated_post['likes_count'],
            "isLiked": False
        }

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
