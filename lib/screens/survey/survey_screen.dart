import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ttm/constants/api_constants.dart'; // Assuming this exists or I'll use hardcoded for now then fix.

class SurveyScreen extends StatefulWidget {
  final int memberId;

  const SurveyScreen({super.key, required this.memberId});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // State Data
  String? _gender;
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  List<String> _diseases = [];
  
  String? _exerciseLevel;
  String? _sleepDuration;

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validation
    if (_currentPage == 0) {
      if (_gender == null || _heightController.text.isEmpty || _weightController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요.')));
        return;
      }
    } else if (_currentPage == 1) {
       // Disease selection is optional or has 'none', so usually technically valid if list is empty?
       // UI shows 'none' option. Let's force at least one selection even if it is 'none'.
       if (_diseases.isEmpty) {
         // Maybe allow empty as none? Let's check UI behavior. Usually better to require explicit choice.
         // For now, allow empty as "Not selected" -> prompt user.
       }
    } else if (_currentPage == 2) {
      if (_exerciseLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('운동량을 선택해주세요.')));
        return;
      }
    } else if (_currentPage == 3) {
      if (_sleepDuration == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수면시간을 선택해주세요.')));
        return;
      }
      _submitSurvey();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitSurvey() async {
    setState(() => _isLoading = true);
    
    // Prepare Data - DB 스키마에 맞게 매핑
    final body = {
      "gender": _gender,  // 'M', 'F', 'O'
      "height": double.parse(_heightController.text),  // height_cm (decimal)
      "weight": double.parse(_weightController.text),  // weight_kg (decimal)
      "diseases": _diseases,  // diseases (text, CSV)
      "exercise_frequency": _exerciseLevel,  // activity_level (ENUM: LOW/NORMAL/HIGH)
      "sleep_duration": _sleepDuration,  // sleep_pattern (ENUM: REGULAR/IRREGULAR/SHORT/LONG)
    };

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.memberHealth(widget.memberId)}');
      
      print('API 요청: PUT $url');
      print('요청 데이터: ${jsonEncode(body)}');
      
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 응답 시간 초과');
        },
      );

      print('응답 코드: ${response.statusCode}');
      print('응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        // Success -> Go Home
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류 발생: ${response.statusCode} - ${response.body}')),
          );
        }
      }
    } catch (e) {
      print('에러 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네트워크 오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                      _buildStep4(),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _currentPage == 3 ? '완료' : '다음',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton.icon(
                  onPressed: _prevPage,
                  icon: const Icon(Icons.arrow_back, color: Colors.grey),
                  label: const Text('뒤로 가기', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Step 1: Basic Info ---
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Text('기본 정보를 알려주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('더 정확한 영양 분석을 위해 필요해요', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 48),

          // Gender
          const Align(alignment: Alignment.centerLeft, child: Text('성별', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildGenderButton('M', '남성')),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderButton('F', '여성')),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderButton('O', '기타')),
            ],
          ),
          const SizedBox(height: 24),

          // Height
          const Align(alignment: Alignment.centerLeft, child: Text('키 (cm)', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '예: 170',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),

          // Weight
          const Align(alignment: Alignment.centerLeft, child: Text('몸무게 (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '예: 65',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String value, String label) {
    bool isSelected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white, // green-50
          border: Border.all(
            color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF388E3C) : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // --- Step 2: Diseases ---
  Widget _buildStep2() {
    final options = [
      {'id': 'hypertension', 'label': '고혈압'},
      {'id': 'diabetes', 'label': '당뇨'},
      {'id': 'obesity', 'label': '비만'},
      {'id': 'hyperlipidemia', 'label': '고지혈증'},
      {'id': 'heart-disease', 'label': '심장 질환'},
      {'id': 'kidney-disease', 'label': '신장 질환'},
      {'id': 'allergy', 'label': '알러지'},
      {'id': 'none', 'label': '해당 없음'},
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text('질병 유무를 알려주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('맞춤 영양 관리를 위해 필요해요', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            const Text('중복 선택 가능', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 48),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((opt) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 64 - 12) / 2, // 2 columns
                  child: _buildDiseaseButton(opt['id']!, opt['label']!),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseButton(String id, String label) {
    bool isSelected = _diseases.contains(id);
    return InkWell(
      onTap: () {
        setState(() {
          if (id == 'none') {
            if (isSelected) {
              _diseases.clear(); // Toggle off none -> clear all? or just none? Usually none means none.
            } else {
              _diseases = ['none'];
            }
          } else {
            _diseases.remove('none'); // Selecting others clears none
            if (isSelected) {
              _diseases.remove(id);
            } else {
              _diseases.add(id);
            }
          }
        });
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF388E3C) : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // --- Step 3: Exercise ---
  Widget _buildStep3() {
    final options = [
      {'id': 'none', 'label': '아예 안함', 'desc': '운동을 하지 않아요'},
      {'id': 'light', 'label': '주 1-2회', 'desc': '거의 안함'},
      {'id': 'moderate', 'label': '주 3-4회', 'desc': '자주함'},
      {'id': 'active', 'label': '매일', 'desc': '꾸준히 운동해요'},
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text('운동량을 알려주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('맞춤 칼로리 계산을 도와드려요', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 48),

            ...options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildOptionCard(
                opt['id']!,
                opt['label']!,
                opt['desc']!,
                _exerciseLevel,
                (val) => setState(() => _exerciseLevel = val),
              ),
            )),
          ],
        ),
      ),
    );
  }

  // --- Step 4: Sleep ---
  Widget _buildStep4() {
    final options = [
      {'id': 'low', 'label': '5시간 이하', 'desc': '수면이 부족해요'},
      {'id': 'normal', 'label': '6-7시간', 'desc': '적당한 수면'},
      {'id': 'good', 'label': '8시간', 'desc': '충분한 수면'},
      {'id': 'high', 'label': '9시간 이상', 'desc': '많은 수면'},
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text('수면시간을 알려주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('건강한 생활 관리를 도와드려요', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 48),

            ...options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildOptionCard(
                opt['id']!,
                opt['label']!,
                opt['desc']!,
                _sleepDuration,
                (val) => setState(() => _sleepDuration = val),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    String id, 
    String label, 
    String desc, 
    String? groupValue, 
    Function(String) onChanged
  ) {
    bool isSelected = groupValue == id;
    
    // Icon Logic (Placeholder icons)
    IconData iconData = Icons.help;
    if (id == 'none' || id == 'low') iconData = Icons.sentiment_dissatisfied;
    if (id == 'light' || id == 'normal') iconData = Icons.sentiment_neutral;
    if (id == 'moderate' || id == 'good') iconData = Icons.sentiment_satisfied;
    if (id == 'active' || id == 'high') iconData = Icons.sentiment_very_satisfied;

    // Specific Icons override
    if (groupValue == _exerciseLevel) {
       if (id == 'none') iconData = Icons.fitness_center_outlined; // Dumbbell like
       if (id == 'light') iconData = Icons.show_chart;
       if (id == 'moderate') iconData = Icons.favorite;
       if (id == 'active') iconData = Icons.directions_bike;
    } else if (groupValue == _sleepDuration) {
       if (id == 'low') iconData = Icons.bedtime;
       if (id == 'normal') iconData = Icons.dark_mode;
       if (id == 'good') iconData = Icons.bed; 
       if (id == 'high') iconData = Icons.bedroom_parent;
    }

    return InkWell(
      onTap: () => onChanged(id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isSelected ? const Color(0xFF66BB6A) : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF388E3C) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
