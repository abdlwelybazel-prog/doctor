# ⚡ دليل البدء السريع - المميزات الجديدة

هذا الدليل يوضح كيفية استخدام جميع الميزات الجديدة بسرعة وسهولة.

---

## 1️⃣ استخدام نظام الصلاحيات (User Role Service)

### التحقق من نوع المستخدم:

```dart
// التحقق من أن المستخدم دكتور
if (await UserRoleService.isDoctor()) {
  // اعرض محتوى للأطباء فقط
}

// التحقق من أن المستخدم مريض
if (await UserRoleService.isPatient()) {
  // اعرض محتوى للمرضى فقط
}
```

### التحقق من الصلاحيات:

```dart
// هل يمكن إضافة أدوية؟
if (await UserRoleService.canAddMedication()) {
  showAddMedicationButton();
}

// هل يمكن وصف أدوية؟
if (await UserRoleService.canPrescribeMedicine()) {
  showPrescribeButton();
}
```

### الحصول على بيانات المستخدم:

```dart
// بيانات كاملة
final userData = await UserRoleService.getUserFullData();
print(userData['fullName']); // اسم المستخدم

// بيانات خاصة بالدكتور
final doctorInfo = await UserRoleService.getDoctorInfo();
print(doctorInfo['specialty']); // التخصص
```

---

## 2️⃣ فتح صفحة الإعدادات

### من أي مكان في التطبيق:

```dart
// الطريقة البسيطة
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SettingsScreen()),
);

// مع animation (Fade)
navigateFade(context, const SettingsScreen());
```

### من Profile Screen:

```dart
// تم إضافة رابط في Profile Screen مباشرة
// اضغط على الإعدادات في القائمة
```

---

## 3️⃣ استخدام Bottom Navigation Bar الجديد

### في الشاشة الرئيسية:

```dart
import 'package:digl/core/widgets/modern_bottom_nav_bar.dart';
import 'package:digl/core/widgets/modern_bottom_nav_bar.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(), // محتوى الصفحة
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavItem(label: 'الرئيسية', icon: Icons.home),
          BottomNavItem(label: 'الأدوية', icon: Icons.medication),
          BottomNavItem(label: 'المواعيد', icon: Icons.calendar_today),
          BottomNavItem(label: 'الملف الشخصي', icon: Icons.person),
          BottomNavItem(label: 'الإعدادات', icon: Icons.settings),
        ],
      ),
    );
  }
}
```

### اختيار نسخة أخرى:

```dart
// النسخة المتقدمة
AdvancedBottomNavBar(...)

// النسخة البسيطة
SimpleBottomNavBar(...)
```

---

## 4️⃣ إضافة Animations للانتقالات

### Fade Transition:

```dart
// الطريقة السريعة
navigateFade(context, NextPage());

// الطريقة الكاملة
Navigator.push(context, FadePageTransition(page: NextPage()));
```

### Slide Transitions:

```dart
// انزلاق من اليمين
navigateSlideRight(context, NextPage());

// انزلاق من اليسار
navigateSlideLeft(context, NextPage());
```

### Scale Transition:

```dart
// تكبير/تصغير
navigateScale(context, NextPage());
```

---

## 5️⃣ استخدام Animated Widgets

### Animated Button:

```dart
AnimatedButton(
  onTap: () {
    print('تم الضغط على الزر');
  },
  child: ElevatedButton(
    onPressed: () {},
    child: const Text('اضغط هنا'),
  ),
)
```

### Fade In Animation:

```dart
FadeInAnimation(
  duration: Duration(milliseconds: 600),
  child: MyWidget(),
)
```

### Pulse Animation:

```dart
PulseAnimation(
  minScale: 0.9,
  maxScale: 1.1,
  child: Icon(Icons.favorite, size: 48),
)
```

### Animated Card:

```dart
AnimatedCard(
  elevation: 4,
  child: Card(
    child: ListTile(
      title: Text('بطاقة مع حركة'),
    ),
  ),
)
```

---

## 6️⃣ تطبيق الصلاحيات في الواجهة

### إخفاء الأزرار للمرضى:

```dart
// في build method
if (canAddMedications)
  FloatingActionButton(
    onPressed: _addMedication,
    child: Icon(Icons.add),
  ),
```

### عرض رسائل مختلفة:

```dart
if (!canAddMedications) {
  return Center(
    child: Text('فقط الأطباء يمكنهم إضافة الأدوية'),
  );
}
```

### منع الوصول للدوال:

```dart
Future<void> _addMedication() async {
  // التحقق من الصلاحية
  if (!await UserRoleService.canAddMedication()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ليس لديك الصلاحية')),
    );
    return;
  }

  // تابع العملية
}
```

