import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class AIService {
  // 싱글톤 패턴
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// AI와 대화하기
  Future<String> chat(String message, {int? memberId}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/ai/chat');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          if (memberId != null) 'member_id': memberId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['reply'];
      } else {
        throw Exception('AI 응답 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('AI 서비스 오류: $e');
      throw Exception('서버 연결 오류');
    }
  }

  /// 식사 분석 경고 가져오기
  Future<String> getMealAnalysisWarning(int memberId, String foodName) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/ai/analyze-meal-warning');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'member_id': memberId,
          'food_name': foodName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['warning'];
      } else {
        print('Warning fetch failed: ${response.statusCode}');
        return '건강 주의사항을 불러올 수 없습니다.';
      }
    } catch (e) {
      print('AI Warning Service Error: $e');
      return 'AI 연결 중 오류가 발생했습니다.';
    }
  }
}
