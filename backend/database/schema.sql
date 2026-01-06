-- TTM 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS ttm_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ttm_db;

-- 사용자 테이블 (members)
CREATE TABLE IF NOT EXISTS members (
  member_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '회원 ID',
  login_id VARCHAR(50) UNIQUE NOT NULL COMMENT '로그인 아이디',
  nickname VARCHAR(50) UNIQUE NULL COMMENT '닉네임',
  password_hash VARCHAR(255) NOT NULL COMMENT '비밀번호 해시',
  email VARCHAR(100) UNIQUE NOT NULL COMMENT '이메일',
  member_name VARCHAR(100) NOT NULL COMMENT '이름',
  phone_number VARCHAR(20) NULL COMMENT '핸드폰 번호',
  birth_date DATE NULL COMMENT '생년월일',
  gender VARCHAR(1) NULL COMMENT '성별 (M/F)',
  region VARCHAR(50) DEFAULT '서울' COMMENT '지역',
  member_status VARCHAR(20) DEFAULT 'ACTIVE' COMMENT '회원 상태',
  terms_agreed TINYINT(1) DEFAULT 0 COMMENT '약관 동의',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '가입일',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
  deleted_at TIMESTAMP NULL COMMENT '삭제일',
  last_login TIMESTAMP NULL COMMENT '마지막 로그인',
  INDEX idx_login_id (login_id),
  INDEX idx_nickname (nickname),
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테스트 사용자 추가 (비밀번호: Test1234!@)
-- bcrypt 해시값
INSERT INTO members (login_id, nickname, email, password_hash, member_name, phone_number, birth_date, gender, region, member_status, terms_agreed) VALUES 
('test', '테스터', 'test@test.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5lBjFYVJP3NmW', '테스트사용자', '010-1234-5678', '1990-01-01', 'M', '서울', 'ACTIVE', 1),
('admin', '관리자', 'admin@ttm.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5lBjFYVJP3NmW', '관리자', '010-9999-9999', '1985-05-15', 'M', '서울', 'ACTIVE', 1);

-- 확인
SELECT member_id, login_id, nickname, email, member_name, phone_number, birth_date, created_at FROM members;
