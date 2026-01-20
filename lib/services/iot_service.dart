import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ttm/constants/api_constants.dart';

class IotStatus {
  IotStatus({required this.memberId, required this.connected, required this.lastSeen});

  final int memberId;
  final bool connected;
  final String lastSeen;

  factory IotStatus.fromJson(Map<String, dynamic> json) {
    return IotStatus(
      memberId: json['member_id'] is int ? json['member_id'] : int.tryParse('${json['member_id']}') ?? 0,
      connected: json['connected'] == true,
      lastSeen: json['last_seen'] ?? '',
    );
  }
}

class IotService {
  Future<IotStatus> getStatus(int memberId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/iot/status/$memberId');
    final response = await http.get(uri, headers: {'Content-Type': 'application/json'}).timeout(ApiConstants.timeout);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return IotStatus.fromJson(data);
    }
    throw Exception('IoT 상태 조회 실패: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getProcessingStatus(int memberId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/meals/iot-processing/$memberId');
    final response = await http.get(uri, headers: {'Content-Type': 'application/json'}).timeout(ApiConstants.timeout);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data;
    }
    throw Exception('IoT 처리 상태 조회 실패: ${response.statusCode}');
  }
}
