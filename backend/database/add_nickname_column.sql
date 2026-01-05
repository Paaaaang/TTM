-- members 테이블에 nickname 컬럼 추가
ALTER TABLE members 
ADD COLUMN nickname VARCHAR(50) NULL COMMENT '닉네임' AFTER member_name;

-- nickname에 인덱스 추가 (중복 확인 성능 향상)
CREATE INDEX idx_nickname ON members(nickname);

-- 기존 데이터에 임시 닉네임 설정 (선택사항)
-- UPDATE members SET nickname = CONCAT('user_', member_id) WHERE nickname IS NULL;
