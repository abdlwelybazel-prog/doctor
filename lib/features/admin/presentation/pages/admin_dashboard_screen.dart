import 'package:flutter/material.dart';
import 'package:digl/features/admin/models/admin_models.dart';
import 'package:digl/features/admin/services/admin_service.dart';
import 'package:digl/features/admin/presentation/pages/doctor_requests_screen.dart';
import 'package:digl/features/admin/presentation/pages/admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminUser admin;

  const AdminDashboardScreen({super.key, required this.admin});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminStats> _statsFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminService.getAdminStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardContent(theme),
          const DoctorRequestsScreen(),
          _buildSettingsContent(theme),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.disabledColor,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'لوحة التحكم',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'طلبات الأطباء',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.primaryColor,
      foregroundColor: Colors.white,
      title: const Text('لوحة التحكم الإدارية'),
      centerTitle: true,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: _showAdminProfile,
        ),
      ],
    );
  }

  Widget _buildDashboardContent(ThemeData theme) {
    return FutureBuilder<AdminStats>(
      future: _statsFuture,
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
                const Text('حدث خطأ في تحميل البيانات', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _statsFuture = AdminService.getAdminStats();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _statsFuture = AdminService.getAdminStats();
            });
            await _statsFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeCard(theme),
                const SizedBox(height: 24),
                _buildStatsGrid(stats, theme),
                const SizedBox(height: 24),
                _buildPendingRequestsCard(stats, theme),
                const SizedBox(height: 24),
                _buildQuickActionsCard(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، ${widget.admin.fullName}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'دورك: ${widget.admin.role == 'super_admin' ? 'مسؤول عام' : 'مسؤول'}',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdminStats stats, ThemeData theme) {
    final cardColors = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.amberAccent,
    ];

    final statsList = [
      {'title': 'إجمالي الأطباء', 'value': stats.totalDoctors.toString(), 'icon': Icons.local_hospital, 'color': cardColors[0]},
      {'title': 'طلبات معلقة', 'value': stats.pendingRequests.toString(), 'icon': Icons.assignment_ind, 'color': cardColors[1]},
      {'title': 'أطباء موافق عليهم', 'value': stats.approvedDoctors.toString(), 'icon': Icons.verified_user, 'color': cardColors[2]},
      {'title': 'إجمالي المرضى', 'value': stats.totalPatients.toString(), 'icon': Icons.people, 'color': cardColors[3]},
      {'title': 'المواعيد الإجمالية', 'value': stats.totalAppointments.toString(), 'icon': Icons.calendar_today, 'color': cardColors[4]},
      {'title': 'متوسط التقييم', 'value': stats.averageDoctorRating.toStringAsFixed(1), 'icon': Icons.star, 'color': cardColors[5]},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: statsList.length,
      itemBuilder: (context, index) {
        final item = statsList[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 30),
                ),
                const SizedBox(height: 14),
                Text(item['value'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(item['title'] as String,
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildPendingRequestsCard(AdminStats stats, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.orange.withOpacity(0.1),
      shadowColor: Colors.orange.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'طلبات معلقة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يوجد ${stats.pendingRequests} طلب يحتاج إلى مراجعة',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _currentIndex = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('عرض الطلبات', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ThemeData theme) {
    final actions = [
      {'icon': Icons.assignment_ind, 'label': 'الطلبات', 'color': Colors.blueAccent, 'tap': () => setState(() => _currentIndex = 1)},
      {'icon': Icons.person_add, 'label': 'إضافة مسؤول', 'color': Colors.greenAccent, 'tap': () => _showComingSoon()},
      {'icon': Icons.analytics, 'label': 'التقارير', 'color': Colors.purpleAccent, 'tap': () => _showComingSoon()},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إجراءات سريعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: actions.map((action) {
                return ElevatedButton(
                  onPressed: action['tap'] as VoidCallback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action['color'] as Color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action['icon'] as IconData, size: 28),
                      const SizedBox(height: 8),
                      Text(action['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذه الميزة قريباً...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSettingsContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'معلومات الحساب',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('الاسم', widget.admin.fullName, theme),
                _buildInfoRow('البريد الإلكتروني', widget.admin.email, theme),
                _buildInfoRow('رقم الهاتف', widget.admin.phoneNumber, theme),
                _buildInfoRow(
                  'الدور',
                  widget.admin.role == 'super_admin' ? 'مسؤول عام' : 'مسؤول',
                  theme,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('تسجيل الخروج'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: theme.disabledColor),
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

  void _showAdminProfile() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملف المسؤول',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('الملف الشخصي'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('الأمان'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('المساعدة'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
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

    if (confirmed == true) {
      await AdminService.logoutAdmin();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AdminLoginScreen(),
        ),
      );
    }
  }
}
