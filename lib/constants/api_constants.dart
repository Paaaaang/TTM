import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // 실제 기기 시연 모드 (true: 실제 iPhone/Android 기기, false: 시뮬레이터/에뮬레이터)
  static const bool useRealDevice = false;
  
  // 실제 기기 시연 시 사용할 PC의 IP 주소 (WiFi 같은 네트워크에 연결 필요)
  // Windows에서 확인: ipconfig (무선 LAN 어댑터 Wi-Fi의 IPv4 주소)
  // Mac에서 확인: ifconfig | grep "inet " (en0의 IP)
  static const String realDeviceIp = '192.168.0.100'; // 시연 전 PC IP로 변경 필요
  
  // 플랫폼에 따라 자동으로 적절한 baseUrl 선택
  static String get baseUrl {
    if (kIsWeb) {
      // 웹 환경
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // Android
      return useRealDevice 
          ? 'http://$realDeviceIp:3000'  // 실제 기기
          : 'http://10.0.2.2:3000';       // 에뮬레이터
    } else if (Platform.isIOS) {
      // iOS
      return useRealDevice
          ? 'http://$realDeviceIp:3000'  // 실제 iPhone
          : 'http://localhost:3000';      // 시뮬레이터
    } else {
      // Windows, macOS, Linux 데스크톱
      return 'http://localhost:3000';
    }
  }
  
  // Auth endpoints
  static const String authSignup = '/api/auth/signup';
  static const String authLogin = '/api/auth/login';
  
  // Member endpoints
  static String memberHealth(int memberId) => '/api/members/$memberId/health';
  
  // 타임아웃 설정
  static const Duration timeout = Duration(seconds: 30);
}
