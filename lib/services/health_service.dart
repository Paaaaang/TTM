/// 건강정보 서비스 레이어
///
/// API 호출 및 로컬 캐싱 처리:
/// - 질병 정보 조회/추가/삭제
/// - 알레르기 정보 조회/추가/삭제
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/health_info.dart';

class HealthService {
  // 캐시 키
  static const String _diseasesCachePrefix = 'cached_diseases_';
  static const String _allergiesCachePrefix = 'cached_allergies_';
  
  // 캐시 유효 시간 (1시간)
  static const Duration _cacheDuration = Duration(hours: 1);

  // ============================================================
  // 질병 정보 API
  // ============================================================

  /// 회원 질병 정보 조회
  Future<List<Disease>> getDiseases(int memberId, {bool forceRefresh = false}) async {
    try {
      // 캐시 확인
      if (!forceRefresh) {
        final cachedDiseases = await _getCachedDiseases(memberId);
        if (cachedDiseases != null) {
          return cachedDiseases;
        }
      }

      // API 호출
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/health/diseases/$memberId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final diseases = data.map((json) => Disease.fromJson(json)).toList();
        
        // 캐시 저장
        await _cacheDiseases(memberId, diseases);
        
        return diseases;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('질병 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('질병 정보 조회 오류: $e');
      
      // 오류 시 캐시된 데이터 반환
      final cachedDiseases = await _getCachedDiseases(memberId);
      if (cachedDiseases != null) {
        return cachedDiseases;
      }
      
      rethrow;
    }
  }

  /// 질병 정보 추가
  Future<Disease> addDisease(int memberId, String diseaseName, {String? description}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/health/diseases/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'member_id': memberId,
          'disease_name': diseaseName,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final disease = Disease.fromJson(data);
        
        // 캐시 무효화
        await _invalidateDiseasesCache(memberId);
        
        return disease;
      } else {
        throw Exception('질병 정보 추가 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('질병 정보 추가 오류: $e');
      rethrow;
    }
  }

  /// 질병 정보 삭제
  Future<void> deleteDisease(int memberId, int memberDiseaseId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/health/diseases/$memberDiseaseId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // 캐시 무효화
        await _invalidateDiseasesCache(memberId);
      } else if (response.statusCode == 404) {
        throw Exception('질병 정보를 찾을 수 없습니다');
      } else {
        throw Exception('질병 정보 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('질병 정보 삭제 오류: $e');
      rethrow;
    }
  }

  // ============================================================
  // 알레르기 정보 API
  // ============================================================

  /// 회원 알레르기 정보 조회
  Future<List<Allergy>> getAllergies(int memberId, {bool forceRefresh = false}) async {
    try {
      // 캐시 확인
      if (!forceRefresh) {
        final cachedAllergies = await _getCachedAllergies(memberId);
        if (cachedAllergies != null) {
          return cachedAllergies;
        }
      }

      // API 호출
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/health/allergies/$memberId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final allergies = data.map((json) => Allergy.fromJson(json)).toList();
        
        // 캐시 저장
        await _cacheAllergies(memberId, allergies);
        
        return allergies;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('알레르기 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('알레르기 정보 조회 오류: $e');
      
      // 오류 시 캐시된 데이터 반환
      final cachedAllergies = await _getCachedAllergies(memberId);
      if (cachedAllergies != null) {
        return cachedAllergies;
      }
      
      rethrow;
    }
  }

  /// 알레르기 정보 추가
  Future<Allergy> addAllergy(int memberId, String allergyName, {String? description}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/health/allergies/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'member_id': memberId,
          'allergy_name': allergyName,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final allergy = Allergy.fromJson(data);
        
        // 캐시 무효화
        await _invalidateAllergiesCache(memberId);
        
        return allergy;
      } else {
        throw Exception('알레르기 정보 추가 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('알레르기 정보 추가 오류: $e');
      rethrow;
    }
  }

  /// 알레르기 정보 삭제
  Future<void> deleteAllergy(int memberId, int allergyId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/health/allergies/$allergyId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // 캐시 무효화
        await _invalidateAllergiesCache(memberId);
      } else if (response.statusCode == 404) {
        throw Exception('알레르기 정보를 찾을 수 없습니다');
      } else {
        throw Exception('알레르기 정보 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('알레르기 정보 삭제 오류: $e');
      rethrow;
    }
  }

  /// 통합 건강정보 조회
  Future<HealthInfo> getHealthInfo(int memberId, {bool forceRefresh = false}) async {
    final diseases = await getDiseases(memberId, forceRefresh: forceRefresh);
    final allergies = await getAllergies(memberId, forceRefresh: forceRefresh);
    
    return HealthInfo(
      diseases: diseases,
      allergies: allergies,
    );
  }

  // ============================================================
  // 캐싱 메서드
  // ============================================================

  Future<void> _cacheDiseases(int memberId, List<Disease> diseases) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': diseases.map((d) => d.toJson()).toList(),
      };
      await prefs.setString('$_diseasesCachePrefix$memberId', json.encode(cacheData));
    } catch (e) {
      print('질병 캐시 저장 오류: $e');
    }
  }

  Future<List<Disease>?> _getCachedDiseases(int memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('$_diseasesCachePrefix$memberId');
      
      if (cachedString != null) {
        final cacheData = json.decode(cachedString);
        final timestamp = DateTime.parse(cacheData['timestamp']);
        
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          final List<dynamic> data = cacheData['data'];
          return data.map((json) => Disease.fromJson(json)).toList();
        }
      }
      
      return null;
    } catch (e) {
      print('질병 캐시 조회 오류: $e');
      return null;
    }
  }

  Future<void> _invalidateDiseasesCache(int memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_diseasesCachePrefix$memberId');
    } catch (e) {
      print('질병 캐시 무효화 오류: $e');
    }
  }

  Future<void> _cacheAllergies(int memberId, List<Allergy> allergies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': allergies.map((a) => a.toJson()).toList(),
      };
      await prefs.setString('$_allergiesCachePrefix$memberId', json.encode(cacheData));
    } catch (e) {
      print('알레르기 캐시 저장 오류: $e');
    }
  }

  Future<List<Allergy>?> _getCachedAllergies(int memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('$_allergiesCachePrefix$memberId');
      
      if (cachedString != null) {
        final cacheData = json.decode(cachedString);
        final timestamp = DateTime.parse(cacheData['timestamp']);
        
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          final List<dynamic> data = cacheData['data'];
          return data.map((json) => Allergy.fromJson(json)).toList();
        }
      }
      
      return null;
    } catch (e) {
      print('알레르기 캐시 조회 오류: $e');
      return null;
    }
  }

  Future<void> _invalidateAllergiesCache(int memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_allergiesCachePrefix$memberId');
    } catch (e) {
      print('알레르기 캐시 무효화 오류: $e');
    }
  }
}
