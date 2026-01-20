// 친구 그룹 서비스
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ttm/constants/api_config.dart';
import 'package:ttm/models/friend_group.dart';

class FriendGroupService {
  /// 내 그룹 목록 조회
  Future<List<FriendGroup>> getMyGroups(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('/api/groups/$memberId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => FriendGroup.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load groups');
      }
    } catch (e) {
      print('그룹 목록 조회 오류: $e');
      return [];
    }
  }

  /// 그룹 생성
  Future<FriendGroup?> createGroup(String groupName, int creatorMemberId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('/api/groups/')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'group_name': groupName,
          'creator_member_id': creatorMemberId,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return FriendGroup.fromJson(data);
      } else {
        throw Exception('Failed to create group');
      }
    } catch (e) {
      print('그룹 생성 오류: $e');
      return null;
    }
  }

  /// 그룹 삭제
  Future<bool> deleteGroup(int groupId, int memberId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.getUrl('/api/groups/$groupId?member_id=$memberId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('그룹 삭제 오류: $e');
      return false;
    }
  }

  /// 그룹에 멤버 추가
  Future<bool> addGroupMember(int groupId, int memberId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('/api/groups/$groupId/members')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'member_id': memberId}),
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('그룹 멤버 추가 오류: $e');
      return false;
    }
  }

  /// 그룹에서 멤버 제거
  Future<bool> removeGroupMember(int groupId, int memberId) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.getUrl('/api/groups/$groupId/members/$memberId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('그룹 멤버 제거 오류: $e');
      return false;
    }
  }

  /// 그룹 멤버 목록 조회 (영양 점수 포함)
  Future<List<GroupMemberInfo>> getGroupMembers(int groupId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('/api/groups/$groupId/members')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => GroupMemberInfo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load group members');
      }
    } catch (e) {
      print('그룹 멤버 조회 오류: $e');
      return [];
    }
  }
}
