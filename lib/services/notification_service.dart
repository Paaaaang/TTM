import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 백그라운드 메시지 수신: ${message.notification?.title}');
}

/// FCM 푸시 알림 서비스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Firebase 및 알림 초기화
  Future<void> initialize() async {
    // Firebase 초기화는 main.dart에서 이미 완료
    
    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 로컬 알림 초기화
    await _initializeLocalNotifications();

    // FCM 권한 요청
    await _requestPermission();

    // FCM 토큰 가져오기
    await _getFCMToken();

    // 포그라운드 메시지 리스너
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드에서 알림 클릭 시
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 앱이 종료 상태에서 알림으로 실행된 경우
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // FCM 토큰 갱신 리스너
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveFCMToken(newToken);
      print('🔄 FCM 토큰 갱신: $newToken');
    });
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 알림 채널 생성
    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'ttm_channel',
        'TTM 알림',
        description: '게시글 댓글, 좋아요 등의 알림',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// FCM 권한 요청
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('✅ FCM 권한 상태: ${settings.authorizationStatus}');
  }

  /// FCM 토큰 가져오기
  Future<String?> _getFCMToken() async {
    try {
      // iOS의 경우 APNS 토큰 먼저 가져오기
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          print('⏳ APNS 토큰 대기 중...');
          // APNS 토큰이 준비될 때까지 대기
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
        print('📱 FCM 토큰: $_fcmToken');
      }
      return _fcmToken;
    } catch (e) {
      print('❌ FCM 토큰 가져오기 실패: $e');
      return null;
    }
  }

  /// FCM 토큰 저장
  Future<void> _saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// 저장된 FCM 토큰 불러오기
  static Future<String?> getSavedFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 포그라운드 메시지 수신: ${message.notification?.title}');

    // 로컬 알림으로 표시
    _showLocalNotification(message);
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'ttm_channel',
      'TTM 알림',
      channelDescription: '게시글 댓글, 좋아요 등의 알림',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// 알림 탭 처리 (로컬)
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 로컬 알림 탭: ${response.payload}');
    // TODO: 알림 타입에 따라 화면 이동 처리
  }

  /// 알림 탭 처리 (FCM)
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 FCM 알림 탭: ${message.data}');
    
    // 알림 타입에 따라 화면 이동
    final type = message.data['type'];
    final targetId = message.data['targetId'];

    switch (type) {
      case 'comment':
      case 'reply':
        // 게시글 상세로 이동
        print('➡️ 게시글 상세로 이동: postId=$targetId');
        break;
      case 'like':
        // 게시글 상세로 이동
        print('➡️ 게시글 상세로 이동 (좋아요): postId=$targetId');
        break;
      default:
        print('❓ 알 수 없는 알림 타입: $type');
    }
  }

  /// FCM 토큰 서버에 전송
  Future<void> sendTokenToServer(int memberId) async {
    if (_fcmToken == null) {
      print('❌ FCM 토큰이 없습니다.');
      return;
    }

    // TODO: 백엔드 API 호출하여 토큰 저장
    print('📤 서버로 FCM 토큰 전송: memberId=$memberId, token=$_fcmToken');
  }

  /// 알림 구독 토픽
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ 토픽 구독: $topic');
  }

  /// 알림 구독 취소
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('❌ 토픽 구독 취소: $topic');
  }
}
