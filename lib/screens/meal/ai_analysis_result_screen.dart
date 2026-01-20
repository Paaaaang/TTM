import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ttm/services/ai_service.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/services/meal_service.dart';
import 'package:ttm/screens/ai_coach_screen.dart';

/// AI 분석 결과 화면 - 수정 가능
class AIAnalysisResultScreen extends StatefulWidget {
  final XFile imageFile;
  final String? mealType; // 선택된 식사 유형
  
  const AIAnalysisResultScreen({
    super.key,
    required this.imageFile,
    this.mealType,
  });

  @override
  State<AIAnalysisResultScreen> createState() => _AIAnalysisResultScreenState();
}

class _AIAnalysisResultScreenState extends State<AIAnalysisResultScreen> {
  late TextEditingController _foodNameController;
  late TextEditingController _caloriesController;
  late TextEditingController _carbsController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _sugarController;
  late TextEditingController _sodiumController;
  
  // 수정 모드 상태
  bool _isEditing = false;
  
  // 초기값 저장 (취소 시 복원용)
  late String _originalFoodName;
  late String _originalCalories;
  late String _originalCarbs;
  late String _originalProtein;
  late String _originalFat;
  late String _originalSugar;
  late String _originalSodium;
  
  // AI 분석 경고 텍스트
  String _warningText = '사용자의 건강 정보를 바탕으로 주의사항을 분석 중입니다...';
  
  // AI 분석 데이터 로딩 상태 (통합)
  bool _isLoadingAnalysis = true;

  // 최근 7일 요약 문구
  bool _isLoadingRecentSummary = true;
  List<String> _recentSummaryLines = [];

  @override
  void initState() {
    super.initState();
    
    // 컨트롤러 초기화 (빈 값으로)
    _foodNameController = TextEditingController();
    _caloriesController = TextEditingController();
    _carbsController = TextEditingController();
    _proteinController = TextEditingController();
    _fatController = TextEditingController();
    _sugarController = TextEditingController();
    _sodiumController = TextEditingController();
    
    // AI 분석 시작
    _performAIAnalysis();
  }
  
