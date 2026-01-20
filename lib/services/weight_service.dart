/// 체중 기록 서비스
/// 작성일: 2026-01-07

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/token_manager.dart';

class WeightService {
  static final WeightService _instance = WeightService._internal();
  factory WeightService() => _instance;
  WeightService._internal();

  /// 체중 기록 생성/업데이트
  /// 같은 날짜에 이미 기록이 있으면 업데이트됨
  Future<Map<String, dynamic>> createWeightRecord({
    required double weightKg,
    required DateTime recordedDate,
    String? memo,
  }) async {
    final token = await TokenManager.getToken();
    if (token == null) {
      throw Exception('로그인이 필요합니다');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/weight/record'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'weight_kg': weightKg,
        'recorded_date': recordedDate.toIso8601String().split('T')[0], // YYYY-MM-DD
        'memo': memo,
      }),
    ).timeout(ApiConstants.timeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 401) {
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요');
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '체중 기록 생성 실패');
    }
  }

  /// 체중 변화 이력 조회
  Future<Map<String, dynamic>> getWeightHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    final token = await TokenManager.getToken();
    if (token == null) {
      throw Exception('로그인이 필요합니다');
    }

    // 쿼리 파라미터 구성
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };

    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/weight/history')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(ApiConstants.timeout);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 401) {
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요');
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '체중 이력 조회 실패');
    }
  }

  /// 가장 최근 체중 기록 조회
  Future<Map<String, dynamic>?> getLatestWeight() async {
    final token = await TokenManager.getToken();
    if (token == null) {
      throw Exception('로그인이 필요합니다');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/weight/latest'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      ).timeout(ApiConstants.timeout);

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      // null 체크
      if (body == 'null' || body.isEmpty) {
        return null;
      }
      return jsonDecode(body);
    } else if (response.statusCode == 401) {
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요');
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '최근 체중 조회 실패');
    }
  }

  /// 체중 기록 삭제
  Future<void> deleteWeightRecord(int weightLogId) async {
    final token = await TokenManager.getToken();
    if (token == null) {
      throw Exception('로그인이 필요합니다');
    }

    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/api/weight/record/$weightLogId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      ).timeout(ApiConstants.timeout);

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요');
    } else if (response.statusCode == 403) {
      throw Exception('본인의 기록만 삭제할 수 있습니다');
    } else if (response.statusCode == 404) {
      throw Exception('체중 기록을 찾을 수 없습니다');
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '체중 기록 삭제 실패');
    }
  }

  /// 주간 체중 데이터 조회 (통계 화면용)
  Future<List<Map<String, dynamic>>> getWeeklyWeightData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final history = await getWeightHistory(
      startDate: startDate,
      endDate: endDate,
      limit: 100,
    );

    final records = history['records'] as List<dynamic>;
    
    // 날짜별로 그룹화 (같은 날 여러 기록이 있을 수 있음)
    final Map<String, double> dailyWeights = {};
    
    for (final record in records) {
      // 백엔드에서는 'recorded_date' 필드를 사용
      final recordedDate = record['recorded_date'];
      String date;
      
      // recorded_date가 DateTime 객체인 경우와 String인 경우 처리
      if (recordedDate is String) {
        date = recordedDate.split('T')[0]; // ISO 형식의 경우 날짜 부분만 추출
      } else {
        date = recordedDate.toString().split('T')[0];
      }
      
      final weight = (record['weight_kg'] as num).toDouble();
      
      // 같은 날의 가장 최근 기록 사용
      if (!dailyWeights.containsKey(date) || dailyWeights[date]! < weight) {
        dailyWeights[date] = weight;
      }
    }

    // List로 변환하여 반환
    return dailyWeights.entries
        .map((entry) => {
              'date': entry.key,
              'weight': entry.value,
            })
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// 월간 체중 데이터 조회 (통계 화면용)
  Future<List<Map<String, dynamic>>> getMonthlyWeightData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return getWeeklyWeightData(startDate: startDate, endDate: endDate);
  }
}
