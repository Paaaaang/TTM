/// 언어 설정 화면
import 'package:flutter/material.dart';

/// 언어 설정 화면 위젯
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'ko';

  final List<Map<String, String>> _languages = [
    {'code': 'ko', 'name': '한국어', 'englishName': 'Korean'},
    {'code': 'en', 'name': 'English', 'englishName': 'English'},
    {'code': 'ja', 'name': '日本語', 'englishName': 'Japanese'},
    {'code': 'zh', 'name': '中文', 'englishName': 'Chinese'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('언어 설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            child: Column(
              children: _languages.map((language) {
                final isSelected = _selectedLanguage == language['code'];
                return ListTile(
                  title: Text(
                    language['name']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    language['englishName']!,
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF66BB6A),
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLanguage = language['code']!;
                    });
                    // TODO: 실제 언어 변경 로직
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${language['name']}로 변경되었습니다'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '언어 변경 후 앱을 다시 시작하면 적용됩니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
