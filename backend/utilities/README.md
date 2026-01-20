# TTM Backend Utilities

이 폴더는 개발 중 사용된 유틸리티 스크립트들을 보관합니다.

## 📁 폴더 구조

```
backend/utilities/
├── archives/              # 보관용 스크립트 (참고용)
│   ├── tests/            # API/기능 테스트 스크립트 (5개)
│   ├── audits/           # 시스템 점검 스크립트 (3개)
│   └── converters/       # 데이터 변환 스크립트 (3개)
├── migrations/           # DB 마이그레이션 파일 (4개)
└── README.md            # 이 파일
```

---

## 📦 Archives 폴더

개발 과정에서 사용된 스크립트들을 참고용으로 보관합니다.  
**프로덕션 환경에서는 사용하지 않습니다.**

### 🧪 archives/tests/ (5개)

API 및 기능 테스트 스크립트입니다. 새로운 기능 개발 시 참고할 수 있습니다.

| 파일 | 설명 | 라인 수 |
|------|------|---------|
| **test_db_connection.py** | DB 연결 및 meal 테이블 확인 | 141 |
| **test_ai_analyze.py** | AI 음식 분석 기능 테스트 | 51 |
| **test_health_api.py** | 건강 정보 API 테스트 | 85 |
| **test_post_13.py** | 게시글 기능 테스트 | 83 |
| **test_weight_api.py** | 체중 기록 API 테스트 | 36 |

#### 사용 예시
```bash
# DB 연결 테스트
python backend/utilities/archives/tests/test_db_connection.py

# AI 분석 테스트
python backend/utilities/archives/tests/test_ai_analyze.py
```

---

### 📊 archives/audits/ (3개)

시스템 전체 점검 및 감사 스크립트입니다. 프로젝트 구조 분석 시 참고할 수 있습니다.

| 파일 | 설명 | 라인 수 |
|------|------|---------|
| **system_audit.py** | TTM 시스템 전체 점검 (API, Frontend, Backend, DB 매칭) | 297 |
| **detailed_audit.py** | 상세 시스템 감사 | 252 |
| **verify_schema_mapping.py** | 스키마 매핑 검증 | 207 |

#### 주요 기능

**system_audit.py**:
- Backend API 엔드포인트 추출
- Frontend API 호출 추출
- DB 테이블/컬럼 분석
- API-Frontend-DB 매칭 상태 확인

**detailed_audit.py**:
- 코드 품질 분석
- 의존성 점검
- 성능 이슈 탐지

**verify_schema_mapping.py**:
- DB 스키마와 코드 모델 매핑 검증
- 누락된 필드 탐지

#### 사용 예시
```bash
# 시스템 전체 점검
python backend/utilities/archives/audits/system_audit.py

# 상세 감사
python backend/utilities/archives/audits/detailed_audit.py

# 스키마 검증
python backend/utilities/archives/audits/verify_schema_mapping.py
```

---

### 🔄 archives/converters/ (3개)

데이터 변환 및 조회 스크립트입니다.

| 파일 | 설명 | 라인 수 |
|------|------|---------|
| **convert_food_to_dart.py** | 음식 데이터를 Dart 코드로 변환 | 107 |
| **read_food_excel.py** | 영양 DB Excel 파일 읽기 | 48 |
| **list_badges.py** | 배지 목록 조회 | 14 |

#### 주요 기능

**convert_food_to_dart.py**:
- `nutrition_db.xlsx` → Dart 코드 변환
- 음식 자동 카테고리 분류 (밥류, 국/찌개, 고기/생선 등)
- Flutter 앱에서 사용할 수 있는 FoodItem 리스트 생성

**read_food_excel.py**:
- Excel 영양 DB 읽기 및 조회
- 음식명으로 영양소 검색

**list_badges.py**:
- DB에서 배지 목록 조회
- 배지 ID, 이름, 설명 출력

#### 사용 예시
```bash
# Dart 코드 생성
python backend/utilities/archives/converters/convert_food_to_dart.py > food_database.dart

# 영양 DB 조회
python backend/utilities/archives/converters/read_food_excel.py

# 배지 목록 조회
python backend/utilities/archives/converters/list_badges.py
```

---

## 🗄️ Migrations 폴더 (4개)

데이터베이스 스키마 변경 및 성능 개선 SQL/Python 스크립트입니다.

| 파일 | 설명 | 라인 수 |
|------|------|---------|
| **create_weight_log.sql** | weight_log 테이블 생성 | 13 |
| **add_allergy_tables.sql** | 알레르기 관련 테이블 추가 | 29 |
| **add_missing_columns.py** | 누락된 컬럼 추가 (Python) | 55 |
| **add_performance_indexes.sql** | 성능 최적화 인덱스 추가 | 42 |

### 마이그레이션 적용 방법

#### SQL 마이그레이션
```bash
# MySQL 접속 후 실행
mysql -u we0123 -p we0123 < backend/utilities/migrations/create_weight_log.sql
mysql -u we0123 -p we0123 < backend/utilities/migrations/add_allergy_tables.sql
mysql -u we0123 -p we0123 < backend/utilities/migrations/add_performance_indexes.sql
```

