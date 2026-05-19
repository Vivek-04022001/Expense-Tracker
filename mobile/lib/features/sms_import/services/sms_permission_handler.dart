import 'package:permission_handler/permission_handler.dart';

enum SmsPermissionResult { granted, denied, permanentlyDenied }

class SmsPermissionHandler {
  Future<SmsPermissionResult> request() async {
    final status = await Permission.sms.status;
    if (status.isGranted) return SmsPermissionResult.granted;
    if (status.isPermanentlyDenied) {
      return SmsPermissionResult.permanentlyDenied;
    }

    final result = await Permission.sms.request();
    if (result.isGranted) return SmsPermissionResult.granted;
    if (result.isPermanentlyDenied) {
      return SmsPermissionResult.permanentlyDenied;
    }
    return SmsPermissionResult.denied;
  }

  Future<void> openSettings() => openAppSettings();
}
