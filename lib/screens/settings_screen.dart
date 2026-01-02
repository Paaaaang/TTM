/// 설정 화면
import 'package:flutter/material.dart';
import 'package:ttm/services/auth_service.dart';

/// 설정 화면 위젯
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          
          // 프로필 섹션
          _buildSection(
            '프로필',
            [
              _buildListTile(
                context,
                icon: Icons.person,
                title: '내 정보 수정',
                onTap: () {
                  Navigator.pushNamed(context, '/settings/profile-edit');
                },
              ),
              _buildListTile(
                context,
                icon: Icons.group,
                title: '친구 목록',
                onTap: () {
                  Navigator.pushNamed(context, '/friends');
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 앱 설정 섹션
          _buildSection(
            '앱 설정',
            [
              _buildListTile(
                context,
                icon: Icons.language,
                title: '언어 설정',
                trailing: const Text(
                  '한국어',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/settings/language');
                },
              ),
              _buildListTile(
                context,
                icon: Icons.notifications,
                title: '알림 설정',
                onTap: () {
                  // TODO: 알림 설정 화면
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 고객 지원 섹션
          _buildSection(
            '고객 지원',
            [
              _buildListTile(
                context,
                icon: Icons.help_outline,
                title: '도움말',
                onTap: () {
                  Navigator.pushNamed(context, '/help');
                },
              ),
              _buildListTile(
                context,
                icon: Icons.feedback_outlined,
                title: '피드백 보내기',
                onTap: () {
                  Navigator.pushNamed(context, '/settings/feedback');
                },
              ),
              _buildListTile(
                context,
                icon: Icons.info_outline,
                title: '앱 정보',
                trailing: const Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 계정 섹션
          _buildSection(
            '계정',
            [
              _buildListTile(
                context,
                icon: Icons.logout,
                title: '로그아웃',
                textColor: Colors.orange,
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),
              _buildListTile(
                context,
                icon: Icons.delete_forever,
                title: '회원 탈퇴',
                textColor: Colors.red,
                onTap: () {
                  Navigator.pushNamed(context, '/settings/delete-account');
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 섹션 빌드
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  /// 리스트 타일 빌드
  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: textColor ?? Colors.black87,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  /// 로그아웃 확인 다이얼로그
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/onboarding',
                  (route) => false,
                );
              }
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
