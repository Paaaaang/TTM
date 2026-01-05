const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

// 회원가입
router.post('/signup', [
  body('username').trim().isLength({ min: 3 }).withMessage('아이디는 최소 3자 이상이어야 합니다'),
  body('password').isLength({ min: 4 }).withMessage('비밀번호는 최소 4자 이상이어야 합니다'),
  body('email').isEmail().withMessage('유효한 이메일을 입력하세요'),
  body('name').trim().notEmpty().withMessage('이름을 입력하세요')
], async (req, res) => {
  try {
    // 유효성 검사
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password, email, name } = req.body;

    // 중복 체크
    const [existing] = await db.query(
      'SELECT id FROM users WHERE username = ? OR email = ?',
      [username, email]
    );

    if (existing.length > 0) {
      return res.status(409).json({ error: '이미 존재하는 아이디 또는 이메일입니다' });
    }

    // 비밀번호 해싱
    const hashedPassword = await bcrypt.hash(password, 10);

    // 사용자 생성
    const [result] = await db.query(
      'INSERT INTO users (username, password, email, name) VALUES (?, ?, ?, ?)',
      [username, hashedPassword, email, name]
    );

    const userId = result.insertId;

    // 사용자 정보 반환 (비밀번호 제외)
    const user = {
      id: userId.toString(),
      username,
      email,
      name
    };

    res.status(201).json({ user });
  } catch (error) {
    console.error('회원가입 오류:', error);
    res.status(500).json({ error: '회원가입 중 오류가 발생했습니다' });
  }
});

// 로그인
router.post('/login', [
  body('username').trim().notEmpty().withMessage('아이디를 입력하세요'),
  body('password').notEmpty().withMessage('비밀번호를 입력하세요')
], async (req, res) => {
  try {
    // 유효성 검사
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password } = req.body;

    // 사용자 조회
    const [users] = await db.query(
      'SELECT id, username, password, email, name FROM users WHERE username = ?',
      [username]
    );

    if (users.length === 0) {
      return res.status(401).json({ error: '아이디 또는 비밀번호가 일치하지 않습니다' });
    }

    const user = users[0];

    // 비밀번호 검증
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: '아이디 또는 비밀번호가 일치하지 않습니다' });
    }

    // JWT 토큰 생성
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      process.env.JWT_SECRET || 'your_jwt_secret',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    // 마지막 로그인 시간 업데이트
    await db.query(
      'UPDATE users SET last_login = NOW() WHERE id = ?',
      [user.id]
    );

    // 사용자 정보 반환 (비밀번호 제외)
    const userResponse = {
      id: user.id.toString(),
      username: user.username,
      email: user.email,
      name: user.name
    };

    res.json({ user: userResponse, token });
  } catch (error) {
    console.error('로그인 오류:', error);
    res.status(500).json({ error: '로그인 중 오류가 발생했습니다' });
  }
});

// 로그아웃 (선택적 - 클라이언트에서 토큰 삭제로 처리 가능)
router.post('/logout', (req, res) => {
  res.json({ message: '로그아웃 되었습니다' });
});

module.exports = router;
