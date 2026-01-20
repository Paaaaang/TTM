import 'package:flutter/material.dart';
import 'package:ttm/providers/language_provider.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = LanguageProvider();
    
    return AnimatedBuilder(
      animation: languageProvider,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(languageProvider.getText('language_settings')),
          ),
          body: ListView(
            children: [
              _buildLanguageItem(
                context,
                title: '한국어',
                subtitle: 'Korean',
                isSelected: languageProvider.isKorean,
                onTap: () {
                  languageProvider.setLocale(const Locale('ko', 'KR'));
                },
              ),
              _buildLanguageItem(
                context,
                title: 'English',
                subtitle: '영어',
                isSelected: !languageProvider.isKorean,
                onTap: () {
                  languageProvider.setLocale(const Locale('en', 'US'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF1DB954))
          : null,
      onTap: onTap,
    );
  }
}
