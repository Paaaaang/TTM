import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ttm/screens/meal/ai_analysis_result_screen.dart';

/// 사진 촬영으로 식단 추가 화면
class CameraMealScreen extends StatefulWidget {
  const CameraMealScreen({super.key});

  @override
  State<CameraMealScreen> createState() => _CameraMealScreenState();
}

class _CameraMealScreenState extends State<CameraMealScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  String? _mealType; // 전달받은 식사 유형
  DateTime? _selectedDate; // 전달받은 날짜

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // arguments에서 mealType과 selectedDate 가져오기
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args.containsKey('mealType')) {
        _mealType = args['mealType'] as String?;
      }
      if (args.containsKey('selectedDate')) {
        _selectedDate = args['selectedDate'] as DateTime?;
      }
    }
  }

  /// 카메라로 사진 촬영
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _capturedImage = photo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카메라 촬영 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 갤러리에서 선택
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _capturedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('갤러리 선택 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 사진 선택 확인 후 AI 분석
  void _confirmAndAnalyze() async {
    if (_capturedImage == null) return;
    
    // 더미 로딩 제거 - 직접 AI 분석 화면으로 이동
    // AI 분석 결과 화면으로 이동하고 결과 받기
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIAnalysisResultScreen(
          imageFile: _capturedImage!,
          mealType: _mealType, // 식사 유형 전달
        ),
      ),
    );
    
    // 결과가 있으면 카메라 화면도 닫으면서 데이터 반환
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  /// 재촬영
  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 사진을 촬영한 후 미리보기
    if (_capturedImage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '사진 확인',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Column(
          children: [
            // 촬영된 이미지 미리보기
            Expanded(
              child: Center(
                child: kIsWeb
                    ? Image.network(
                        _capturedImage!.path,
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
                        File(_capturedImage!.path),
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            
            // 하단 버튼들
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // 이 사진으로 분석하기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _confirmAndAnalyze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '이 사진으로 분석하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 재촬영 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TextButton(
                      onPressed: _retakePicture,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '다시 촬영하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // 초기 카메라 화면
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '음식 사진 촬영',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // 카메라 안내
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 60,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '음식 사진을 촬영하면\nAI가 자동으로 분석해드립니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // 하단 버튼들
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // 촬영 버튼 (크기 축소)
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: const Color(0xFF1DB954),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 갤러리 선택 버튼
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: const Text('갤러리에서 선택'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 직접 입력하기 버튼
                  TextButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/meal/add',
                        arguments: {
                          'mealType': _mealType,
                          'selectedDate': _selectedDate,
                        }, // 식사 유형과 날짜 전달
                      );
                      // 식단 추가 완료 시 홈으로 결과 전달
                      if (result == true && mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text(
                      '직접 입력하기',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
