// 캘린더 화면 - 월별 식단/운동 기록 확인
import 'package:flutter/material.dart';
import 'package:ttm/constants/app_colors.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ttm/constants/api_config.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// 현재 선택된 월
  DateTime _currentMonth = DateTime.now();
  
  /// 선택된 날짜
  DateTime? _selectedDate;
  
  /// 서비스
  final AuthService _authService = AuthService();
  
  /// 현재 사용자
  User? _currentUser;
  
  /// 날짜별 영양 점수 (날짜 -> 점수)
  Map<String, int> _nutritionScores = {};
  
  /// 로딩 상태
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  /// 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
      _loadMonthScores();
    }
  }
  
  /// 월별 영양 점수 로드
  Future<void> _loadMonthScores() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl(
          '/api/meals/nutrition-scores/${_currentUser!.memberId}'
          '?year=${_currentMonth.year}&month=${_currentMonth.month}'
        )),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scores = data['scores'] as Map<String, dynamic>;
        
        if (mounted) {
          setState(() {
            _nutritionScores = scores.map((key, value) {
              // JSON에서 받은 숫자를 안전하게 int로 변환
              if (value is int) return MapEntry(key, value);
              if (value is double) return MapEntry(key, value.toInt());
              if (value is num) return MapEntry(key, value.toInt());
              return MapEntry(key, 0);
            });
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load nutrition scores');
      }
    } catch (e) {
      print('월별 영양 점수 로드 오류: $e');
      if (mounted) {
        setState(() {
          _nutritionScores = {};
          _isLoading = false;
        });
      }
    }
  }
  
  /// 이전 달로 이동
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadMonthScores();
  }
  
  /// 다음 달로 이동
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadMonthScores();
  }
  
  /// 날짜 선택
  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    // 선택된 날짜로 홈 화면으로 돌아가기
    Navigator.pop(context, date);
  }
  
  /// 해당 월의 첫 번째 날
  DateTime get _firstDayOfMonth {
    return DateTime(_currentMonth.year, _currentMonth.month, 1);
  }
  
  /// 해당 월의 마지막 날
  DateTime get _lastDayOfMonth {
    return DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
  }
  
  /// 캘린더 그리드 생성
  List<DateTime?> get _calendarDays {
    List<DateTime?> days = [];
    
    // 첫 번째 날의 요일 (일요일=7, 월요일=1)
    int firstWeekday = _firstDayOfMonth.weekday;
    
    // 일요일을 0으로 만들기 (월요일=1 -> 일요일=0)
    if (firstWeekday == 7) firstWeekday = 0;
    
    // 앞쪽 빈 칸 추가
    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }
    
    // 날짜 추가
    for (int day = 1; day <= _lastDayOfMonth.day; day++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '캘린더',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 월 선택 헤더
          _buildMonthHeader(),
          // 요일 헤더
          _buildWeekdayHeader(),
          // 캘린더 그리드
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }
  
  /// 월 선택 헤더
  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            color: Colors.black87,
          ),
          Text(
            '${_currentMonth.year}년 ${_currentMonth.month}월',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
  
  /// 요일 헤더
  Widget _buildWeekdayHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: day == '일' 
                      ? Colors.red[400]
                      : day == '토'
                          ? Colors.blue[400]
                          : Colors.grey[700],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  /// 캘린더 그리드
  Widget _buildCalendarGrid() {
    final days = _calendarDays;
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.75,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        if (date == null) {
          return const SizedBox();
        }
        
        return _buildDayCell(date);
      },
    );
  }
  
  /// 날짜 셀
  Widget _buildDayCell(DateTime date) {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final score = _nutritionScores[dateKey] ?? 0;
    final hasScore = score > 0;
    
    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;
    
    final isSelected = _selectedDate?.year == date.year &&
        _selectedDate?.month == date.month &&
        _selectedDate?.day == date.day;
    
    // 영양 점수 기반 채우기 비율 (0~100점 기준)
    final fillRatio = hasScore ? (score / 100).clamp(0.0, 1.0) : 0.0;
    
    // 점수에 따른 색상 변경
    Color scoreColor;
    if (score >= 80) {
      scoreColor = const Color(0xFF1DB954); // 녹색 (우수)
    } else if (score >= 60) {
      scoreColor = AppColors.primary; // 양호
    } else if (score >= 40) {
      scoreColor = const Color(0xFFFFA726); // 주황색 (보통)
    } else {
      scoreColor = const Color(0xFFFF6B6B); // 빨간색 (개선 필요)
    }
    
    return GestureDetector(
      onTap: () => _selectDate(date),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? const Color(0xFF1DB954)
                : Colors.grey[200]!,
            width: isToday ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            children: [
              // 배경 (흰색)
              Container(
                color: Colors.white,
              ),
              
              // 채우기 (하단에서 상단으로 그라데이션)
              if (hasScore)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: fillRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            scoreColor.withOpacity(0.7),
                            scoreColor.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // 선택 효과
              if (isSelected)
                Container(
                  color: const Color(0xFF1DB954).withOpacity(0.1),
                ),
              
              // 날짜 텍스트 (중앙 상단)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Text(
                  '${date.day}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    color: isToday
                        ? const Color(0xFF1DB954)
                        : Colors.black87,
                  ),
                ),
              ),

              // 영양 점수 텍스트 (하단)
              if (hasScore)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Text(
                    '${score}점',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: fillRatio > 0.5 ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
