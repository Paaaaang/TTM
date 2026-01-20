# TTM 데이터베이스 문서

> 작성일: 2026-01-14  
> 최종 수정일: 2026-01-14  
> DB 버전: MySQL 8.0  
> 스키마: ttm_db / we0123

---

## 📋 목차

1. [데이터베이스 개요](#데이터베이스-개요)
2. [테이블 구조](#테이블-구조)
3. [주요 변경 이력](#주요-변경-이력)
4. [중복 체크 결과](#중복-체크-결과)
5. [마이그레이션 가이드](#마이그레이션-가이드)
6. [성능 최적화](#성능-최적화)

---

## 데이터베이스 개요

### 기본 정보
- **데이터베이스명**: `ttm_db` (개발), `we0123` (운영)
- **문자셋**: utf8mb4
- **Collation**: utf8mb4_unicode_ci
- **테이블 수**: 14개
- **엔진**: InnoDB

### 연결 정보
```python
# backend/config/database.py
DATABASE_CONFIG = {
    "host": "project-db-campus.smhrd.com",
    "port": 3307,
    "user": "campus_23IS_AI4_p1_2",
    "password": "smhrd2",
    "database": "we0123",
    "charset": "utf8mb4"
}
```

---

## 테이블 구조

### 1. members (회원 정보)
**총 컬럼**: 23개  
**주요 컬럼**:
- `member_id` BIGINT - 회원 고유 ID (PK)
- `email` VARCHAR(255) - 이메일 (UNIQUE)
- `login_id` VARCHAR(50) - 로그인 ID (UNIQUE)
- `password_hash` VARCHAR(255) - 비밀번호 해시
- `phone_number` VARCHAR(20) - 전화번호 (UNIQUE)
- `member_name` VARCHAR(50) - 이름
- `nickname` VARCHAR(50) - 닉네임 (UNIQUE)
- `gender` ENUM('M','F','O') - 성별
- `birth_date` DATE - 생년월일
- `region` VARCHAR(50) - 지역
- `height_cm` DECIMAL(5,2) - 키 (cm)
- `weight_kg` DECIMAL(5,2) - 현재 체중 (kg) ⚠️ 최근 체중 캐시
- `member_status` ENUM - 회원 상태
- `calorie_goal` INT - 일일 칼로리 목표 (기본 2000kcal)
- `water_goal` DECIMAL(5,2) - 일일 물 섭취 목표 (기본 2.0L)

**인덱스**:
- PRIMARY KEY: `member_id`
- UNIQUE: `email`, `login_id`, `phone_number`, `nickname`
- INDEX: `member_status`

**제약 조건**:
- 모든 UNIQUE 컬럼은 NULL 불가
- 회원 상태는 ACTIVE가 기본값

---

### 2. meal_log (식단 기록)
**총 컬럼**: 8개  
**주요 컬럼**:
- `meal_log_id` BIGINT - 식단 기록 ID (PK)
- `member_id` BIGINT - 회원 ID (FK → members)
- `meal_date` DATE - 식사 날짜
- `meal_type` ENUM('BREAKFAST','LUNCH','DINNER','SNACK') - 식사 유형
- `total_calories` INT - 총 칼로리
- `notes` TEXT - 메모

**인덱스**:
- PRIMARY KEY: `meal_log_id`
- INDEX: `meal_date`, `member_id`
- FOREIGN KEY: `member_id` ON DELETE CASCADE

**쿼리 최적화**:
```sql
-- 특정 날짜 범위 조회 (날짜 인덱스 활용)
SELECT * FROM meal_log 
WHERE member_id = 1 AND meal_date BETWEEN '2026-01-01' AND '2026-01-31';
```

---

### 3. meal_item (식단 항목)
**총 컬럼**: 10개  
**주요 컬럼**:
- `meal_item_id` BIGINT - 항목 ID (PK)
- `meal_log_id` BIGINT - 식단 ID (FK → meal_log)
- `food_name` VARCHAR(100) - 음식명
- `calories` INT - 칼로리
- `protein_g`, `carbs_g`, `fat_g` DECIMAL(5,2) - 3대 영양소
- `sugar_g`, `sodium_mg` DECIMAL - 당류, 나트륨
- `serving_size` VARCHAR(50) - 1인분 크기

**인덱스**:
- PRIMARY KEY: `meal_item_id`
- INDEX: `meal_log_id`
- FOREIGN KEY: `meal_log_id` ON DELETE CASCADE

---

### 4. exercise_log (운동 기록)
**총 컬럼**: 9개  
**주요 컬럼**:
- `exercise_log_id` BIGINT - 운동 기록 ID (PK)
- `member_id` BIGINT - 회원 ID (FK → members)
- `exercise_date` DATE - 운동 날짜
- `exercise_type` VARCHAR(50) - 운동 유형
- `exercise_name` VARCHAR(100) - 운동명
- `duration_minutes` INT - 운동 시간 (분)
- `calories_burned` INT - 소모 칼로리
- `intensity_level` ENUM('LOW','MODERATE','HIGH') - 운동 강도

**인덱스**:
- PRIMARY KEY: `exercise_log_id`
- INDEX: `exercise_date`, `member_id`
- FOREIGN KEY: `member_id` ON DELETE CASCADE

---

### 5. weight_log (체중 기록) 🆕
**추가일**: 2026-01-09  
**총 컬럼**: 6개  
**주요 컬럼**:
- `weight_log_id` BIGINT - 체중 기록 ID (PK)
- `member_id` BIGINT - 회원 ID (FK → members)
- `weight_kg` DECIMAL(5,2) - 측정 체중 (kg)
- `recorded_date` DATE - 측정 날짜
- `memo` TEXT - 메모

**인덱스**:
- PRIMARY KEY: `weight_log_id`
- INDEX: `member_id`, `recorded_date`
- **복합 인덱스**: `(member_id, recorded_date)` ⚡ 조회 성능 최적화
- FOREIGN KEY: `member_id` ON DELETE CASCADE

**members.weight_kg와의 차이점**:
- `members.weight_kg`: **최근 체중 캐시** (빠른 조회용)
- `weight_log.weight_kg`: **날짜별 체중 변화 기록** (통계/그래프용)

---

### 6. post (게시물)
**총 컬럼**: 11개  
**주요 컬럼**:
- `post_id` BIGINT - 게시물 ID (PK)
- `member_id` BIGINT - 작성자 ID (FK → members)
- `title` VARCHAR(200) - 제목
- `content` TEXT - 내용
- `category` ENUM('NOTICE','FREE','QNA','REVIEW') - 카테고리
- `visibility_scope` ENUM('PUBLIC','PRIVATE','FRIENDS') - 공개 범위
- `likes_count` INT - 좋아요 수
- `comments_count` INT - 댓글 수

**인덱스**:
- PRIMARY KEY: `post_id`
- INDEX: `category`, `member_id`, `created_at`, `likes_count`, `comments_count`
- FOREIGN KEY: `member_id` ON DELETE CASCADE

---

### 7. post_image (게시물 이미지)
**총 컬럼**: 5개  
**주요 컬럼**:
- `post_image_id` BIGINT - 이미지 ID (PK)
- `post_id` BIGINT - 게시물 ID (FK → post)
- `image_path` VARCHAR(500) - 이미지 경로
- `image_order` INT - 이미지 순서

**인덱스**:
- PRIMARY KEY: `post_image_id`
- INDEX: `post_id`
- FOREIGN KEY: `post_id` ON DELETE CASCADE

---

### 8. post_comment (댓글)
**총 컬럼**: 7개  
**주요 컬럼**:
- `comment_id` BIGINT - 댓글 ID (PK)
- `post_id` BIGINT - 게시물 ID (FK → post)
- `member_id` BIGINT - 작성자 ID (FK → members)
- `content` TEXT - 댓글 내용
- `parent_comment_id` BIGINT - 부모 댓글 ID (대댓글용)

**인덱스**:
- PRIMARY KEY: `comment_id`
- INDEX: `post_id`, `member_id`, `parent_comment_id`
- FOREIGN KEY: `post_id`, `member_id`, `parent_comment_id` ON DELETE CASCADE

**대댓글 구조**:
```sql
-- 대댓글 조회
SELECT * FROM post_comment 
WHERE post_id = 1 AND parent_comment_id IS NULL; -- 일반 댓글

SELECT * FROM post_comment 
WHERE parent_comment_id = 10; -- 댓글 ID 10의 대댓글
```

---

### 9. post_like (게시물 좋아요)
**총 컬럼**: 3개  
**주요 컬럼**:
- `like_id` BIGINT - 좋아요 ID (PK)
- `post_id` BIGINT - 게시물 ID (FK → post)
- `member_id` BIGINT - 회원 ID (FK → members)

**인덱스**:
- PRIMARY KEY: `like_id`
- UNIQUE: `(post_id, member_id)` ⚠️ 중복 좋아요 방지
- INDEX: `post_id`, `member_id`
- FOREIGN KEY: `post_id`, `member_id` ON DELETE CASCADE

---

### 10. badge (배지 마스터)
**총 컬럼**: 6개  
**주요 컬럼**:
- `badge_id` BIGINT - 배지 ID (PK)
- `badge_name` VARCHAR(100) - 배지명
- `description` VARCHAR(500) - 설명
- `badge_condition` VARCHAR(255) - 획득 조건
- `icon_path` VARCHAR(500) - 아이콘 경로

---

### 11. member_badge (회원 보유 배지)
**총 컬럼**: 4개  
**주요 컬럼**:
- `member_badge_id` BIGINT - ID (PK)
- `member_id` BIGINT - 회원 ID (FK → members)
- `badge_id` BIGINT - 배지 ID (FK → badge)
- `acquired_at` DATETIME - 획득 시간

**인덱스**:
- PRIMARY KEY: `member_badge_id`
- UNIQUE: `(member_id, badge_id)` ⚠️ 중복 획득 방지
- INDEX: `member_id`, `badge_id`
- FOREIGN KEY: `member_id`, `badge_id` ON DELETE CASCADE

---

### 12. member_disease (회원 질병 정보)
**총 컬럼**: 4개  
**주요 컬럼**:
- `member_disease_id` BIGINT - ID (PK)
- `member_id` BIGINT - 회원 ID (FK → members)
- `disease_name` VARCHAR(50) - 질병명
- `description` VARCHAR(300) - 설명

**인덱스**:
- PRIMARY KEY: `member_disease_id`
- INDEX: `member_id`
- FOREIGN KEY: `member_id` ON DELETE CASCADE

---

### 13. member_allergy (회원 알레르기 정보)
**총 컬럼**: 4개  
**주요 컬럼**:
- `allergy_id` BIGINT - ID (PK)
- `member_id` BIGINT - 회원 ID (FK → members)
- `allergy_name` VARCHAR(100) - 알레르기명
- `notes` TEXT - 비고

**인덱스**:
- PRIMARY KEY: `allergy_id`
- INDEX: `member_id`
- FOREIGN KEY: `member_id` ON DELETE CASCADE

---

### 14. friend (친구 관계)
**총 컬럼**: 4개  
**주요 컬럼**:
- `friend_id` BIGINT - ID (PK)
- `member_id` BIGINT - 요청자 ID (FK → members)
- `friend_member_id` BIGINT - 친구 ID (FK → members)
- `status` ENUM('PENDING','ACCEPTED','BLOCKED') - 친구 상태

**인덱스**:
- PRIMARY KEY: `friend_id`
- UNIQUE: `(member_id, friend_member_id)` ⚠️ 중복 친구 방지
- INDEX: `member_id`, `friend_member_id`, `status`
- FOREIGN KEY: `member_id`, `friend_member_id` ON DELETE CASCADE

---

## 주요 변경 이력

### 2026-01-09: weight_log 테이블 추가 ✅

**배경**:
- members 테이블의 weight_kg는 현재 체중만 저장
- 시간에 따른 체중 변화를 추적하기 위해 별도 테이블 필요
- 통계 화면의 체중 그래프에 실제 데이터 연동

**변경 내용**:
1. weight_log 테이블 생성
2. API 엔드포인트 구현 (routers/weight.py)
   - POST /api/weight/record - 체중 기록 생성/업데이트
   - GET /api/weight/history - 체중 이력 조회
   - GET /api/weight/latest - 최근 체중 조회
   - DELETE /api/weight/record/{id} - 체중 기록 삭제
3. Flutter 서비스 구현 (lib/services/weight_service.dart)
4. 통계 화면 연동 (lib/screens/stats_screen.dart)

**최종 테이블 수**: 13개 → 14개 (+1)

---

### 2026-01-07: 데이터베이스 최적화 작업 ✅

**members 테이블 최적화 (8개 컬럼 제거)**:
- ❌ `social_login_agreed` - terms_agreed로 통합 가능
- ❌ `disease_flag` - member_disease 테이블 조회로 대체
- ❌ `allergy_flag` - member_allergy 테이블 조회로 대체
- ❌ `sleep_hours`, `sleep_pattern` - 사용하지 않음
- ❌ `health_goal`, `exercise_goal`, `step_goal` - 사용하지 않음

**최종 컬럼 수**: 31개 → 23개 (8개 감소)

**기타 테이블 최적화**:
- meal_log: 필수 컬럼만 유지 (8개)
- exercise_log: 필수 컬럼만 유지 (9개)
- post: 게시물 기능 최적화 (11개)

---

### 2026-01-06: 초기 스키마 생성 ✅

**생성된 테이블**: 13개
- members, meal_log, meal_item, exercise_log
- post, post_image, post_comment, post_like
- badge, member_badge
- member_disease, member_allergy
- friend

**초기 데이터**:
```sql
-- 테스트 계정 2개
INSERT INTO members (login_id, nickname, email, password_hash, ...)
VALUES 
('test', '테스터', 'test@test.com', '$2b$12$...', ...),
('admin', '관리자', 'admin@ttm.com', '$2b$12$...', ...);
```

---

## 중복 체크 결과

### 1. 체중 관련 컬럼 ✅ 중복 아님

#### members.weight_kg vs weight_log.weight_kg
- **결론**: 용도가 다름
- `members.weight_kg`: **최근 체중 캐시** (빠른 조회용)
  - 프로필 조회 시 JOIN 불필요
  - BMI 계산 즉시 가능 (height_cm + weight_kg)
  - 칼로리 목표 계산 (체중 기반)
- `weight_log.weight_kg`: **날짜별 체중 변화 기록**
  - 통계 화면의 그래프 데이터
  - 주간/월간 체중 변화 추이
  - 체중 감량 목표 달성 확인

**자동 동기화 로직**:
```python
# backend/routers/weight.py
# 체중 기록 시 members 테이블도 자동 업데이트
UPDATE members m
SET m.weight_kg = (
    SELECT w.weight_kg FROM weight_log w
    WHERE w.member_id = m.member_id
    ORDER BY w.recorded_date DESC
    LIMIT 1
)
WHERE m.member_id = ?;
```

### 2. 체중 기록 → 그래프 연동 현황 ✅

**완료된 부분**:
1. WeightService 구현 (lib/services/weight_service.dart)
   - `createWeightRecord()`: 체중 기록 생성/업데이트
   - `getWeightHistory()`: 체중 이력 조회
   - `getWeeklyWeightData()`: 주간 데이터
   - `getMonthlyWeightData()`: 월간 데이터

2. stats_screen.dart 연동 (77-95줄)
   ```dart
   weightData = await _weightService.getWeeklyWeightData(
     startDate: startOfWeek,
     endDate: endOfWeek,
   );
   
   final Map<String, double> weightMap = {};
   for (var record in weightData) {
     weightMap[record['date']] = record['weight'];
   }
   ```

---

## 마이그레이션 가이드

### 아카이브된 마이그레이션 스크립트
마이그레이션 스크립트는 `backend/utilities/migrations/` 폴더로 이동되었습니다.

**파일 목록**:
- `add_allergy_tables.sql` - 알레르기 테이블 추가 (완료)
- `add_missing_columns.py` - 누락 컬럼 추가 (완료)
- `create_weight_log.sql` - weight_log 테이블 생성 (완료)
- `add_performance_indexes.sql` - 성능 인덱스 추가 (완료, schema.sql에 병합)

**⚠️ 주의사항**:
- 이 스크립트들은 이미 적용되었으므로 재실행하지 마세요
- 새 환경에서는 `schema.sql`만 실행하면 됩니다

### 새 환경 구축 절차

```bash
# 1. MySQL 접속
mysql -h project-db-campus.smhrd.com -P 3307 -u campus_23IS_AI4_p1_2 -p

# 2. 스키마 생성
mysql> source backend/database/schema.sql;

# 3. 테이블 확인
mysql> USE we0123;
mysql> SHOW TABLES;  # 14개 테이블 확인

# 4. 인덱스 확인
mysql> SHOW INDEX FROM meal_log;
mysql> SHOW INDEX FROM exercise_log;
mysql> SHOW INDEX FROM weight_log;
```

---

## 성능 최적화

### 1. 인덱스 전략

**단일 컬럼 인덱스** (빠른 조회):
- `meal_log(meal_date)` - 날짜별 식단 조회
- `exercise_log(exercise_date)` - 날짜별 운동 조회
- `weight_log(recorded_date)` - 날짜별 체중 조회
- `post(category)` - 카테고리별 게시물
- `post(created_at)` - 최신순 정렬

**복합 인덱스** (조인 최적화):
- `weight_log(member_id, recorded_date)` ⚡
- `post_like(post_id, member_id)` - UNIQUE 제약 + 조회

**UNIQUE 제약** (중복 방지 + 성능):
- `members(email, login_id, phone_number, nickname)`
- `post_like(post_id, member_id)` - 중복 좋아요 방지
- `member_badge(member_id, badge_id)` - 중복 배지 방지
- `friend(member_id, friend_member_id)` - 중복 친구 방지

### 2. 쿼리 최적화 예시

**주간 체중 데이터 조회** (복합 인덱스 활용):
```sql
SELECT weight_kg, recorded_date 
FROM weight_log 
WHERE member_id = ? 
  AND recorded_date BETWEEN ? AND ?
ORDER BY recorded_date ASC;
-- INDEX(member_id, recorded_date) 사용 → FAST
```

**월간 칼로리 통계** (날짜 인덱스 활용):
```sql
SELECT DATE(meal_date) as date, SUM(total_calories) as total
FROM meal_log 
WHERE member_id = ? 
  AND meal_date BETWEEN ? AND ?
GROUP BY DATE(meal_date);
-- INDEX(meal_date) 사용 → FAST
```

**카테고리별 게시물** (카테고리 인덱스 활용):
```sql
SELECT * FROM post 
WHERE category = 'FREE' 
  AND deleted_at IS NULL
ORDER BY created_at DESC 
LIMIT 20;
-- INDEX(category) + INDEX(created_at) 사용 → FAST
```

### 3. CASCADE 정책

**ON DELETE CASCADE** (자동 삭제):
- members 삭제 시 → 모든 하위 데이터 자동 삭제
  - meal_log, exercise_log, weight_log
  - post, post_comment, post_like
  - member_badge, member_disease, member_allergy
  - friend

**장점**:
- 데이터 정합성 유지
- 수동 삭제 불필요
- 고아 레코드(orphan record) 방지

---

## 참고 자료

### 관련 문서
- [BACKEND_GUIDE.md](../BACKEND_GUIDE.md) - 백엔드 API 문서
- [FRONTEND_GUIDE.md](../../lib/FRONTEND_GUIDE.md) - Flutter 개발 가이드
- [schema.sql](./schema.sql) - 전체 스키마 정의

### 데이터베이스 도구
- MySQL Workbench
- DBeaver
- phpMyAdmin

---

**✅ 마지막 업데이트**: 2026-01-14  
**📊 현재 테이블 수**: 14개  
**🔍 총 인덱스 수**: 45개+
