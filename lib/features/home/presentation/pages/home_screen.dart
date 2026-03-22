import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digl/features/consultations/presentation/pages/instant_consultation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/upcoming_appointments_widget.dart';
import '../../../../services/appointment_service.dart';
import '../../../../services/health_News_Service.dart';
import '../../../../services/internet_checker_service.dart';
import '../../../../services/medication_service.dart';
import '../../../appointments/presentation/pages/appointments_list_screen.dart';
import '../../../appointments/presentation/pages/book_appointment_screen.dart';
import '../../../doctor/presentation/doctorsListWidget.dart';
import '../../../healthNews/medical_news_widget.dart';
import '../../../healthNews/medical_tips_widget.dart';
import '../../../medications/presentation/pages/medications_screen.dart';
import '../../../model.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'UpcomingMedicationsSection.dart';
import 'notificationsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  bool _isConnected = true;

  String userName = "";
  String userType = "patient";
  String selectedMood = "";

  UserModel? currentUserModel;

  List<Appointment> appointments = [];
  List<Map<String, dynamic>> medications = [];
  List<Map<String, dynamic>> healthNews = [];
  List<HealthNewsItem> chronicTips = [], nutritionTips = [], preventionTips = [], medicalNews = [];

  int unreadNotifications = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadInitialData();
  }

  Future<void> _checkConnection() async {
    _isConnected = await InternetCheckerService.hasInternet();
    setState(() {});
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchCurrentUser(),
      _fetchUserData(),
      _fetchAppointments(),
      _fetchMedications(),
      _fetchHealthStats(),
      _loadTipsAndNews(),
      _fetchHealthNews(),
    ]);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _fetchCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        currentUserModel = UserModel.fromFirestore(doc);
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName = data['fullName']?.toString() ?? "مستخدم";
          userType = data['accountType']?.toString() ?? "patient";
          selectedMood = data['mood']?.toString() ?? "";
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchAppointments() async {
    try {
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      appointments = await appointmentService.getAppointments().first;
      setState(() {});
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      appointments = [];
    }
  }

  Future<void> _fetchMedications() async {
    try {
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      final userMedications = await medicationService.getMedications().first;

      medications = userMedications.take(2).map((med) {
        return {
          "id": med.id,
          "name": med.name,
          "dose": med.dose,
          "schedule": med.schedule,
          "next": med.next,
          "userId": med.userId,
          "history": med.history,
          "times": med.times,
        };
      }).toList();

      setState(() {});
    } catch (e) {
      debugPrint('Error fetching medications: $e');
      medications = [];
    }
  }

  Future<void> _fetchHealthNews() async {
    const apiKey = '549d849192e84b2d9c96d5e29f8ff3c5';
    final url = Uri.parse(
      'https://newsapi.org/v2/everything?q=الصحة OR الطب OR الوقاية OR العلاج&language=ar&sortBy=publishedAt&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List articles = data['articles'];
        healthNews = articles.map((e) {
          return {
            'title': e['title'] ?? 'بدون عنوان',
            'source': e['source']['name'] ?? 'مصدر غير معروف',
            'image': e['urlToImage'],
            'url': e['url'],
            'description': e['description'] ?? '',
            'content': e['content'] ?? '',
          };
        }).toList();
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error fetching health news: $e');
    }
  }

  Future<void> _fetchHealthStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _firestore.collection('healthStats').doc(user.uid).get();
      if (doc.exists) {
        // يمكن معالجة الإحصائيات هنا إذا احتجت
      }
    } catch (e) {
      debugPrint('Error fetching health stats: $e');
    }
  }

  Future<void> _loadTipsAndNews() async {
    try {
      chronicTips = await HealthNewsService.fetchChronicDiseaseTips();
      nutritionTips = await HealthNewsService.fetchNutritionTips();
      preventionTips = await HealthNewsService.fetchPreventionTips();
      medicalNews = await HealthNewsService.fetchNutritionTips();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading tips: $e');
    }
  }

  Future<void> updateMood(String mood) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'mood': mood,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        setState(() => selectedMood = mood);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث حالتك المزاجية بنجاح')),
        );
      }
    } catch (e) {
      debugPrint('Error updating mood: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحديث الحالة المزاجية: $e')),
      );
    }
  }

  PreferredSizeWidget buildAppBar() {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
      elevation: 2,
      title: Text("digl", style: theme.textTheme.headline6?.copyWith(color: Colors.white)),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            if (unreadNotifications > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(unreadNotifications.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentUserModel == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: theme.scaffoldBackgroundColor,
        bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: theme.disabledColor,
        ),
      ),
      child: Scaffold(
        appBar: _currentIndex == 0 ? buildAppBar() : null,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    WelcomeMoodSection(
                      userName: userName,
                      userType: userType,
                      selectedMood: selectedMood,
                      onMoodSelected: updateMood,
                    ),
                    UpcomingAppointmentsWidget(appointments: appointments),
                    UpcomingMedicationsSection(medications: medications),
                    if (currentUserModel!.isPatient) const DoctorsListWidget(),
                    const MedicalTipsWidget(),
                    const MedicalNewsWidget(),
                  ],
                ),
              ),
            ),
            currentUserModel!.isPatient
                ? const BookAppointmentScreen()
                : const AppointmentsListScreen(),
            const InstantConsultationScreen(),
            const MedicationsScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'المواعيد'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'استشارة'),
            BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'الأدوية'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

/// ===========================
/// Welcome & Mood Section Widget
/// ===========================
class WelcomeMoodSection extends StatelessWidget {
  final String userName;
  final String userType;
  final String selectedMood;
  final void Function(String) onMoodSelected;

  const WelcomeMoodSection({
    super.key,
    required this.userName,
    required this.userType,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.primaryColor, theme.colorScheme.secondary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: theme.primaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userType == 'patient' ? "مرحباً، $userName" : "مرحباً، دكتور $userName",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("كيف تشعر اليوم؟", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMoodButton(Icons.sentiment_very_satisfied, "ممتاز", theme),
              const SizedBox(width: 8),
              _buildMoodButton(Icons.sentiment_satisfied, "جيد", theme),
              const SizedBox(width: 8),
              _buildMoodButton(Icons.sentiment_neutral, "عادي", theme),
              const SizedBox(width: 8),
              _buildMoodButton(Icons.sentiment_dissatisfied, "سيء", theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(IconData icon, String label, ThemeData theme) {
    final isSelected = selectedMood == label;
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => onMoodSelected(label),
        icon: Icon(icon, color: isSelected ? Colors.white : theme.primaryColor),
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : theme.primaryColor, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? theme.primaryColor : theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: isSelected ? null : BorderSide(color: theme.primaryColor),
        ),
      ),
    );
  }
}