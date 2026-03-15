import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/medical_theme.dart';
import '../../../core/config/theme.dart';
import '../../appointments/presentation/pages/appointment_details_screen.dart';
import '../../model.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final doctorId = _auth.currentUser?.uid;
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى تسجيل الدخول لعرض الحجوزات'),
          backgroundColor: MedicalTheme.dangerRed,
        ),
      );
      return;
    }

    try {
      // جلب جميع المواعيد للطبيب فقط
      final snap = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      // فلترة وترتيب محلياً
      final filteredDocs = snap.docs.where((doc) {
        final status = (doc.data() as Map<String, dynamic>)['status'];
        return status == 'pending';
      }).toList();

      // ترتيب حسب التاريخ (الأحدث أولاً)
      filteredDocs.sort((a, b) {
        final aCreatedAt = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
        final bCreatedAt = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
        return (bCreatedAt?.toDate() ?? DateTime(1970)).compareTo(aCreatedAt?.toDate() ?? DateTime(1970));
      });

      setState(() {
        bookings = filteredDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل الحجوزات: $e'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  Future<void> _updateBookingStatus(String? bookingId, String status) async {
    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('معرف الحجز غير موجود'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('appointments').doc(bookingId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
      await _loadBookings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'attended' ? 'تمت الموافقة على الحجز بنجاح' : 'تم إلغاء الحجز بنجاح',
          ),
          backgroundColor:
          status == 'attended' ? MedicalTheme.successGreen : MedicalTheme.dangerRed,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء تحديث الحجز: $e'),
          backgroundColor: MedicalTheme.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحجوزات الجديدة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: bookings.isEmpty
            ? const Center(child: Text('لا توجد حجوزات جديدة'))
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index];
            final patientName = data['userName'] ?? 'مريض';
            final reason = data['reason'] ?? 'سبب غير معروف';
            final time = data['date'] != null
                ? DateFormat('dd MMM yyyy, hh:mm a', 'ar')
                .format((data['date'] as Timestamp).toDate())
                : 'بدون وقت';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['userImageUrl'] != null
                      ? NetworkImage(data['userImageUrl'])
                      : null,
                  child: data['userImageUrl'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(patientName),
                subtitle: Text('$time - $reason'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: MedicalTheme.successGreen),
                      onPressed: () => _updateBookingStatus(data['id'], 'attended'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: MedicalTheme.dangerRed),
                      onPressed: () => _updateBookingStatus(data['id'], 'cancelled'),
                    ),
                  ],
                ),
                onTap: () {
                  try {
                    final appointment = Appointment(
                      id: data['id'] ?? '',
                      userId: data['userId'] ?? '',
                      userName: data['userName'] ?? 'مريض',
                      userImageUrl: data['userImageUrl'],
                      userPhone: data['userPhone'],
                      doctorId: data['doctorId'] ?? '',
                      doctorName: data['doctorName'] ?? 'طبيب',
                      doctorImageUrl: data['doctorImageUrl'],
                      doctorPhone: data['doctorPhone'],
                      specialtyName: data['specialtyName'] ?? '',
                      date: data['date'] ?? Timestamp.now(),
                      time: data['time'] ?? '',
                      workplace: data['workplace'] ?? '',
                      payment: data['payment'] ?? '',
                      status: data['status'] ?? 'pending',
                      createdAt: data['createdAt'] ?? Timestamp.now(),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailsScreen(
                            appointment: appointment),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في عرض تفاصيل الحجز: $e'),
                        backgroundColor: AppTheme.alertRed,
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
