# TTM 앱 컬러 통합 작업 리스트

## 📋 작업 개요

- **목표**: 모든 화면의 하드코딩된 색상을 AppColors 팔레트로 통합
- **원칙**:
  1. 기능적 색상 유지 (삭제: 빨강, 경고: 오렌지, 소셜 로그인 브랜드 색상)
  2. 흰색 배경/카드는 `AppColors.background` or `AppColors.softBackground`
  3. 회색 텍스트는 `AppColors.textSecondary`
  4. 구분선/테두리는 `AppColors.divider` or `AppColors.borderLight`
  5. 브랜드 액센트는 `AppColors.primary`

---

## ✅ 완료된 파일 (3개)

1. [x] **stats_screen.dart** - purple → AppColors.primary
2. [x] **ai_coach_screen.dart** - purple/blue 그라디언트 → AppColors.primary/primaryDark
3. [x] **exercise_detail_screen.dart** - blue → AppColors.primary

---

## 🔄 진행 중인 파일 (29개)

### 우선순위 1: 핵심 화면 (8개)

4. [ ] **home_screen.dart** - 색상 많음 (200+ 인스턴스)
   - Colors.grey[100~700] → AppColors.textSecondary / AppColors.background
   - Colors.white → AppColors.background
   - Color(0xFF1DB954) → 이미 AppColors.primary 사용 중 (유지)
   - Colors.red → AppColors.error (삭제 버튼)
   - Colors.orange/blue (차트) → AppColors.carbs/protein/fat

5. [ ] **activity_detail_screen.dart**
   - Colors.orange → AppColors.warning (운동 아이콘)
   - Colors.grey → AppColors.textSecondary
   - Colors.white → AppColors.background
   - Colors.red (좋아요) → 유지

6. [ ] **community_home_screen.dart**
   - 이미 AppColors 사용 중인지 확인 필요
   - Colors.grey → AppColors.textSecondary

7. [ ] **profile_screen.dart**
   - Color(0xFF1DB954) → 이미 사용 중 (유지)
   - Colors.grey → AppColors.textSecondary
   - AppBar 배경 확인

8. [ ] **calendar_screen.dart**
   - Color(0xFF1DB954) → AppColors.primary
   - Color(0xFFFF6B6B) → AppColors.error (경고 점수)
   - Colors.grey → AppColors.textSecondary

9. [ ] **create_post_screen.dart**
   - Color(0xFF2196F3), Color(0xFFF44336) 등 → 카테고리별 색상 (유지 or AppColors)

10. [ ] **meal_detail_screen.dart**
    - Colors.green → AppColors.primary
    - Colors.orange (차트) → AppColors.fat
    - Colors.blue/red/amber → AppColors.carbs/protein/fat

11. [ ] **post_detail_screen.dart**
    - Color(0xFF1DB954) 확인
    - Colors.grey → AppColors.textSecondary

### 우선순위 2: 서브 화면 (11개)

12. [ ] **login_screen.dart**
    - Colors.grey[50, 300, 600] → AppColors
    - Colors.black87 → AppColors.textPrimary
    - 소셜 로그인 색상 → 유지 (kakao, naver, google)

13. [ ] **splash_screen.dart**
    - Colors.white → 유지 (로딩 화면)

14. [ ] **onboarding_screen.dart** (이미 AppColors 사용 중?)

15. [ ] **survey/survey_screen.dart**
    - Color(0xFFFF9800) 오렌지 → AppColors.warning (알레르기)
    - Colors.grey → AppColors.textSecondary

16. [ ] **survey/welcome_screen.dart**

17. [ ] **main_screen.dart**
    - Color(0xFF4285F4, 0xFF9B72CB, 0xFFD96570) → 카테고리 색상 (유지?)
    - Colors.grey → AppColors.textSecondary

18. [ ] **calorie_detail_popup.dart**
    - Color(0xFF1DB954) → AppColors.primary
    - Colors.blue/orange/red → AppColors.carbs/protein/fat
    - Colors.grey → AppColors.textSecondary

