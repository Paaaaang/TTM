/// 약관 동의 위젯
import 'package:flutter/material.dart';
import 'package:ttm/constants/terms_content.dart';

class TermsAgreementWidget extends StatefulWidget {
  final bool agreeAll;
  final bool agreeTerms;
  final bool agreePrivacy;
  final bool agreeMarketing;
  final bool agreeKakao;
  final bool agreePush;
  final bool agreeSMS;
  final bool agreeEmail;
  final Function(bool) onAgreeAllChanged;
  final Function(bool) onAgreeTermsChanged;
  final Function(bool) onAgreePrivacyChanged;
  final Function(bool) onAgreeMarketingChanged;
  final Function(bool) onAgreeKakaoChanged;
  final Function(bool) onAgreePushChanged;
  final Function(bool) onAgreeSMSChanged;
  final Function(bool) onAgreeEmailChanged;

  const TermsAgreementWidget({
    Key? key,
    required this.agreeAll,
    required this.agreeTerms,
    required this.agreePrivacy,
    required this.agreeMarketing,
    required this.agreeKakao,
    required this.agreePush,
    required this.agreeSMS,
    required this.agreeEmail,
    required this.onAgreeAllChanged,
    required this.onAgreeTermsChanged,
    required this.onAgreePrivacyChanged,
    required this.onAgreeMarketingChanged,
    required this.onAgreeKakaoChanged,
    required this.onAgreePushChanged,
    required this.onAgreeSMSChanged,
    required this.onAgreeEmailChanged,
  }) : super(key: key);

  @override
  State<TermsAgreementWidget> createState() => _TermsAgreementWidgetState();
}

class _TermsAgreementWidgetState extends State<TermsAgreementWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 전체 동의
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: CheckboxListTile(
              value: widget.agreeAll,
              onChanged: (value) => widget.onAgreeAllChanged(value ?? false),
              title: const Text(
                '전체 동의',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF66BB6A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
          ),
          
          const Divider(height: 1),
          
          // 이용약관 동의 (필수)
          _buildTermItem(
            title: '이용약관 동의',
            isRequired: true,
            value: widget.agreeTerms,
            onChanged: (value) => widget.onAgreeTermsChanged(value ?? false),
            onDetailTap: () => _showTermsDialog(context, '이용약관'),
          ),
          
          // 개인정보수집 및 이용 동의 (필수)
          _buildTermItem(
            title: '개인정보수집 및 이용 동의',
            isRequired: true,
            value: widget.agreePrivacy,
            onChanged: (value) => widget.onAgreePrivacyChanged(value ?? false),
            onDetailTap: () => _showTermsDialog(context, '개인정보수집'),
          ),
          
          // 마케팅 수신동의 (선택)
          _buildTermItem(
            title: '마케팅 수신동의',
            isRequired: false,
            value: widget.agreeMarketing,
            onChanged: (value) => widget.onAgreeMarketingChanged(value ?? false),
            onDetailTap: () => _showTermsDialog(context, '마케팅'),
            hasExpand: false,
          ),
          
          // 마케팅 수신동의 상세 (항상 표시)
          ...[
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: [
                  _buildSubTermItem('카카오톡', widget.agreeKakao, (value) {
                    widget.onAgreeKakaoChanged(value ?? false);
                  }),
                  _buildSubTermItem('Push 알림', widget.agreePush, (value) {
                    widget.onAgreePushChanged(value ?? false);
                  }),
                  _buildSubTermItem('문자(SMS)', widget.agreeSMS, (value) {
                    widget.onAgreeSMSChanged(value ?? false);
                  }),
                  _buildSubTermItem('이메일', widget.agreeEmail, (value) {
                    widget.onAgreeEmailChanged(value ?? false);
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 약관 항목 위젯
  Widget _buildTermItem({
    required String title,
    required bool isRequired,
    required bool value,
    required Function(bool?) onChanged,
    required VoidCallback onDetailTap,
    bool hasExpand = false,
    bool isExpanded = false,
    VoidCallback? onExpandTap,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF66BB6A),
              ),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(!value),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isRequired ? '(필수)' : '(선택)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isRequired ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasExpand)
              IconButton(
                icon: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
                onPressed: onExpandTap,
              ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
              ),
              onPressed: onDetailTap,
            ),
          ],
          ),
        ),
        if (!hasExpand || (hasExpand && !isExpanded))
          const Divider(height: 1),
      ],
    );
  }

  /// 하위 약관 항목 위젯
  Widget _buildSubTermItem(String title, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF66BB6A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                title,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 약관 상세 다이얼로그
  void _showTermsDialog(BuildContext context, String type) {
    String title;
    String content;
    
    switch (type) {
      case '이용약관':
        title = '이용약관';
        content = TermsContent.termsOfService;
        break;
        
      case '개인정보수집':
        title = '개인정보 수집 및 이용 동의';
        content = TermsContent.privacyPolicy;
        break;
        
      case '마케팅':
        title = '마케팅 정보 수신 동의';
        content = TermsContent.marketingConsent;
        break;
        
      default:
        title = '약관';
        content = '약관 내용이 없습니다.';
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF66BB6A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // 내용
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              // 확인 버튼
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66BB6A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
