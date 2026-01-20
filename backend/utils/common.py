"""
공통 유틸리티 함수 및 데코레이터
"""
from functools import wraps
from fastapi import HTTPException, status
from config.database import get_db_connection
from typing import Callable, Any
import logging

logger = logging.getLogger(__name__)


def handle_db_transaction(func: Callable) -> Callable:
    """
    데이터베이스 트랜잭션 자동 처리 데코레이터
    - 자동 커밋/롤백
    - 연결 자동 종료
    - 에러 로깅
    """
    @wraps(func)
    async def wrapper(*args, **kwargs):
        conn = None
        cursor = None
        try:
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)
            
            # kwargs에 cursor와 conn 병합
            kwargs.update({'cursor': cursor, 'conn': conn})
            
            # 함수 실행
            result = await func(*args, **kwargs)
            
            conn.commit()
            return result
            
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"DB Transaction Error in {func.__name__}: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database error: {str(e)}"
            )
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()
    
    return wrapper


def validate_member_exists(cursor, member_id: int) -> dict:
    """
    회원 존재 여부 확인 및 정보 반환
    
    Args:
        cursor: DB cursor
        member_id: 회원 ID
        
    Returns:
        dict: 회원 정보
        
    Raises:
        HTTPException: 회원이 없을 경우 404
    """
    cursor.execute(
        "SELECT * FROM members WHERE member_id = %s AND member_status = 'ACTIVE'",
        (member_id,)
    )
    member = cursor.fetchone()
    
    if not member:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Member with ID {member_id} not found or inactive"
        )
    
    return member


def validate_post_exists(cursor, post_id: int) -> dict:
    """
    게시물 존재 여부 확인 및 정보 반환
    """
    cursor.execute(
        "SELECT * FROM post WHERE post_id = %s AND deleted_at IS NULL",
        (post_id,)
    )
    post = cursor.fetchone()
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Post with ID {post_id} not found"
        )
    
    return post


def snake_to_camel(snake_str: str) -> str:
    """
    snake_case를 camelCase로 변환
    
    Args:
        snake_str: snake_case 문자열
        
    Returns:
        str: camelCase 문자열
    """
    components = snake_str.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


def convert_keys_to_camel(data: dict | list) -> dict | list:
    """
    딕셔너리 또는 리스트의 키를 snake_case에서 camelCase로 변환
    
    Args:
        data: 변환할 데이터
        
    Returns:
        dict | list: camelCase 키를 가진 데이터
    """
    if isinstance(data, dict):
        return {snake_to_camel(k): convert_keys_to_camel(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [convert_keys_to_camel(item) for item in data]
    else:
        return data


def paginate_query(
    cursor,
    base_query: str,
    params: tuple,
    page: int = 1,
    limit: int = 10,
    max_limit: int = 50
) -> tuple[list, dict]:
    """
    페이지네이션 적용
    
    Args:
        cursor: DB cursor
        base_query: 기본 쿼리 (SELECT ... FROM ... WHERE ...)
        params: 쿼리 파라미터
        page: 페이지 번호 (1부터 시작)
        limit: 페이지당 항목 수
        max_limit: 최대 제한
        
    Returns:
        tuple: (결과 리스트, 페이지 정보)
    """
    # limit 제한
    limit = min(limit, max_limit)
    offset = (page - 1) * limit
    
    # 전체 개수 조회
    count_query = f"SELECT COUNT(*) as total FROM ({base_query}) as subquery"
    cursor.execute(count_query, params)
    total = cursor.fetchone()['total']
    
    # 페이지 데이터 조회
    paginated_query = f"{base_query} LIMIT %s OFFSET %s"
    cursor.execute(paginated_query, params + (limit, offset))
    results = cursor.fetchall()
    
    # 페이지 정보
    page_info = {
        'total': total,
        'page': page,
        'limit': limit,
        'totalPages': (total + limit - 1) // limit  # 올림 계산
    }
    
    return results, page_info