---

## 📝 أمثلة سريعة

### مثال 1: شاشة رئيسية محسّنة

```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final isDoc = await UserRoleService.isDoctor();
    setState(() => _isDoctor = isDoc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDoctor ? 'لوحة الدكتور' : 'المريض'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => navigateFade(context, SettingsScreen()),
          ),
        ],
      ),
      body: FadeInAnimation(
        child: Center(
          child: _buildContent(),
        ),
      ),
      bottomNavigationBar: ModernBottomNavBar(...),
    );
  }
}
```

### مثال 2: زر محمي بالصلاحيات

```dart
class AddMedicationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserRoleService.canAddMedication(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return SizedBox.shrink(); // إخفاء الزر
        }

        return AnimatedButton(
          onTap: () => Navigator.push(
            context,
            SlideRightPageTransition(page: AddMedicationScreen()),
          ),
          child: FloatingActionButton(
            onPressed: () {},
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
```

### مثال 3: واجهة متغيرة حسب نوع المستخدم

```dart
class UserSpecificUI extends StatefulWidget {
  @override
  State<UserSpecificUI> createState() => _UserSpecificUIState();
}

class _UserSpecificUIState extends State<UserSpecificUI> {
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    UserRoleService.isDoctor().then((value) {
      setState(() => _isDoctor = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isDoctor ? _buildDoctorUI() : _buildPatientUI(),
    );
  }

  Widget _buildDoctorUI() {
    return Column(
      children: [
        ListTile(title: Text('إضافة دواء')),
        ListTile(title: Text('وصف أدوية')),
        ListTile(title: Text('عرض التقارير')),
      ],
    );
  }

  Widget _buildPatientUI() {
    return Column(
      children: [
        ListTile(title: Text('أدويتي')),
        ListTile(title: Text('مواعيدي')),
        ListTile(title: Text('تقارير صحتي')),
      ],
    );
  }
}
```

---

## 🔧 نصائح الاستخدام

### ✅ أفضل الممارسات:

1. **استخدم await عند التحقق من الصلاحيات:**
   ```dart
   // ✅ صحيح
   final canAdd = await UserRoleService.canAddMedication();
   if (canAdd) { ... }

   // ❌ خطأ
   UserRoleService.canAddMedication().then((canAdd) { ... });
   ```

2. **استخدم const عندما يكون ممكناً:**
   ```dart
   // ✅ أداء أفضل
   const Text('Hello');

   // ❌ إعادة بناء غير ضرورية
   Text('Hello');
   ```

3. **استخدم الـ Animations المناسبة:**
   ```dart
   // للانتقالات البسيطة
   navigateFade(context, page);

   // للانتقالات المهمة
   navigateSlideRight(context, page);
   ```

### ⚠️ أشياء يجب تجنبها:

1. ❌ لا تفحص الصلاحيات بناءً على النص فقط
   ```dart
   // ❌ غير آمن
   if (userRole == 'doctor') { ... }

   // ✅ آمن
   if (await UserRoleService.isDoctor()) { ... }
   ```

2. ❌ لا تترك Animations ثقيلة تحتل الموارد
   ```dart
   // ✅ صحيح - 300ms محسّن
   FadeInAnimation(duration: Duration(milliseconds: 300), ...)

   // ❌ خطأ - بطيء جداً
   FadeInAnimation(duration: Duration(seconds: 5), ...)
   ```

---

## 🐛 حل المشاكل الشائعة

### المشكلة: الأزرار لا تختفي للمرضى

**الحل:**
```dart
// تأكد من أنك استخدمت await
Future<void> _loadPermissions() async {
  final can = await UserRoleService.canAddMedication();
  setState(() => canAddMedications = can);
}
```

### المشكلة: الـ Animations بطيئة

**الحل:**
```dart
// قلل المدة
FadeInAnimation(
  duration: Duration(milliseconds: 300), // بدلاً من 800
  child: widget,
)
```

### المشكلة: رسالة خطأ "User not found"

**الحل:**
```dart
// تأكد من تسجيل المستخدم في Firestore
final userData = await UserRoleService.getUserFullData();
if (userData == null) {
  // أنشئ مستند للمستخدم أولاً
}
```

---

## 📞 احصل على المزيد من المساعدة

للمزيد من التفاصيل، اقرأ:

- 📖 `ENHANCED_FEATURES.md` - توثيق شامل
- 💡 `integration_example.dart` - أمثلة متقدمة
- 📊 `IMPLEMENTATION_SUMMARY.md` - ملخص كامل

---

**استمتع باستخدام الميزات الجديدة! 🚀**