  /// AI 이미지 분석 수행
  Future<void> _performAIAnalysis() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }
      
      setState(() {
        _isLoadingAnalysis = true;
      });
      
      // AI 분석 API 호출 (XFile 직접 전달)
      final result = await MealService().analyzeMealImage(
        imageFile: widget.imageFile,
        memberId: user.memberId,
        mealType: widget.mealType ?? 'SNACK',
      );
      
      if (result['success'] == true && result['foods'] is List && (result['foods'] as List).isNotEmpty) {
        final firstFood = (result['foods'] as List)[0] as Map<String, dynamic>;
        
        // AI 분석 결과로 컨트롤러 업데이트
        _foodNameController.text = firstFood['food_name']?.toString() ?? '알 수 없음';
        // 칼로리는 정수로 변환 (소수점 제거)
        final calories = (firstFood['calories_kcal'] ?? 0).toDouble();
        _caloriesController.text = calories.round().toString();
        _carbsController.text = (firstFood['carbohydrates_g'] ?? 0.0).toStringAsFixed(1);
        _proteinController.text = (firstFood['protein_g'] ?? 0.0).toStringAsFixed(1);
        _fatController.text = (firstFood['fat_g'] ?? 0.0).toStringAsFixed(1);
        _sugarController.text = (firstFood['sugars_g'] ?? 0.0).toStringAsFixed(1);
        _sodiumController.text = (firstFood['sodium_mg'] ?? 0.0).toStringAsFixed(0);
        
        // 초기값 저장
        _saveOriginalValues();
        
        // AI 경고 분석 시작
        _fetchAIAnalysis();

        // 최근 7일 요약 가져오기
        _fetchRecentSummary(user.memberId);
        
        setState(() {
          _isLoadingAnalysis = false;
        });
      } else {
        throw Exception(result['message'] ?? '음식을 인식할 수 없습니다');
      }
    } catch (e) {
      print('AI 분석 오류: $e');
      setState(() {
        _isLoadingAnalysis = false;
      });
      
      // 에러 다이얼로그 표시 (상세 정보 포함)
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('분석 실패'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('음식 분석에 실패했습니다.'),
                  const SizedBox(height: 12),
                  const Text(
                    '오류 내용:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context); // AI 분석 화면 닫기
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  Future<void> _fetchAIAnalysis() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        final warning = await AIService().getMealAnalysisWarning(
          user.memberId, 
          _foodNameController.text
        );
        if (mounted) {
          setState(() {
            _warningText = warning;
          });
        }
      }
    } catch (e) {
      print('AI Warning Error: $e');
      if (mounted) {
        setState(() {
          _warningText = '분석 정보를 불러오는 데 실패했습니다.';
        });
      }
    }
  }

  Future<void> _fetchRecentSummary(int memberId) async {
    try {
      setState(() {
        _isLoadingRecentSummary = true;
      });

      final stats = await MealService().getMealStats(memberId, days: 7);
      if (stats == null || stats.isEmpty) {
        setState(() {
          _recentSummaryLines = [
            '최근 7일 동안 저녁 단백질 섭취가 낮은 날이 많았어요.',
            '아침 식사를 기록한 날은 2일이에요.',
          ];
          _isLoadingRecentSummary = false;
        });
        return;
      }

      final breakfastDates = <String>{};
      int lowProteinDinnerDays = 0;

      for (final item in stats) {
        final mealType = item['meal_type']?.toString() ?? '';
        final mealDate = item['meal_date']?.toString() ?? '';
        final totalProtein = (item['total_protein'] ?? 0).toDouble();

        if (mealType == 'BREAKFAST' && mealDate.isNotEmpty) {
          breakfastDates.add(mealDate);
        }
        if (mealType == 'DINNER' && totalProtein < 20) {
          lowProteinDinnerDays += 1;
        }
      }

      setState(() {
        _recentSummaryLines = [
          lowProteinDinnerDays >= 3
              ? '최근 7일 동안 저녁 단백질 섭취가 낮은 날이 많았어요.'
              : '최근 7일 동안 저녁 단백질 섭취가 낮은 날은 ${lowProteinDinnerDays}일이에요.',
          '아침 식사를 기록한 날은 ${breakfastDates.length}일이에요.',
        ];
        _isLoadingRecentSummary = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentSummaryLines = [
            '최근 7일 동안 저녁 단백질 섭취가 낮은 날이 많았어요.',
            '아침 식사를 기록한 날은 2일이에요.',
          ];
          _isLoadingRecentSummary = false;
        });
      }
    }
  }

  String _buildAiCoachPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('현재 AI 분석 결과를 바탕으로 식단 코칭을 부탁해.');
    buffer.writeln('- 음식명: ${_foodNameController.text}');
    buffer.writeln('- 칼로리: ${_caloriesController.text} kcal');
    buffer.writeln('- 탄수화물: ${_carbsController.text} g');
    buffer.writeln('- 단백질: ${_proteinController.text} g');
    buffer.writeln('- 지방: ${_fatController.text} g');
    buffer.writeln('- 당류: ${_sugarController.text} g');
    buffer.writeln('- 나트륨: ${_sodiumController.text} mg');

    if (_recentSummaryLines.isNotEmpty) {
      buffer.writeln('최근 7일 요약:');
      for (final line in _recentSummaryLines) {
        buffer.writeln('- $line');
      }
    }
    return buffer.toString();
  }

  void _requestHelpToAICoach() {
    final prompt = _buildAiCoachPrompt();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AICoachScreen(initialPrompt: prompt),
      ),
    );
  }

  @override

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }
  
  void _saveOriginalValues() {
    _originalFoodName = _foodNameController.text;
    _originalCalories = _caloriesController.text;
    _originalCarbs = _carbsController.text;
    _originalProtein = _proteinController.text;
    _originalFat = _fatController.text;
    _originalSugar = _sugarController.text;
    _originalSodium = _sodiumController.text;
  }
  
  void _restoreOriginalValues() {
    setState(() {
      _foodNameController.text = _originalFoodName;
      _caloriesController.text = _originalCalories;
      _carbsController.text = _originalCarbs;
      _proteinController.text = _originalProtein;
      _fatController.text = _originalFat;
      _sugarController.text = _originalSugar;
      _sodiumController.text = _originalSodium;
      _isEditing = false;
    });
  }
  
  void _enableEditing() {
    setState(() {
      _isEditing = true;
    });
  }
  
  void _saveChanges() {
    setState(() {
      _saveOriginalValues();
      _isEditing = false;
    });
  }

  void _saveResult() {
    // 식단 데이터 구성
    final mealData = {
      'name': _foodNameController.text,
      'calories': int.tryParse(_caloriesController.text) ?? 0,
      'carbs': double.tryParse(_carbsController.text) ?? 0.0,
      'protein': double.tryParse(_proteinController.text) ?? 0.0,
      'fat': double.tryParse(_fatController.text) ?? 0.0,
      'sugar': double.tryParse(_sugarController.text) ?? 0.0,
      'sodium': double.tryParse(_sodiumController.text) ?? 0.0,
      'image': widget.imageFile.path,
      if (widget.mealType != null) 'mealType': widget.mealType, // 식사 유형 포함
    };
    
    print('AI 분석 결과 저장: $mealData'); // 디버깅용
    
    // 결과 화면 닫으면서 데이터 반환
    Navigator.pop(context, mealData);
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때 표시 (그라디언트 스타일)
    if (_isLoadingAnalysis) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4285F4),
                      Color(0xFF9B72CB),
                      Color(0xFFD96570),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'AI가 음식을 분석하고 있습니다...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '잠시만 기다려주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 분석 완료 후 결과 표시
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1DB954),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI 분석 결과',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 촬영된 이미지
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.black,
              child: kIsWeb
                  ? Image.network(
                      widget.imageFile.path,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.white70,
                          size: 64,
                        );
                      },
                    )
                  : Image.file(
                      File(widget.imageFile.path),
                      fit: BoxFit.contain,
                    ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'AI는 실수를 할 수 있습니다. 중요한 정보는 재차 확인하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 질병 & 알러지 주의사항
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목 행 (아이콘 + 제목)
                        Row(
                          children: [
                            Container(
                              width: 28,  // 30% 축소 (40 -> 28)
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6C5CE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: Colors.white,
                                size: 16,  // 30% 축소 (22 -> 16)
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'AI 요약',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C5CE7),
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _requestHelpToAICoach,
                              icon: const Icon(Icons.smart_toy_rounded, size: 16),
                              label: const Text('도움 요청하기'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6C5CE7),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 본문 내용
                        Text(
                          _warningText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,  // 폰트 굵기 추가
                            color: Colors.black,  // 더 진한 색상
                            height: 1.5,
                            fontFamily: 'Roboto',  // 명확한 폰트 지정
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey[300], height: 1),
                        const SizedBox(height: 12),
                        Text(
                          '최근 7일 요약',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingRecentSummary)
                          Text(
                            '요약을 불러오는 중...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _recentSummaryLines
                                .map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(fontSize: 12)),
                                        Expanded(
                                          child: Text(
                                            line,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[800],
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 음식 이름 & 수정 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '음식 이름',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (!_isEditing)
                        TextButton.icon(
                          onPressed: _enableEditing,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('수정'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1DB954),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        )
                      else
                        Row(
                          children: [
                            TextButton(
                              onPressed: _restoreOriginalValues,
                              child: const Text(
                                '취소',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: _saveChanges,
                              child: const Text(
                                '저장',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1DB954),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _foodNameController,
                    enabled: _isEditing,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _isEditing ? Colors.grey[50] : Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: _isEditing 
                          ? BorderSide(color: Colors.grey[300]!) 
                          : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: _isEditing 
                          ? BorderSide(color: Colors.grey[300]!) 
                          : BorderSide.none,
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 칼로리
                  const Text(
                    '칼로리',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _caloriesController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _isEditing ? Colors.grey[50] : Colors.transparent,
                      suffixText: 'kcal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: _isEditing 
                          ? BorderSide(color: Colors.grey[300]!) 
                          : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: _isEditing 
                          ? BorderSide(color: Colors.grey[300]!) 
                          : BorderSide.none,
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 영양 정보
                  const Text(
                    '영양 정보',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildNutrientField('탄수화물', _carbsController, Colors.blue),
                        const SizedBox(height: 12),
                        _buildNutrientField('단백질', _proteinController, Colors.orange),
                        const SizedBox(height: 12),
                        _buildNutrientField('지방', _fatController, Colors.red),
                        const SizedBox(height: 16),
                        // 당류 & 나트륨 (작게)
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallNutrientField('당류', _sugarController, 'g'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSmallNutrientField('나트륨', _sodiumController, 'mg'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saveResult,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '식단에 추가하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 취소 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        '다시 촬영하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientField(String label, TextEditingController controller, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              suffixText: 'g',
              isDense: true,
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: _isEditing 
                  ? BorderSide(color: Colors.grey[300]!) 
                  : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: _isEditing 
                  ? BorderSide(color: Colors.grey[300]!) 
                  : BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSmallNutrientField(String label, TextEditingController controller, String unit) {
    return Row(
      children: [
        // 라벨
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // 수치 입력 박스
        SizedBox(
          width: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _isEditing ? Colors.grey[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: _isEditing 
                ? Border.all(color: Colors.grey[300]!) 
                : null,
            ),
            child: TextField(
              controller: controller,
              enabled: _isEditing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                suffixText: unit,
                suffixStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
