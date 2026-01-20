import 'package:permission_handler/permission_handler.dart';

/// 앱 권한 관리 서비스
class PermissionService {
  /// 모든 필수 권한 요청
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = {};

    // 알림 권한
    statuses[Permission.notification] = await Permission.notification.request();
    
    // 카메라 권한
    statuses[Permission.camera] = await Permission.camera.request();
    
    // 블루투스 권한 (Android 12 이상)
    if (await Permission.bluetoothConnect.isDenied) {
      statuses[Permission.bluetoothConnect] = await Permission.bluetoothConnect.request();
    }
    if (await Permission.bluetoothScan.isDenied) {
      statuses[Permission.bluetoothScan] = await Permission.bluetoothScan.request();
    }

    return statuses;
  }

  /// 알림 권한 요청
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// 카메라 권한 요청
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// 블루투스 권한 요청
  static Future<bool> requestBluetoothPermissions() async {
    final connectStatus = await Permission.bluetoothConnect.request();
    final scanStatus = await Permission.bluetoothScan.request();
    return connectStatus.isGranted && scanStatus.isGranted;
  }

  /// 권한 상태 확인
  static Future<bool> checkPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// 설정 화면으로 이동
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// 권한 거부 여부 확인
  static Future<bool> isPermissionDenied(Permission permission) async {
    final status = await permission.status;
    return status.isDenied || status.isPermanentlyDenied;
  }
}
