import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ZegoCallService {
  static final ZegoCallService _instance = ZegoCallService._internal();
  factory ZegoCallService() => _instance;
  ZegoCallService._internal();

  /// مفاتيح Zego - تأكد من أن هذه المفاتيح متطابقة في جميع الملفات!
  static const int _zegoAppId = 1335900570;
  static const String _zegoAppSign =
      '412035e8ee25f60dcc716b5ba608090d3d4f727320b08ccfc44e4f565867f1c3';

  static const String _logTag = '📞 [Zego Call Service]';

  /// Plugin واحد فقط
  static final ZegoUIKitSignalingPlugin _signalingPlugin = ZegoUIKitSignalingPlugin();

  static bool _isInitialized = false;
  static bool _isConnecting = false;

  static bool get isInitialized => _isInitialized;

  /// ✅ تهيئة Zego
  /// يتم تهيئة خدمة المكالمات من Zego Cloud
  static Future<bool> initialize({
    required String userID,
    required String userName,
  }) async {
    if (_isInitialized) {
      _logSuccess("Zego مهيأ بالفعل");
      return true;
    }

    if (_isConnecting) {
      _logWarning("جاري التهيئة بالفعل...");
      return false;
    }

    try {
      _isConnecting = true;
      _logInfo("🚀 تهيئة Zego للمستخدم: $userID مع الاسم: $userName");
      _logDebug("App ID: $_zegoAppId");

      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: _zegoAppId,
        appSign: _zegoAppSign,
        userID: userID,
        userName: userName,
        plugins: [_signalingPlugin],
      );

      _logDebug("تم استدعاء init بنجاح");

      // تحقق من الاتصال بالـ signaling مع إعادة محاولة
      bool connected = await _waitForSignalingConnection(maxRetries: 3);
      if (!connected) {
        _logError("فشل الاتصال بخدمة signaling بعد التهيئة");
        return false;
      }

      _isInitialized = true;
      _logSuccess("تم تهيئة Zego بنجاح وتم الاتصال بـ signaling");
      return true;
    } catch (e) {
      _logError("خطأ تهيئة Zego: $e");
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// ✅ انتظار اتصال signaling مع إعادة محاولة متعددة
  /// هذا ضروري جداً للتأكد من أن الاتصال بخادم signaling مستقر
  /// قبل محاولة إرسال أي دعوات مكالمات
  static Future<bool> _waitForSignalingConnection({
    int timeoutSeconds = 15,  // زيادة timeout إلى 15 ثانية
    int maxRetries = 3
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      _logInfo("⏳ محاولة الاتصال بالـ signaling #$attempt من $maxRetries");

      int elapsed = 0;
      final maxWait = timeoutSeconds;

      while (_signalingPlugin.getConnectionState() !=
             ZegoSignalingPluginConnectionState.connected &&
          elapsed < maxWait) {
        _logDebug("   ⏳ انتظار اتصال signaling... (${elapsed + 1}/${maxWait}s)");
        await Future.delayed(const Duration(seconds: 1));
        elapsed++;
      }

      final currentState = _signalingPlugin.getConnectionState();
      _logDebug("🔍 حالة الاتصال الحالية: $currentState");

      if (currentState == ZegoSignalingPluginConnectionState.connected) {
        _logSuccess("✅ تم الاتصال بالـ signaling بنجاح!");
        return true;
      } else {
        _logWarning("⚠️ لم يتم الاتصال بالـ signaling في المحاولة #$attempt (الحالة: $currentState)");
        if (attempt < maxRetries) {
          _logDebug("   🔄 إعادة المحاولة بعد 3 ثوان...");
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }

    _logError("❌ فشل الاتصال بالـ signaling بعد $maxRetries محاولات!");
    _logError("⚠️ تأكد من:");
    _logError("  1. اتصال الإنترنت جيد");
    _logError("  2. خوادم ZEGO متاحة");
    _logError("  3. المستخدم مسجل الدخول");
    return false;
  }

  /// ✅ الحصول على حالة signaling الحالية
  static String getSignalingStatus() {
    final state = _signalingPlugin.getConnectionState();
    final isInit = _isInitialized;
    return "Initialized: $isInit, State: $state";
  }

  /// ✅ إرسال دعوة مكالمة
  /// هذه الدالة تتعامل مع كل جوانب إرسال دعوة المكالمة
  /// بما فيها التحقق من التهيئة والاتصال والتسجيل
  static Future<void> _startCall({
    required String targetUserId,
    required String targetUserName,
    required String callId,
    required bool isVideoCall,
    required BuildContext context,
  }) async {
    try {
      _logInfo(isVideoCall
        ? "📹 محاولة إرسال دعوة مكالمة فيديو"
        : "📞 محاولة إرسال دعوة مكالمة صوتية");

      _logDebug("التفاصيل:");
      _logDebug("  - المستقبل (targetUserId): $targetUserId");
      _logDebug("  - اسم المستقبل: $targetUserName");
      _logDebug("  - معرف المكالمة: $callId");

      // ✅ التحقق من وجود مستخدم مسجل الدخول
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logError("لا يوجد مستخدم مسجل الدخول!");
        _showSnack(context, "يجب تسجيل الدخول أولاً", Colors.red);
        return;
      }

      _logDebug("المرسل (currentUser): ${user.uid}");

      // ✅ تحذير إذا كان المستقبل والمرسل نفس الشخص
      if (targetUserId == user.uid) {
        _logError("لا يمكن الاتصال بنفسك!");
        _showSnack(context, "لا يمكنك الاتصال بنفسك", Colors.red);
        return;
      }

      // ✅ التحقق من تهيئة Zego - محاولة متعددة
      if (!_isInitialized) {
        _logWarning("⚠️ Zego لم يتم تهيئته بعد - جاري التهيئة...");
        bool ok = await initialize(
          userID: user.uid,
          userName: user.displayName ?? "User_${user.uid.substring(0, 5)}",
        );
        if (!ok) {
          _logError("❌ فشل تهيئة Zego - تأكد من اتصال الإنترنت");
          _showSnack(
            context,
            "خطأ: فشل الاتصال بخدمة المكالمات\n\nتأكد من:\n1. اتصال الإنترنت\n2. صلاحيات التطبيق",
            Colors.red
          );
          return;
        }
      }

      // ✅ التحقق من اتصال signaling - مع محاولات إضافية
      _logDebug("🔍 التحقق من اتصال signaling...");
      bool connected = await _waitForSignalingConnection(maxRetries: 3);
      if (!connected) {
        _logError("❌ فشل الاتصال بخدمة signaling - المحاولات استنفدت");
        _showSnack(
          context,
          "خطأ: فشل الاتصال بخدمة المكالمات\n\nيرجى المحاولة مجدداً أو تفعيل إعادة التهيئة",
          Colors.red
        );
        // محاولة إعادة التهيئة تلقائياً
        _isInitialized = false;
        return;
      }

      _logSuccess("✅ جاهز لإرسال الدعوة - signaling متصل");

      // ✅ تأخير صغير لضمان الاستقرار
      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ إرسال الدعوة
      _logInfo("🚀 إرسال الدعوة للمستخدم: $targetUserId");

      await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [ZegoCallUser(targetUserId, targetUserName)],
        isVideoCall: isVideoCall,
        callID: callId,
      );

      _logSuccess("✅ تم إرسال الدعوة بنجاح! في انتظار رد المستقبل...");

      // ✅ تسجيل المكالمة في قاعدة البيانات
      await _saveCallLog(targetUserId, isVideoCall ? "video" : "audio");

      // ✅ إظهار رسالة النجاح
      _showSnack(
        context,
        isVideoCall
          ? "✅ تم إرسال دعوة فيديو\n⏳ في انتظار رد المستقبل..."
          : "✅ تم إرسال دعوة صوت\n⏳ في انتظار رد المستقبل...",
        Colors.green
      );

    } catch (e, stackTrace) {
      _logError("❌ خطأ أثناء إرسال الدعوة");
      _logError("❌ الخطأ: $e");
      _logError("❌ الـ Stack Trace: $stackTrace");

      // معالجة خصوصية للأخطاء
      String errorMessage = "فشل إرسال دعوة المكالمة";
      if (e.toString().contains("107026")) {
        errorMessage = "المستقبل غير متاح الآن\n\nتأكد من:\n✓ تسجيله الدخول\n✓ تفعيل الإنترنت لديه";
      } else if (e.toString().contains("timeout")) {
        errorMessage = "انتهت مهلة الزمن\n\nحاول مجدداً";
      } else if (e.toString().contains("network")) {
        errorMessage = "خطأ في الاتصال\n\nتحقق من الإنترنت";
      }

      _showSnack(context, errorMessage, Colors.red);
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

  /// ✅ إنهاء المكالمة
  static Future<void> endCall(BuildContext context) async {
    try {
      _logInfo("📵 محاولة إنهاء المكالمة...");
      await ZegoUIKitPrebuiltCallController().hangUp(context);
      _logSuccess("✅ تم إنهاء المكالمة بنجاح");
    } catch (e) {
      _logError("خطأ في إنهاء المكالمة: $e");
    }
  }

  /// ✅ إلغاء التهيئة
  static Future<void> uninitialize() async {
    try {
      _logInfo("🛑 جاري إيقاف Zego...");
      await ZegoUIKitPrebuiltCallInvitationService().uninit();
      _isInitialized = false;
      _logSuccess("✅ تم إيقاف Zego بنجاح");
    } catch (e) {
      _logError("خطأ في إيقاف Zego: $e");
    }
  }

  // ============ Logging Functions ============

  static void _logDebug(String message) {
    debugPrint('$_logTag 🔍 $message');
  }

  static void _logInfo(String message) {
    debugPrint('$_logTag ℹ️ $message');
  }

  static void _logSuccess(String message) {
    debugPrint('$_logTag ✅ $message');
  }

  static void _logWarning(String message) {
    debugPrint('$_logTag ⚠️ $message');
  }

  static void _logError(String message) {
    debugPrint('$_logTag ❌ $message');
  }
}
