/// 식단 서비스
/// 
/// 식단 기록 관련 API 호출 및 데이터 관리
/// - meal_log, meal_item 데이터 CRUD
/// - 로컬 캐싱으로 오프라인 지원
/// - 에러 처리 및 재시도 로직
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ttm/constants/api_config.dart';
import 'package:ttm/models/meal_log.dart';
import 'package:ttm/models/meal_item.dart';

class MealService {
  static const String _cacheKeyPrefix = 'meal_cache_';
  static const Duration _cacheDuration = Duration(hours: 1);

  /// 오늘의 식단 기록 조회
  /// 
  /// GET /api/meals/today/{member_id}
  /// 
  /// [memberId]: 회원 ID
  /// 반환: 오늘의 식단 기록 리스트
  Future<List<MealLog>> getTodayMeals(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('/api/meals/today/$memberId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final mealsJson = jsonDecode(response.body) as List<dynamic>;
        
        final meals = mealsJson
            .map((json) => MealLog.fromJson(json as Map<String, dynamic>))
            .toList();

        // 캐시 저장
        await _cacheMeals('today_$memberId', meals);
        
        return meals;
      } else {
        print('오늘 식단 조회 실패: ${response.statusCode} - ${response.body}');
        // 캐시에서 로드 시도
        return await _loadCachedMeals('today_$memberId');
      }
    } catch (e) {
      print('오늘 식단 조회 오류: $e');
      // 캐시에서 로드 시도
      return await _loadCachedMeals('today_$memberId');
    }
  }

  /// 기간별 식단 기록 조회
  /// 
  /// GET /api/meals/date-range/{member_id}?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
  /// 
  /// [memberId]: 회원 ID
  /// [startDate]: 시작 날짜
  /// [endDate]: 종료 날짜
  /// 반환: 해당 기간의 식단 기록 리스트
  Future<List<MealLog>> getMealsByDateRange(
    int memberId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final startDateStr = dateFormat.format(startDate);
      final endDateStr = dateFormat.format(endDate);

      final uri = Uri.parse(
        ApiConfig.getUrl('/api/meals/date-range/$memberId'),
      ).replace(queryParameters: {
        'start_date': startDateStr,
        'end_date': endDateStr,
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final mealsJson = jsonDecode(response.body) as List<dynamic>;
        
        final meals = mealsJson
            .map((json) => MealLog.fromJson(json as Map<String, dynamic>))
            .toList();

        // 캐시 저장
        await _cacheMeals('range_${memberId}_${startDateStr}_$endDateStr', meals);
        
        return meals;
      } else {
        print('기간별 식단 조회 실패: ${response.statusCode} - ${response.body}');
        return await _loadCachedMeals('range_${memberId}_${startDateStr}_$endDateStr');
      }
    } catch (e) {
      print('기간별 식단 조회 오류: $e');
      final dateFormat = DateFormat('yyyy-MM-dd');
      final startDateStr = dateFormat.format(startDate);
      final endDateStr = dateFormat.format(endDate);
      return await _loadCachedMeals('range_${memberId}_${startDateStr}_$endDateStr');
    }
  }

  /// 식단 기록 생성
  /// 
  /// POST /api/meals/
  /// 
  /// [mealLog]: 생성할 식단 기록 (items 포함)
  /// 반환: 생성된 식단 기록 (meal_log_id 포함)
  Future<MealLog?> createMeal(MealLog mealLog) async {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final mealDateStr = dateFormat.format(mealLog.mealDate);

      final requestBody = {
        'member_id': mealLog.memberId,
        'meal_date': mealDateStr,
        'meal_type': mealLog.mealType,
        'memo': mealLog.memo,
        'items': mealLog.items.map((item) => {
          'food_name': item.foodName,
          'calories_kcal': item.caloriesKcal,
          'carbohydrates_g': item.carbohydratesG,
          'protein_g': item.proteinG,
          'fat_g': item.fatG,
          'sugar_g': item.sugarG,
          'sodium_mg': item.sodiumMg,
        }).toList(),
      };

      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('/api/meals/')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.timeout);

      print('식단 생성 응답: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final createdMeal = MealLog.fromJson(data);
        
        // 오늘 식단 캐시 무효화
        await _invalidateCache('today_${mealLog.memberId}');
        
        return createdMeal;
      } else {
        String message = response.body;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
            message = decoded['detail'].toString();
          }
        } catch (_) {
          // ignore JSON parse errors
        }
        print('식단 생성 실패: ${response.statusCode} - ${response.body}');
        throw Exception(message);
      }
    } catch (e) {
      print('식단 생성 오류: $e');
      rethrow;
    }
  }

  /// 식단 기록 수정
  /// 
  /// PUT /api/meals/{meal_log_id}
  /// 
  /// [mealLogId]: 수정할 식단 기록 ID
  /// [mealLog]: 수정할 내용 (items 포함)
  /// 반환: 수정 성공 여부
  Future<bool> updateMeal(int mealLogId, MealLog mealLog) async {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final mealDateStr = dateFormat.format(mealLog.mealDate);

      final requestBody = {
        'meal_date': mealDateStr,
        'meal_type': mealLog.mealType,
        'memo': mealLog.memo,
        'items': mealLog.items.map((item) => {
          'food_name': item.foodName,
          'calories_kcal': item.caloriesKcal,
          'carbohydrates_g': item.carbohydratesG,
          'protein_g': item.proteinG,
          'fat_g': item.fatG,
          'sugar_g': item.sugarG,
          'sodium_mg': item.sodiumMg,
        }).toList(),
      };

      final response = await http.put(
        Uri.parse(ApiConfig.getUrl('/api/meals/$mealLogId')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // 관련 캐시 무효화
        await _invalidateCache('today_${mealLog.memberId}');
        return true;
      } else {
        print('식단 수정 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('식단 수정 오류: $e');
      return false;
    }
  }

  /// 식단 기록 삭제
  /// 
  /// DELETE /api/meals/{meal_log_id}
  /// 
  /// [mealLogId]: 삭제할 식단 기록 ID
  /// [memberId]: 회원 ID (캐시 무효화용)
  /// 반환: 삭제 성공 여부
  Future<bool> deleteMeal(int mealLogId, int memberId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.getUrl('/api/meals/$mealLogId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // 관련 캐시 무효화
        await _invalidateCache('today_$memberId');
        return true;
      } else {
        print('식단 삭제 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('식단 삭제 오류: $e');
      return false;
    }
  }

  /// 식단 통계 조회
  /// 
  /// GET /api/meals/stats/{member_id}?days=7
  /// 
  /// [memberId]: 회원 ID
  /// [days]: 통계 기간 (기본 7일)
  /// 반환: 평균 칼로리, 탄수화물, 단백질, 지방 등
  Future<List<Map<String, dynamic>>?> getMealStats(int memberId, {int days = 7}) async {
    try {
      final uri = Uri.parse(
        ApiConfig.getUrl('/api/meals/stats/$memberId'),
      ).replace(queryParameters: {
        'days': days.toString(),
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final stats = data['stats'] as List<dynamic>;
        return stats
          .map((item) => item as Map<String, dynamic>)
          .toList();
      } else {
        print('식단 통계 조회 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('식단 통계 조회 오류: $e');
      return null;
    }
  }

  // ========== 캐싱 관련 메서드 ==========

  /// 식단 데이터 캐시 저장
  Future<void> _cacheMeals(String key, List<MealLog> meals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'meals': meals.map((m) => m.toJson()).toList(),
      };
      
      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('캐시 저장 오류: $e');
    }
  }

  /// 캐시에서 식단 데이터 로드
  Future<List<MealLog>> _loadCachedMeals(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      final cached = prefs.getString(cacheKey);
      
      if (cached == null) {
        return [];
      }

      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 캐시 유효성 확인
      if (now - timestamp > _cacheDuration.inMilliseconds) {
        await prefs.remove(cacheKey);
        return [];
      }

      final mealsJson = cacheData['meals'] as List<dynamic>;
      return mealsJson
          .map((json) => MealLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('캐시 로드 오류: $e');
      return [];
    }
  }

  /// 특정 캐시 무효화
  Future<void> _invalidateCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      await prefs.remove(cacheKey);
    } catch (e) {
      print('캐시 무효화 오류: $e');
    }
  }

  /// 모든 식단 캐시 삭제
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('전체 캐시 삭제 오류: $e');
    }
  }

  /// AI 이미지 분석
  /// 
  /// POST /api/meals/analyze-image
  /// 
  /// [imageFile]: 분석할 이미지 파일 (XFile)
  /// [memberId]: 회원 ID
  /// [mealType]: 식사 유형 (BREAKFAST, LUNCH, DINNER, SNACK)
  /// [mealDate]: 식사 날짜 (선택)
  /// 반환: AI 분석 결과 {success, message, foods: [{food_name, calories_kcal, carbohydrates_g, ...}]}
  Future<Map<String, dynamic>> analyzeMealImage({
    required XFile imageFile,
    required int memberId,
    required String mealType,
    String? mealDate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getUrl('/api/meals/analyze-image')),
      );

      // 폼 데이터 추가
      request.fields['member_id'] = memberId.toString();
      request.fields['meal_type'] = mealType;
      if (mealDate != null) {
        request.fields['meal_date'] = mealDate;
      }

      // 이미지 파일 추가 (웹/모바일 모두 지원)
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ AI 분석 성공: ${result['message']}');
        return result;
      } else {
        print('AI 분석 실패: ${response.statusCode} - ${response.body}');
        throw Exception('AI 분석 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('AI 분석 오류: $e');
      rethrow;
    }
  }
}
