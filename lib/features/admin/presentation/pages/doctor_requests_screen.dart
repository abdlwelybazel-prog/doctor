import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/admin/models/admin_models.dart';
import 'package:digl/features/admin/services/admin_service.dart';
import 'package:digl/features/admin/presentation/pages/doctor_request_details_screen.dart';

class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen> {
  String _selectedFilter = 'pending'; // pending, approved, rejected, all
  late Future<List<DoctorRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    if (_selectedFilter == 'all') {
      _requestsFuture = AdminService.getAllDoctorRequests();
    } else {
      _requestsFuture = AdminService.getAllDoctorRequests(status: _selectedFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: FutureBuilder<List<DoctorRequest>>(
            future: _requestsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      const Text('حدث خطأ في تحميل البيانات'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _loadRequests());
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              final requests = snapshot.data ?? [];

              if (requests.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() => _loadRequests());
                  await _requestsFuture;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(requests[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterButton('قيد الانتظار', 'pending'),
            const SizedBox(width: 8),
            _buildFilterButton('موافق عليها', 'approved'),
            const SizedBox(width: 8),
            _buildFilterButton('مرفوضة', 'rejected'),
            const SizedBox(width: 8),
            _buildFilterButton('الكل', 'all'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _loadRequests();
        });
      },
      backgroundColor: isSelected ? Colors.transparent : Colors.white,
      selectedColor: const Color(0xFF3A86FF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3A86FF) : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildRequestCard(DoctorRequest request) {
    Color statusColor;
    String statusLabel;

    switch (request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'قيد الانتظار';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'موافق عليها';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'مرفوضة';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'غير معروف';
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_add, color: statusColor),
        ),
        title: Text(
          request.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              request.specialty,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(request.createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DoctorRequestDetailsScreen(request: request),
            ),
          );

          // إعادة تحميل البيانات بعد العودة من تفاصيل الطلب
          if (mounted) {
            setState(() => _loadRequests());
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات ${_getFilterLabel()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض الطلبات هنا عند استقبالها',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'الموافق عليها';
      case 'rejected':
        return 'المرفوضة';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'قبل ${difference.inMinutes} دقيقة';
      }
      return 'قبل ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'قبل ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
