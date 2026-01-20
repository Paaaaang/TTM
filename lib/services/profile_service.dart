import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ttm/constants/api_constants.dart';

class ActivityStats {
  ActivityStats({
    required this.mealCount,
    required this.workoutCount,
    required this.postCount,
    required this.likeCount,
  });

  final int mealCount;
  final int workoutCount;
  final int postCount;
  final int likeCount;

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ActivityStats(
      mealCount: parseInt(json['meal_count']),
      workoutCount: parseInt(json['workout_count']),
      postCount: parseInt(json['post_count']),
      likeCount: parseInt(json['like_count']),
    );
  }
}

class ProfileService {
  Future<ActivityStats> getActivityStats(int memberId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/api/members/$memberId/activity-stats',
    );

    final response = await http
        .get(uri, headers: {'Content-Type': 'application/json'})
        .timeout(ApiConstants.timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return ActivityStats.fromJson(data);
    }

    throw Exception('활동 통계 조회 실패: ${response.statusCode}');
  }
}
