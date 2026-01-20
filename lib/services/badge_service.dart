/// 배지 서비스 레이어
///
/// API 호출 및 로컬 캐싱 처리:
/// - 전체 배지 목록 조회
/// - 회원 배지 조회
/// - 배지 수여
/// - 배지 통계
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/badge.dart';

class BadgeService {
  // 캐시 키
  static const String _allBadgesCacheKey = 'cached_all_badges';
  static const String _memberBadgesCachePrefix = 'cached_member_badges_';
  static const String _badgeStatsCachePrefix = 'cached_badge_stats_';
  
  // 캐시 유효 시간 (1시간)
  static const Duration _cacheDuration = Duration(hours: 1);

  /// 전체 배지 목록 조회
  Future<List<Badge>> getAllBadges({bool forceRefresh = false}) async {
    try {
      // 캐시 확인
      if (!forceRefresh) {
        final cachedBadges = await _getCachedAllBadges();
        if (cachedBadges != null) {
          return cachedBadges;
        }
      }

      // API 호출
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/badges/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final badges = data.map((json) => Badge.fromJson(json)).toList();
        
        // 캐시 저장
        await _cacheAllBadges(badges);
        
        return badges;
      } else {
        throw Exception('배지 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('배지 목록 조회 오류: $e');
      
      // 오류 시 캐시된 데이터 반환
      final cachedBadges = await _getCachedAllBadges();
      if (cachedBadges != null) {
        return cachedBadges;
      }
      
      rethrow;
    }
  }

  /// 회원 배지 조회
  Future<List<MemberBadge>> getMemberBadges(int memberId, {bool forceRefresh = false}) async {
    try {
      // 캐시 확인
      if (!forceRefresh) {
        final cachedBadges = await _getCachedMemberBadges(memberId);
        if (cachedBadges != null) {
          return cachedBadges;
        }
      }

      // API 호출
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/badges/member/$memberId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final badges = data.map((json) => MemberBadge.fromJson(json)).toList();
        
        // 캐시 저장
        await _cacheMemberBadges(memberId, badges);
        
        return badges;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('회원 배지 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('회원 배지 조회 오류: $e');
      
      // 오류 시 캐시된 데이터 반환
      final cachedBadges = await _getCachedMemberBadges(memberId);
      if (cachedBadges != null) {
        return cachedBadges;
      }
      
      rethrow;
    }
  }

  /// 배지 수여
  Future<MemberBadge> awardBadge(int memberId, int badgeId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/badges/award'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'member_id': memberId,
          'badge_id': badgeId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final badge = MemberBadge.fromJson(data['badge']);
        
        // 캐시 무효화
        await _invalidateMemberBadgesCache(memberId);
        await _invalidateBadgeStatsCache(memberId);
        
        return badge;
      } else if (response.statusCode == 400) {
        throw Exception('이미 획득한 배지입니다');
      } else if (response.statusCode == 404) {
        throw Exception('배지를 찾을 수 없습니다');
      } else {
        throw Exception('배지 수여 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('배지 수여 오류: $e');
      rethrow;
    }
  }

  /// 배지 통계 조회
  Future<BadgeStats> getBadgeStats(int memberId, {bool forceRefresh = false}) async {
    try {
      // 캐시 확인
      if (!forceRefresh) {
        final cachedStats = await _getCachedBadgeStats(memberId);
        if (cachedStats != null) {
          return cachedStats;
        }
      }

      // API 호출
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/badges/stats/$memberId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final stats = BadgeStats.fromJson(data);
        
        // 캐시 저장
        await _cacheBadgeStats(memberId, stats);
        
        return stats;
      } else {
        throw Exception('배지 통계 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('배지 통계 조회 오류: $e');
      
      // 오류 시 캐시된 데이터 반환
      final cachedStats = await _getCachedBadgeStats(memberId);
      if (cachedStats != null) {
        return cachedStats;
      }
      
      rethrow;
    }
  }

  // ============================================================
  // 캐싱 메서드
  // ============================================================

  /// 전체 배지 캐시 저장
  Future<void> _cacheAllBadges(List<Badge> badges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': badges.map((b) => b.toJson()).toList(),
      };
      await prefs.setString(_allBadgesCacheKey, json.encode(cacheData));
    } catch (e) {
      print('전체 배지 캐시 저장 오류: $e');
    }
  }

  /// 전체 배지 캐시 조회
  Future<List<Badge>?> _getCachedAllBadges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_allBadgesCacheKey);
      
