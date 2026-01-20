# TTM 개발 변경 이력

> 모든 주요 수정 및 추가 사항을 시간순으로 기록합니다.
> 형식: `[날짜] 카테고리 - 내용`

---

## 2026년 1월

### 01.12 - 커뮤니티 좋아요 기능 개선
- **백엔드**
  - `post_like` 테이블 사용하여 좋아요 관리 강화
  - `PostResponse`, `PostListItem` 모델에 `isLiked` 필드 추가
  - GET `/api/posts/list`에 `current_member_id` 파라미터 추가 (좋아요 여부 확인)
  - GET `/api/posts/{id}`에 `current_member_id` 파라미터 추가
  - POST `/api/posts/{id}/like`에 `member_id` 파라미터 추가
  - DELETE `/api/posts/{id}/like`에 `member_id` 파라미터 추가
  - 좋아요 토글 시 `post_like` 테이블과 `likes_count` 동시 업데이트

- **프론트엔드**
  - `Post`, `PostListItem` 모델에 `isLiked` 필드 추가
  - 인스타그램 스타일 좋아요 UI 구현 (하트 아이콘 채움/비움)
  - 낙관적 업데이트(Optimistic Update) 적용 - 즉시 UI 반영
  - 에러 발생 시 롤백 기능 추가
  - 좋아요 수 실시간 반영

### 01.12 - 내 정보 화면 개선
- **프로필 화면** ([profile_screen.dart](lib/screens/profile_screen.dart))
  - 총/운동 Kcal 삭제
  - 출석 일차만 중앙에 크게 표시 (가입일로부터 경과일 계산)
  - 내 활동 통계 DB 연동 준비 (meal_log, exercise_log, post, post_like COUNT)
  - 배지 시스템은 이미 DB 연동 완료 상태 유지

- **내 정보 수정 화면** ([profile_edit_screen.dart](lib/screens/settings/profile_edit_screen.dart))
  - 이름/이메일 기본 비활성화, '수정' 버튼 클릭 시 활성화
  - 현재 비밀번호 입력칸 추가 (새 비밀번호 입력 시 필수)
  - 비밀번호 검증 강화
    - 최소 8자 이상
    - 영문, 숫자 포함 필수
    - 비밀번호 확인 일치 검증
  - 회원가입과 동일한 비밀번호 검증 규칙 적용

### 01.12 - 게시글 날짜 표시 확인
- `Post` 및 `PostListItem` 모델의 `timeAgo` getter 확인
- DB `created_at` 칼럼과 정상 매칭 확인
- "방금 전", "n분 전", "n시간 전", "n일 전", "MM월 DD일" 형식 정상 작동

---

## 이전 개발 이력

### 01.09 - 백엔드 최종 검토
- posts.py view_count, likes_count DB 매칭 확인
- 모든 테이블 스키마 검증 완료
- 최종_검토_보고서.md 생성

### 01.06 - 커뮤니티 기능 구현
- 게시글 작성, 조회, 수정, 삭제 API 구현
- 이미지 업로드 기능 추가
- 좋아요 기능 기본 구현

### 12월 이전
- 초기 프로젝트 구조 설정
- 회원 관리, 식단 기록, 운동 기록 기능 구현
- 배지 시스템 구축

---

## 다음 작업 예정

### 우선순위 높음
- [ ] 내 활동 통계 실제 API 연동 (meal_log, exercise_log, post, post_like COUNT)
- [ ] 출석 일차 계산을 위한 User 모델에 created_at 필드 추가
- [ ] 비밀번호 변경 시 현재 비밀번호 검증 API 연동
- [ ] 이름/이메일 수정 API 연동

### 우선순위 중간
- [ ] 프로필 이미지 업로드 기능 구현
- [ ] 게시글 댓글 기능 완성
- [ ] 알림 시스템 구현

### 우선순위 낮음
- [ ] 다크 모드 지원
- [ ] 다국어 지원

---

## 변경 이력 작성 규칙

1. 날짜는 `MM.DD` 형식 사용
2. 카테고리는 기능 단위로 명확히 구분
3. 백엔드/프론트엔드 구분하여 기록
4. 파일 경로는 상대 경로로 링크 포함
5. Breaking Changes는 **굵게** 표시
6. 각 항목은 간결하되 구체적으로 작성
