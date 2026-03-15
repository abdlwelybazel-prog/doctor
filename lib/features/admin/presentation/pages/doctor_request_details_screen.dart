import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/admin/models/admin_models.dart';
import 'package:digl/features/admin/services/admin_service.dart';

class DoctorRequestDetailsScreen extends StatefulWidget {
  final DoctorRequest request;

  const DoctorRequestDetailsScreen({super.key, required this.request});

  @override
  State<DoctorRequestDetailsScreen> createState() =>
      _DoctorRequestDetailsScreenState();
}

class _DoctorRequestDetailsScreenState extends State<DoctorRequestDetailsScreen> {
  late DoctorRequest _request;
  bool _isLoading = false;
  final _rejectionReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        backgroundColor: const Color(0xFF3A86FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildPersonalInfoCard(),
                  const SizedBox(height: 24),
                  _buildProfessionalInfoCard(),
                  const SizedBox(height: 24),
                  _buildDocumentsCard(),
                  const SizedBox(height: 24),
                  if (_request.status == 'pending') _buildActionButtons(),
                  if (_request.status != 'pending') _buildReviewInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (_request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'قيد الانتظار - ينتظر المراجعة';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'موافق عليها';
        statusIcon = Icons.verified;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'مرفوضة';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'غير معروف';
        statusIcon = Icons.help;
    }

    return Card(
      color: statusColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: Colors.white, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_request.rejectionReason.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'السبب: ${_request.rejectionReason}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'البيانات الشخصية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('الاسم الكامل', _request.fullName),
            _buildInfoRow('البريد الإلكتروني', _request.email),
            _buildInfoRow('رقم الهاتف', _request.phoneNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'البيانات المهنية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('التخصص', _request.specialty),
            _buildInfoRow('سنوات الخبرة', _request.yearsOfExperience),
            _buildInfoRow('اسم العيادة', _request.clinicName),
            _buildInfoRow('عنوان العيادة', _request.clinicAddress),
            if (_request.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'السيرة الذاتية:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _request.bio,
                style: const TextStyle(height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الوثائق والإثباتات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_request.medicalLicense.isNotEmpty)
              _buildDocumentItem(
                'رخصة الممارسة الطبية',
                _request.medicalLicense,
              ),
            if (_request.medicalDegree.isNotEmpty)
              _buildDocumentItem(
                'شهادة التخرج',
                _request.medicalDegree,
              ),
            ..._request.documentUrls.asMap().entries.map((entry) {
              return _buildDocumentItem(
                'وثيقة إضافية ${entry.key + 1}',
                entry.value,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String title, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.description, color: const Color(0xFF3A86FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'تم الرفع',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new,
                color: Color(0xFF3A86FF), size: 20),
            onPressed: () {
              // يمكن فتح الملف هنا
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('فتح الملف...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // زر الموافقة
        ElevatedButton.icon(
          onPressed: _approveRequest,
          icon: const Icon(Icons.verified),
          label: const Text('الموافقة على الطلب'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // زر الرفض
        ElevatedButton.icon(
          onPressed: _showRejectDialog,
          icon: const Icon(Icons.close),
          label: const Text('رفض الطلب'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewInfo() {
    return Card(
      color: Colors.blue[50],
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات المراجعة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'المراجع',
              _request.reviewedBy,
            ),
            _buildInfoRow(
              'تاريخ المراجعة',
              '${_request.reviewedAt.day}/${_request.reviewedAt.month}/${_request.reviewedAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: const Text(
          'هل أنت متأكد من الموافقة على طلب هذا الطبيب؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final admin = FirebaseAuth.instance.currentUser;
      if (admin == null) throw Exception('لم يتم العثور على المسؤول');

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(admin.uid)
          .get();

      final adminName = adminDoc.data()?['fullName'] ?? 'مسؤول';

      await AdminService.approveDoctorRequest(
        _request.id,
        admin.uid,
        adminName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الموافقة على الطلب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الرجاء إدخال سبب الرفض:'),
            const SizedBox(height: 12),
            TextField(
              controller: _rejectionReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب سبب الرفض...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: _rejectionReasonController.text.isNotEmpty
                ? () {
                    Navigator.pop(context);
                    _rejectRequest();
                  }
                : null,
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRequest() async {
    setState(() => _isLoading = true);

    try {
      final admin = FirebaseAuth.instance.currentUser;
      if (admin == null) throw Exception('لم يتم العثور على المسؤول');

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(admin.uid)
          .get();

      final adminName = adminDoc.data()?['fullName'] ?? 'مسؤول';

      await AdminService.rejectDoctorRequest(
        _request.id,
        admin.uid,
        adminName,
        _rejectionReasonController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفض الطلب بنجاح'),
          backgroundColor: Colors.red,
        ),
      );

      _rejectionReasonController.clear();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