      if (cachedString != null) {
        final cacheData = json.decode(cachedString);
        final timestamp = DateTime.parse(cacheData['timestamp']);
        
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          final List<dynamic> data = cacheData['data'];
          return data.map((json) => Badge.fromJson(json)).toList();
        }
      }
      
      return null;
    } catch (e) {
      print('전체 배지 캐시 조회 오류: $e');
      return null;
    }
  }

  /// 회원 배지 캐시 저장
  Future<void> _cacheMemberBadges(int memberId, List<MemberBadge> badges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': badges.map((b) => b.toJson()).toList(),
      };
      await prefs.setString(
        '$_memberBadgesCachePrefix$memberId',
        json.encode(cacheData),
      );
    } catch (e) {
      print('회원 배지 캐시 저장 오류: $e');
    }
  }

  /// 회원 배지 캐시 조회
  Future<List<MemberBadge>?> _getCachedMemberBadges(int memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('$_memberBadgesCachePrefix$memberId');
      
      if (cachedString != null) {
        final cacheData = json.decode(cachedString);
        final timestamp = DateTime.parse(cacheData['timestamp']);
        
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          final List<dynamic> data = cacheData['data'];
          return data.map((json) => MemberBadge.fromJson(json)).toList();
        }
      }
      
      return null;
    } catch (e) {
      print('회원 배지 캐시 조회 오류: $e');
      return null;
    }
  }

  /// 회원 배지 캐시 무효화
  Future<void> _invalidateMemberBadgesCache(int memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_memberBadgesCachePrefix$memberId');
    } catch (e) {
      print('회원 배지 캐시 무효화 오류: $e');
    }
  }

  /// 배지 통계 캐시 저장
  Future<void> _cacheBadgeStats(int memberId, BadgeStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': stats.toJson(),
      };
      await prefs.setString(
        '$_badgeStatsCachePrefix$memberId',
        json.encode(cacheData),
      );
    } catch (e) {
      print('배지 통계 캐시 저장 오류: $e');
    }
  }

  /// 배지 통계 캐시 조회
  Future<BadgeStats?> _getCachedBadgeStats(int memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('$_badgeStatsCachePrefix$memberId');
      
      if (cachedString != null) {
        final cacheData = json.decode(cachedString);
        final timestamp = DateTime.parse(cacheData['timestamp']);
        
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return BadgeStats.fromJson(cacheData['data']);
        }
      }
      
      return null;
    } catch (e) {
      print('배지 통계 캐시 조회 오류: $e');
      return null;
    }
  }

  /// 배지 통계 캐시 무효화
  Future<void> _invalidateBadgeStatsCache(int memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_badgeStatsCachePrefix$memberId');
    } catch (e) {
      print('배지 통계 캐시 무효화 오류: $e');
    }
  }

  /// 배지 자동 체크 및 획득
  Future<List<Map<String, dynamic>>> checkAndAwardBadges(int memberId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/badges/check-and-award/$memberId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final newlyEarned = data['newly_earned_badges'] as List<dynamic>;
        
        // 캐시 무효화
        await _invalidateMemberBadgesCache(memberId);
        await _invalidateBadgeStatsCache(memberId);
        
        return newlyEarned.cast<Map<String, dynamic>>();
      } else {
        throw Exception('배지 자동 획득 체크 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('배지 자동 획득 체크 오류: $e');
      return [];
    }
  }
}
