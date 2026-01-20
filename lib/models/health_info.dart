/// 건강정보 모델 클래스
///
/// DB 테이블 매핑:
/// - member_disease 테이블: 회원 질병 정보
/// - member_allergy 테이블: 회원 알레르기 정보
class Disease {
  // DB: member_disease 테이블
  final int memberDiseaseId;   // member_disease_id (PK)
  final int memberId;           // member_id (FK)
  final String diseaseName;     // disease_name
  final String? description;    // description
  final DateTime? createdAt;    // created_at

  Disease({
    required this.memberDiseaseId,
    required this.memberId,
    required this.diseaseName,
    this.description,
    this.createdAt,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      memberDiseaseId: json['member_disease_id'] as int,
      memberId: json['member_id'] as int,
      diseaseName: json['disease_name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_disease_id': memberDiseaseId,
      'member_id': memberId,
      'disease_name': diseaseName,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}


class Allergy {
  // DB: member_allergy 테이블
  final int allergyId;          // allergy_id (PK)
  final int memberId;           // member_id (FK)
  final String allergyName;     // allergy_name
  final String? description;    // description

  Allergy({
    required this.allergyId,
    required this.memberId,
    required this.allergyName,
    this.description,
  });

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      allergyId: json['allergy_id'] as int,
      memberId: json['member_id'] as int,
      allergyName: json['allergy_name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergy_id': allergyId,
      'member_id': memberId,
      'allergy_name': allergyName,
      'description': description,
    };
  }
}


class HealthInfo {
  // 건강정보 통합 모델
  final List<Disease> diseases;
  final List<Allergy> allergies;

  HealthInfo({
    required this.diseases,
    required this.allergies,
  });

  // Helper: 질병이 있는지
  bool get hasDiseases => diseases.isNotEmpty;

  // Helper: 알레르기가 있는지
  bool get hasAllergies => allergies.isNotEmpty;

  // Helper: 건강정보가 있는지
  bool get hasHealthInfo => hasDiseases || hasAllergies;

  // Helper: 질병 이름 리스트
  List<String> get diseaseNames => diseases.map((d) => d.diseaseName).toList();

  // Helper: 알레르기 이름 리스트
  List<String> get allergyNames => allergies.map((a) => a.allergyName).toList();
}