#### Python 마이그레이션
```bash
# Python 스크립트 실행
python backend/utilities/migrations/add_missing_columns.py
```

### 마이그레이션 내역

#### 1. create_weight_log.sql
```sql
-- weight_log 테이블 생성
-- 체중 기록 추적용 (member_id, weight_kg, measured_at)
```

#### 2. add_allergy_tables.sql
```sql
-- allergy 테이블 생성 (알레르기 종류)
-- member_allergy 테이블 생성 (회원별 알레르기)
```

#### 3. add_missing_columns.py
```python
# members 테이블에 fcm_token, fasting 컬럼 추가
# post 테이블에 comment_count, likes_count 컬럼 추가
```

#### 4. add_performance_indexes.sql
```sql
-- 성능 최적화 인덱스 추가
-- meal_log(member_id, meal_date)
-- exercise_log(member_id, exercise_date)
-- post(member_id, created_at)
-- comment(post_id, created_at)
```

---

## 🗑️ 정리 내역 (2026-01-15)

### 제거된 파일 (21개)

개발 완료 후 더 이상 사용하지 않는 일회성 점검/디버깅 스크립트를 제거했습니다.

#### DB 스키마 체크 파일 (13개)
- check_all_schemas.py
- check_badge_conditions.py
- check_badge_status.py
- check_comments_schema.py
- check_created_at.py
- check_db_integration.py
- check_db_issues.py
- check_exercise_table.py
- check_meal_schema.py
- check_members_schema.py
- check_nutrition_db.py
- check_post_schema.py
- check_tables.py

#### 디버그 파일 (8개)
- check_gun_badges.py
- check_posts.py
- check_users.py
- check_weight_data.py
- check_weight_log.py
- debug_gunsi_badges.py
- debug_import.py
- debug_posts.py

**제거 이유**:
- 모두 개발 중 DB 스키마 확인 및 디버깅용 일회성 스크립트
- 현재 시스템이 안정화되어 더 이상 사용하지 않음
- 필요 시 Git 히스토리에서 복원 가능

---

## 📊 정리 전후 비교

| 항목 | 정리 전 | 정리 후 | 변경 |
|------|---------|---------|------|
| **전체 파일 수** | 32개 | 16개 | -16개 (-50%) |
| **루트 파일** | 28개 | 1개 (README.md) | -27개 |
| **archives/** | - | 11개 | +11개 (보관) |
| **migrations/** | 4개 | 4개 | 유지 |

### 정리 효과

✅ **구조 단순화**: 루트에 28개 파일 → 1개 파일 (README.md)  
✅ **용도 명확화**: archives (보관), migrations (마이그레이션)으로 분리  
✅ **유지보수성 향상**: 필요한 파일만 루트에 유지  
✅ **참고자료 보존**: 테스트/감사/변환 스크립트는 archives에 보관

---

## 🚀 사용 가이드

### 새로운 마이그레이션 추가

```bash
# 1. migrations 폴더에 SQL 또는 Python 파일 생성
backend/utilities/migrations/add_new_feature.sql

# 2. 마이그레이션 실행
mysql -u we0123 -p we0123 < backend/utilities/migrations/add_new_feature.sql

# 3. 실행 내역 기록 (README.md 업데이트)
```

### 테스트 스크립트 참고

```bash
# archives/tests/ 폴더의 스크립트 참고
# 새로운 API 테스트 작성 시 기존 패턴 활용
```

### 시스템 점검

```bash
# archives/audits/ 폴더의 감사 스크립트 실행
python backend/utilities/archives/audits/system_audit.py
```

---

## 📝 주의사항

⚠️ **archives 폴더의 스크립트는 참고용입니다**
- 프로덕션 환경에서 실행하지 마세요
- DB 연결 정보가 하드코딩되어 있을 수 있습니다
- 실행 전 코드를 검토하세요

⚠️ **마이그레이션 실행 시 백업 필수**
- 마이그레이션 실행 전 DB 백업
- 개발 환경에서 먼저 테스트
- 프로덕션 적용 시 점진적 롤아웃

⚠️ **Git에서 제거된 파일 복원**
```bash
# 제거된 파일이 필요한 경우 Git 히스토리에서 복원
git log --all --full-history -- backend/utilities/check_*.py
git checkout <commit-hash> -- backend/utilities/check_all_schemas.py
```

---

## 🔗 관련 문서

- [DATABASE.md](../database/DATABASE.md) - 데이터베이스 스키마 및 가이드
- [ROUTERS_README.md](../routers/ROUTERS_README.md) - API 엔드포인트 문서
- [SERVICES_README.md](../services/SERVICES_README.md) - 서비스 레이어 문서
- [utilities_정리_보고서_2026-01-15.md](../docs/utilities_정리_보고서_2026-01-15.md) - 정리 보고서

---

**최종 업데이트**: 2026-01-15  
**정리 담당**: GitHub Copilot
