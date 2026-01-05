-- TTM 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS ttm_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ttm_db;

-- 사용자 테이블
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL COMMENT '아이디',
  nickname VARCHAR(50) UNIQUE NOT NULL COMMENT '닉네임',
  password VARCHAR(255) NOT NULL COMMENT '비밀번호 (해시)',
  email VARCHAR(100) UNIQUE NOT NULL COMMENT '이메일',
  name VARCHAR(100) NOT NULL COMMENT '이름',
  phone VARCHAR(20) NULL COMMENT '핸드폰 번호',
  birthdate DATE NULL COMMENT '생년월일',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '가입일',
  last_login TIMESTAMP NULL COMMENT '마지막 로그인',
  INDEX idx_username (username),
  INDEX idx_nickname (nickname),
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테스트 사용자 추가 (비밀번호: Test1234!@)
-- bcrypt 해시값
INSERT INTO users (username, nickname, password, email, name, phone, birthdate) VALUES 
('test', '테스터', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5lBjFYVJP3NmW', 'test@test.com', '테스트사용자', '010-1234-5678', '1990-01-01'),
('admin', '관리자', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5lBjFYVJP3NmW', 'admin@ttm.com', '관리자', '010-9999-9999', '1985-05-15');

-- 확인
SELECT id, username, nickname, email, name, phone, birthdate, created_at FROM users;
