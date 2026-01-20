import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ttm/constants/api_constants.dart';
import 'package:ttm/services/auth_service.dart';
import 'package:ttm/providers/language_provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _deleteAccount() async {
    // 1. 확인 팝업
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LanguageProvider().getText('delete_account')),
        content: Text(LanguageProvider().getText('delete_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LanguageProvider().getText('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(LanguageProvider().getText('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. 삭제 요청
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception("로그인 정보가 없습니다.");
      }

      print('회원 탈퇴 요청 시작: Member ID ${user.memberId}');
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/members/${user.memberId}');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        // 3. 로그아웃 및 초기화 화면 이동
        await _authService.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
          );
        }
      } else {
        throw Exception('회원 탈퇴 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('회원 탈퇴 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageProvider().getText('delete_account')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 64, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              '정말로 탈퇴하시겠습니까?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '회원 탈퇴 시 작성하신 게시글, 식단 기록, 운동 기록 등 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.',
              style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(LanguageProvider().getText('delete'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
