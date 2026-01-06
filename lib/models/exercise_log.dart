/// 운동 기록 모델
/// 
/// DB 테이블: exercise_log
/// 매핑 규칙: snake_case(DB) → camelCase(Dart)
/// - exercise_log_id (INT PK) → exerciseLogId
/// - member_id (INT FK) → memberId
/// - exercise_date (DATE) → exerciseDate
/// - exercise_name (VARCHAR) → exerciseName
/// - duration_minutes (INT) → durationMinutes
/// - calories_burned (DECIMAL) → caloriesBurned
/// - memo (TEXT) → memo
/// - created_at (TIMESTAMP) → createdAt
class ExerciseLog {
  final int? exerciseLogId;
  final int memberId;
  final DateTime exerciseDate;
  final String exerciseName;
  final int durationMinutes;
  final double? caloriesBurned;
  final String? memo;
  final DateTime? createdAt;

  ExerciseLog({
    this.exerciseLogId,
    required this.memberId,
    required this.exerciseDate,
    required this.exerciseName,
    required this.durationMinutes,
    this.caloriesBurned,
    this.memo,
    this.createdAt,
  });

  /// JSON에서 객체 생성
  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseLogId: json['exercise_log_id'] as int?,
      memberId: json['member_id'] as int,
      exerciseDate: DateTime.parse(json['exercise_date'] as String),
      exerciseName: json['exercise_name'] as String,
      durationMinutes: json['duration_minutes'] as int,
      caloriesBurned: json['calories_burned'] != null 
          ? (json['calories_burned'] as num).toDouble() 
          : null,
      memo: json['memo'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      if (exerciseLogId != null) 'exercise_log_id': exerciseLogId,
      'member_id': memberId,
      'exercise_date': exerciseDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'exercise_name': exerciseName,
      'duration_minutes': durationMinutes,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// 운동 시간을 "N시간 M분" 형식으로 반환
  String get durationFormatted {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '$hours시간 $minutes분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$minutes분';
    }
  }

  /// 칼로리를 "N kcal" 형식으로 반환
  String get caloriesFormatted {
    if (caloriesBurned == null) {
      return '-';
    }
    return '${caloriesBurned!.toStringAsFixed(0)} kcal';
  }

  /// 복사본 생성 (일부 필드 변경)
  ExerciseLog copyWith({
    int? exerciseLogId,
    int? memberId,
    DateTime? exerciseDate,
    String? exerciseName,
    int? durationMinutes,
    double? caloriesBurned,
    String? memo,
    DateTime? createdAt,
  }) {
    return ExerciseLog(
      exerciseLogId: exerciseLogId ?? this.exerciseLogId,
      memberId: memberId ?? this.memberId,
      exerciseDate: exerciseDate ?? this.exerciseDate,
      exerciseName: exerciseName ?? this.exerciseName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
