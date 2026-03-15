import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ZegoCallService {
  static final ZegoCallService _instance = ZegoCallService._internal();
  factory ZegoCallService() => _instance;
  ZegoCallService._internal();

  /// مفاتيح Zego
  static const int _zegoAppId = 1335900570;
  static const String _zegoAppSign =
      '412035e8ee25f60dcc716b5ba608090d3d4f727320b08ccfc44e4f565867f1c3';

  /// Plugin واحد فقط
  static final ZegoUIKitSignalingPlugin _signalingPlugin = ZegoUIKitSignalingPlugin();

  static bool _isInitialized = false;
  static bool _isConnecting = false;

  static bool get isInitialized => _isInitialized;

  /// تهيئة Zego
  static Future<bool> initialize({
    required String userID,
    required String userName,
  }) async {
    if (_isInitialized) {
      debugPrint("✅ Zego مهيأ بالفعل");
      return true;
    }

    if (_isConnecting) {
      debugPrint("⏳ جاري التهيئة...");
      return false;
    }

    try {
      _isConnecting = true;
      debugPrint("🚀 تهيئة Zego للمستخدم $userID");

      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: _zegoAppId,
        appSign: _zegoAppSign,
        userID: userID,
        userName: userName,
        plugins: [_signalingPlugin],
      );

      // تحقق من الاتصال بالـ signaling مع إعادة محاولة
      bool connected = await _waitForSignalingConnection(maxRetries: 3);
      if (!connected) {
        debugPrint("❌ فشل الاتصال بخدمة signaling بعد التهيئة");
        return false;
      }

      _isInitialized = true;
      debugPrint("✅ تم تهيئة Zego بنجاح");
      return true;
    } catch (e) {
      debugPrint("❌ خطأ تهيئة Zego: $e");
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// انتظار اتصال signaling مع إعادة محاولة متعددة
  static Future<bool> _waitForSignalingConnection({int timeoutSeconds = 10, int maxRetries = 2}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint("⏳ محاولة الاتصال بالـ signaling #$attempt");
      int elapsed = 0;
      while (_signalingPlugin.getConnectionState() != ZegoSignalingPluginConnectionState.connected &&
          elapsed < timeoutSeconds) {
        debugPrint("   - انتظار اتصال signaling... (${elapsed + 1}s)");
        await Future.delayed(const Duration(seconds: 1));
        elapsed++;
      }

      if (_signalingPlugin.getConnectionState() == ZegoSignalingPluginConnectionState.connected) {
        debugPrint("✅ تم الاتصال بالـ signaling");
        return true;
      } else {
        debugPrint("⚠️ لم يتم الاتصال بالـ signaling في المحاولة #$attempt");
        if (attempt < maxRetries) {
          debugPrint("   إعادة المحاولة بعد 2 ثانية...");
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    debugPrint("❌ فشل الاتصال بالـ signaling بعد $maxRetries محاولات");
    return false;
  }

  /// إرسال دعوة مكالمة
  static Future<void> _startCall({
    required String targetUserId,
    required String targetUserName,
    required String callId,
    required bool isVideoCall,
    required BuildContext context,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (!_isInitialized) {
        bool ok = await initialize(
          userID: user.uid,
          userName: user.displayName ?? "User",
        );
        if (!ok) {
          _showSnack(context, "فشل الاتصال بخدمة المكالمات", Colors.red);
          return;
        }
      }

      bool connected = await _waitForSignalingConnection();
      if (!connected) {
        _showSnack(context, "فشل الاتصال بخدمة المكالمات", Colors.red);
        return;
      }

      debugPrint(isVideoCall ? "📹 إرسال دعوة فيديو" : "📞 إرسال دعوة صوت");

      await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [ZegoCallUser(targetUserId, targetUserName)],
        isVideoCall: isVideoCall,
        callID: callId,
      );

      await _saveCallLog(targetUserId, isVideoCall ? "video" : "audio");
      _showSnack(context, "تم إرسال دعوة المكالمة", Colors.green);
    } catch (e) {
      debugPrint("❌ خطأ المكالمة: $e");
      _showSnack(context, "فشل إرسال الدعوة", Colors.red);
    }
  }

  /// مكالمة فيديو
  static Future<void> startVideoCall({
    required String targetUserId,
    required String targetUserName,
    required String callId,
    required BuildContext context,
  }) async {
    await _startCall(
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      callId: callId,
      isVideoCall: true,
      context: context,
    );
  }

  /// مكالمة صوتية
  static Future<void> startAudioCall({
    required String targetUserId,
    required String targetUserName,
    required String callId,
    required BuildContext context,
  }) async {
    await _startCall(
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      callId: callId,
      isVideoCall: false,
      context: context,
    );
  }

  /// حفظ سجل المكالمة
  static Future<void> _saveCallLog(String targetUserId, String callType) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection("call_logs").add({
        "callerId": user.uid,
        "receiverId": targetUserId,
        "callType": callType,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "initiated"
      });
    } catch (e) {
      debugPrint("خطأ حفظ سجل المكالمة $e");
    }
  }

  static void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  /// إنهاء المكالمة
  static Future<void> endCall(BuildContext context) async {
    try {
      await ZegoUIKitPrebuiltCallController().hangUp(context);
    } catch (e) {
      debugPrint("خطأ إنهاء المكالمة $e");
    }
  }

  /// إلغاء التهيئة
  static Future<void> uninitialize() async {
    try {
      await ZegoUIKitPrebuiltCallInvitationService().uninit();
      _isInitialized = false;
      debugPrint("تم إيقاف Zego");
    } catch (e) {
      debugPrint("خطأ إيقاف Zego $e");
    }
  }
}