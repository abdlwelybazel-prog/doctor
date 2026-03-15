// lib/services/appointment_notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class AppointmentNotificationService {
  static final AppointmentNotificationService _instance =
  AppointmentNotificationService._internal();

  factory AppointmentNotificationService() => _instance;
  AppointmentNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    const AndroidNotificationChannel appointmentChannel = AndroidNotificationChannel(
      'appointment_channel',
      'تنبيهات المواعيد',
      description: 'إشعارات تذكير بمواعيد العيادة',
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(appointmentChannel);
  }

  Future<void> scheduleAppointmentReminders(String appointmentId) async {
    final appointmentDoc = await _firestore
        .collection('appointments')
        .doc(appointmentId)
        .get();

    if (!appointmentDoc.exists) return;

    final data = appointmentDoc.data()!;
    final DateTime appointmentDate = (data['date'] as Timestamp).toDate();
    final String doctorName = data['doctorName'] ?? 'الطبيب';
    final String location = data['workplace'] ?? 'العيادة';

    // إشعار قبل الموعد بيوم
    await _scheduleSingleReminder(
      id: appointmentId.hashCode + 1,
      title: 'تذكير بالموعد غداً',
      body: 'لديك موعد غداً مع د. $doctorName في $location',
      scheduledDate: appointmentDate.subtract(const Duration(days: 1)),
    );

    // إشعار قبل الموعد بـ 6 ساعات
    await _scheduleSingleReminder(
      id: appointmentId.hashCode + 2,
      title: 'تذكير بالموعد بعد 6 ساعات',
      body: 'لديك موعد بعد 6 ساعات مع د. $doctorName',
      scheduledDate: appointmentDate.subtract(const Duration(hours: 6)),
    );

    // إشعار قبل الموعد بساعة
    await _scheduleSingleReminder(
      id: appointmentId.hashCode + 3,
      title: 'تذكير بالموعد بعد ساعة',
      body: 'لديك موعد بعد ساعة مع د. $doctorName في $location',
      scheduledDate: appointmentDate.subtract(const Duration(hours: 1)),
    );

    // تحديث حالة الإشعارات في Firebase
    await _firestore.collection('appointments').doc(appointmentId).update({
      'notified': {
        '1day': true,
        '6hours': true,
        '1hour': true,
      }
    });
  }

  Future<void> _scheduleSingleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tz.TZDateTime scheduledTzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    if (scheduledTzDate.isAfter(tz.TZDateTime.now(tz.local))) {
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_channel',
          'تنبيهات المواعيد',
          channelDescription: 'إشعارات تذكير بمواعيد العيادة',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      );


    }
  }

  // مراقبة المواعيد الجديدة للمستخدم
  void listenToUserAppointments(String userId) {
    _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          // فلترة محلياً للتحقق من الحالة
          final status = doc.doc.data()?['status'];
          if (status == 'pending' || status == 'confirmed') {
            scheduleAppointmentReminders(doc.doc.id);
          }
        }
      }
    });
  }
}