19. [ ] **friends_list_screen.dart**
    - Colors.grey → AppColors.textSecondary
    - Colors.red → AppColors.error (삭제)

20. [ ] **exercise_add_screen.dart**
    - Colors.blue → AppColors.primary
    - Colors.orange/purple/green → 운동 종류별 (유지 or 통합?)

21. [ ] **help_screen.dart**
    - Colors.grey → AppColors.textSecondary

22. [ ] **settings/profile_edit_screen.dart**
    - Color(0xFF1DB954) → AppColors.primary

### 우선순위 3: 카메라/AI 화면 (3개)

23. [ ] **meal/camera_meal_screen.dart**
    - Colors.black/white → 카메라 UI (유지)
    - Colors.grey → AppColors.textSecondary
    - Color(0xFF1DB954) → AppColors.primary

24. [ ] **meal/ai_analysis_result_screen.dart**
    - Color(0xFF4285F4, 0xFF9B72CB, 0xFFD96570) → 카테고리 (유지?)
    - Color(0xFF6C5CE7) 보라색 → AppColors.focusAccent
    - Color(0xFF1DB954) → AppColors.primary

25. [ ] **meal_add_screen.dart** (있다면)

### 우선순위 4: 설정 화면 (4개)

26. [ ] **settings_screen.dart**
27. [ ] **settings/feedback_screen.dart** - Color(0xFF1DB954) → AppColors.primary
28. [ ] **settings/language_settings_screen.dart** - Color(0xFF1DB954) → AppColors.primary
29. [ ] **settings/notifications_settings_screen.dart** (있다면)

---

## 📊 색상 매핑 가이드

### 변경 필수

| 기존 색상            | 용도          | AppColors 대체           |
| -------------------- | ------------- | ------------------------ |
| Colors.grey[100]     | 배경          | AppColors.softBackground |
| Colors.grey[200]     | 테두리/구분선 | AppColors.borderLight    |
| Colors.grey[300]     | 테두리        | AppColors.divider        |
| Colors.grey[400~600] | 보조 텍스트   | AppColors.textSecondary  |
| Colors.grey[700~800] | 주요 텍스트   | AppColors.textPrimary    |
| Colors.white         | 카드 배경     | AppColors.background     |
| Colors.black87       | 주요 텍스트   | AppColors.textPrimary    |
| Colors.black54       | 보조 텍스트   | AppColors.textSecondary  |
| Color(0xFF1DB954)    | 브랜드 색상   | AppColors.primary        |

### 기능적 색상 (유지)

| 기존 색상            | 용도          | AppColors 대체    |
| -------------------- | ------------- | ----------------- |
| Colors.red           | 삭제/오류     | AppColors.error   |
| Colors.orange        | 경고          | AppColors.warning |
| Colors.blue (차트)   | 탄수화물      | AppColors.carbs   |
| Colors.orange (차트) | 단백질        | AppColors.protein |
| Colors.amber (차트)  | 지방          | AppColors.fat     |
| Color(0xFFFEE500)    | 카카오 로그인 | AppColors.kakao   |
| Color(0xFF03C75A)    | 네이버 로그인 | AppColors.naver   |
| Color(0xFF4285F4)    | 구글 로그인   | AppColors.google  |

### 특수 케이스

| 화면                     | 기존 색상                          | 결정              |
| ------------------------ | ---------------------------------- | ----------------- |
| main_screen.dart         | 0xFF4285F4, 0xFF9B72CB, 0xFFD96570 | 카테고리별 유지?  |
| create_post_screen.dart  | 여러 컬러                          | 태그 색상 유지?   |
| exercise_add_screen.dart | orange/blue/purple/green           | 운동 종류별 유지? |

---

## 🎯 다음 단계

1. home_screen.dart부터 시작 (가장 복잡)
2. 각 파일마다 변경사항 multi_replace로 일괄 적용
3. 변경 완료 후 이 문서 업데이트
4. 최종 커밋
