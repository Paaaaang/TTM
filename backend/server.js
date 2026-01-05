const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 3000;

// 미들웨어
app.use(cors()); // CORS 활성화 (Flutter 앱에서 접근 가능)
app.use(express.json()); // JSON 파싱
app.use(express.urlencoded({ extended: true }));

// 라우트
app.use('/api/auth', authRoutes);

// 기본 라우트
app.get('/', (req, res) => {
  res.json({ message: 'TTM Backend API Server is running!' });
});

// 404 에러 핸들러
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// 에러 핸들러
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 서버 시작
app.listen(PORT, () => {
  console.log(`🚀 서버가 포트 ${PORT}에서 실행 중입니다`);
  console.log(`📍 http://localhost:${PORT}`);
});
