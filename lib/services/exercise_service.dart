/// 운동 서비스
/// 
/// 운동 기록 관련 API 호출 및 데이터 관리
/// - exercise_log 데이터 CRUD
/// - 로컬 캐싱으로 오프라인 지원
/// - 에러 처리 및 재시도 로직
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:ttm/constants/api_config.dart';
import 'package:ttm/models/exercise_log.dart';

class ExerciseService {
  static const String _cacheKeyPrefix = 'exercise_cache_';
  static const Duration _cacheDuration = Duration(hours: 1);

  /// 오늘의 운동 기록 조회
  /// 
  /// GET /api/exercises/today/{member_id}
  /// 
  /// [memberId]: 회원 ID
  /// 반환: 오늘의 운동 기록 리스트
  Future<List<ExerciseLog>> getTodayExercises(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('/api/exercises/today/$memberId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final exercisesJson = data['exercises'] as List<dynamic>;
        
        final exercises = exercisesJson
            .map((json) => ExerciseLog.fromJson(json as Map<String, dynamic>))
            .toList();

        // 캐시 저장
        await _cacheExercises('today_$memberId', exercises);
        
        return exercises;
      } else {
        print('오늘 운동 조회 실패: ${response.statusCode} - ${response.body}');
        // 캐시에서 로드 시도
        return await _loadCachedExercises('today_$memberId');
      }
    } catch (e) {
      print('오늘 운동 조회 오류: $e');
      // 캐시에서 로드 시도
      return await _loadCachedExercises('today_$memberId');
    }
  }

  /// 기간별 운동 기록 조회
  /// 
  /// GET /api/exercises/date-range/{member_id}?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
  /// 
  /// [memberId]: 회원 ID
  /// [startDate]: 시작 날짜
  /// [endDate]: 종료 날짜
  /// 반환: 해당 기간의 운동 기록 리스트
  Future<List<ExerciseLog>> getExercisesByDateRange(
    int memberId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final startDateStr = dateFormat.format(startDate);
      final endDateStr = dateFormat.format(endDate);

      final uri = Uri.parse(
        ApiConfig.getUrl('/api/exercises/date-range/$memberId'),
      ).replace(queryParameters: {
        'start_date': startDateStr,
        'end_date': endDateStr,
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final exercisesJson = data['exercises'] as List<dynamic>;
        
        final exercises = exercisesJson
            .map((json) => ExerciseLog.fromJson(json as Map<String, dynamic>))
            .toList();

        // 캐시 저장
        await _cacheExercises('range_${memberId}_${startDateStr}_$endDateStr', exercises);
        
        return exercises;
      } else {
        print('기간별 운동 조회 실패: ${response.statusCode} - ${response.body}');
        return await _loadCachedExercises('range_${memberId}_${startDateStr}_$endDateStr');
      }
    } catch (e) {
      print('기간별 운동 조회 오류: $e');
      final dateFormat = DateFormat('yyyy-MM-dd');
      final startDateStr = dateFormat.format(startDate);
      final endDateStr = dateFormat.format(endDate);
      return await _loadCachedExercises('range_${memberId}_${startDateStr}_$endDateStr');
    }
  }

  /// 운동 기록 생성
  /// 
  /// POST /api/exercises/
  /// 
  /// [exercise]: 생성할 운동 기록
  /// 반환: 생성된 운동 기록 (exercise_log_id 포함)
  Future<ExerciseLog?> createExercise(ExerciseLog exercise) async {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final exerciseDateStr = dateFormat.format(exercise.exerciseDate);

      final requestBody = {
        'member_id': exercise.memberId,
        'exercise_date': exerciseDateStr,
        'exercise_name': exercise.exerciseName,
        'duration_minutes': exercise.durationMinutes,
        'calories_burned': exercise.caloriesBurned,
        'memo': exercise.memo,
      };

      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('/api/exercises/')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final createdExercise = ExerciseLog.fromJson(data['exercise_log']);
        
        // 오늘 운동 캐시 무효화
        await _invalidateCache('today_${exercise.memberId}');
        
        return createdExercise;
      } else {
        print('운동 생성 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('운동 생성 오류: $e');
      return null;
    }
  }

  /// 운동 기록 수정
  /// 
  /// PUT /api/exercises/{exercise_log_id}
  /// 
  /// [exerciseLogId]: 수정할 운동 기록 ID
  /// [exercise]: 수정할 내용
  /// 반환: 수정 성공 여부
  Future<bool> updateExercise(int exerciseLogId, ExerciseLog exercise) async {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final exerciseDateStr = dateFormat.format(exercise.exerciseDate);

      final requestBody = {
        'exercise_date': exerciseDateStr,
        'exercise_name': exercise.exerciseName,
        'duration_minutes': exercise.durationMinutes,
        'calories_burned': exercise.caloriesBurned,
        'memo': exercise.memo,
      };

      final response = await http.put(
        Uri.parse(ApiConfig.getUrl('/api/exercises/$exerciseLogId')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // 관련 캐시 무효화
        await _invalidateCache('today_${exercise.memberId}');
        return true;
      } else {
        print('운동 수정 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('운동 수정 오류: $e');
      return false;
    }
  }

  /// 운동 기록 삭제
  /// 
  /// DELETE /api/exercises/{exercise_log_id}
  /// 
  /// [exerciseLogId]: 삭제할 운동 기록 ID
  /// [memberId]: 회원 ID (캐시 무효화용)
  /// 반환: 삭제 성공 여부
  Future<bool> deleteExercise(int exerciseLogId, int memberId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.getUrl('/api/exercises/$exerciseLogId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // 관련 캐시 무효화
        await _invalidateCache('today_$memberId');
        return true;
      } else {
        print('운동 삭제 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('운동 삭제 오류: $e');
      return false;
    }
  }

  /// 운동 통계 조회
  /// 
  /// GET /api/exercises/stats/{member_id}?days=7
  /// 
  /// [memberId]: 회원 ID
  /// [days]: 통계 기간 (기본 7일)
  /// 반환: 총 운동 횟수, 시간, 칼로리 등
  Future<Map<String, dynamic>?> getExerciseStats(int memberId, {int days = 7}) async {
    try {
      final uri = Uri.parse(
        ApiConfig.getUrl('/api/exercises/stats/$memberId'),
      ).replace(queryParameters: {
        'days': days.toString(),
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['stats'] as Map<String, dynamic>;
      } else {
        print('운동 통계 조회 실패: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('운동 통계 조회 오류: $e');
      return null;
    }
  }

  // ========== 캐싱 관련 메서드 ==========

  /// 운동 데이터 캐시 저장
  Future<void> _cacheExercises(String key, List<ExerciseLog> exercises) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$key';
      
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
      
      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('캐시 저장 오류: $e');
    }
  }

  /// 캐시에서 운동 데이터 로드
  Future<List<ExerciseLog>> _loadCachedExercises(String key) async {
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

      final exercisesJson = cacheData['exercises'] as List<dynamic>;
      return exercisesJson
          .map((json) => ExerciseLog.fromJson(json as Map<String, dynamic>))
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

  /// 모든 운동 캐시 삭제
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
}
