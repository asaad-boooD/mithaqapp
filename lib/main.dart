import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MithaqApp());
}

// ============ الألوان ============
const Color cBg = Color(0xFFFAF7F2);
const Color cBgAlt = Color(0xFFF5F0E8);
const Color cPrimary = Color(0xFF557264);
const Color cPrimaryLight = Color(0xFF6B8E7F);
const Color cGold = Color(0xFFC9A961);
const Color cText = Color(0xFF2E3A45);
const Color cTextSoft = Color(0xFF6B7A85);
const Color cBorder = Color(0xFFE8E1D5);
const Color cNavy = Color(0xFF1B2D4F);
const Color cBrown = Color(0xFF765B32);

// ============ الروابط ============
const String kBase = 'https://mithaqps.site.je';
// رابط ملفات الجيت هاب
const String kJsonBase = 'https://raw.githubusercontent.com/asaad-boooD/mithaqdata/main/';

TextStyle amiri({double s = 22, Color c = cPrimary, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.amiri(fontSize: s, color: c, fontWeight: w);
TextStyle cairo({double s = 14, Color c = cText, FontWeight w = FontWeight.w500}) =>
    GoogleFonts.cairo(fontSize: s, color: c, fontWeight: w);

// ============ دالة جلب البيانات (مصححة ومحصنة) ============
Future<dynamic> fetchJson(String url) async {
  final client = HttpClient();
  client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    request.headers.set('Accept', 'application/json, text/plain, */*');
    
    final response = await request.close().timeout(const Duration(seconds: 30));
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('خطأ: ${response.statusCode}');
    }
  } finally {
    client.close();
  }
}

// ==================== التطبيق الأساسي ====================
class MithaqApp extends StatelessWidget {
  const MithaqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ميثاق',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: cBg,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: cPrimary, primary: cPrimary, secondary: cGold),
      ),
      locale: const Locale('ar', 'PS'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox.shrink()),
      home: const MainScreen(),
    );
  }
}

// ==================== الشاشة الرئيسية (Bottom Nav) ====================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const HomeTab(),
    const LibraryTab(),
    const ExamsTab(),
    const UnderConstructionScreen(title: 'المستشار الذكي', icon: Icons.smart_toy),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: cPrimary,
          unselectedItemColor: cTextSoft,
          selectedLabelStyle: cairo(s: 11, c: cPrimary, w: FontWeight.bold),
          unselectedLabelStyle: cairo(s: 11, c: cTextSoft),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'المكتبة'),
            BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'الاختبارات'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'المستشار'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// ==================== شاشة "قيد البناء" ====================
class UnderConstructionScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const UnderConstructionScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(title: Text(title, style: amiri(s: 18)), backgroundColor: cBg, iconTheme: const IconThemeData(color: cPrimary)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(color: cBgAlt, shape: BoxShape.circle),
                child: Icon(icon, size: 60, color: cPrimary),
              ),
              const SizedBox(height: 25),
              Text(title, style: amiri(s: 26)),
              const SizedBox(height: 15),
              Text('هذا القسم قيد البناء وسيتم تفعيله قريباً جداً.\nمتوفر حالياً على منصة ميثاق (الموقع).', 
                textAlign: TextAlign.center, style: cairo(s: 16, c: cTextSoft, w: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 1. الشاشة الرئيسية (تصميم شامل) ====================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — قريباً', style: cairo(c: Colors.white)),
      backgroundColor: cPrimary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً بك،', style: cairo(s: 14, c: cTextSoft)),
                    Text('مِيثَاق', style: amiri(s: 28, c: cPrimary)),
                  ],
                ),
                const CircleAvatar(radius: 24, backgroundColor: cBgAlt, child: FaIcon(FontAwesomeIcons.scaleBalanced, color: cPrimary, size: 20)),
              ],
            ),
          ),

          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: cBorder),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن قانون أو سؤال...',
                hintStyle: cairo(s: 14, c: cTextSoft),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: cTextSoft),
              ),
            ),
          ),

          // Daily Question
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [cPrimary, cPrimaryLight]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: cGold, size: 20),
                    const SizedBox(width: 8),
                    Text('سؤال اليوم', style: cairo(s: 14, c: Colors.white, w: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                Text('ما هو الأثر القانوني لتقديم طلب تجديد الدعوى المشطوبة بعد مرور ستين يوماً؟', 
                  style: amiri(s: 18, c: Colors.white), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => _soon(context, 'الجواب'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('اعرف الجواب', style: cairo(s: 12, c: Colors.white, w: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('9', 'قانون'),
                _buildStat('141', 'سؤال'),
                _buildStat('67', 'نموذج'),
                _buildStat('22', 'إجراء'),
              ],
            ),
          ),

          // Quick Actions (وصول سريع)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('وصول سريع', style: amiri(s: 20)),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _buildQuickAction(context, Icons.menu_book, 'المكتبة', () => _push(context, const LibraryTab()))),
                const SizedBox(width: 15),
                Expanded(child: _buildQuickAction(context, Icons.assignment, 'الاختبارات', () => _push(context, const ExamsTab()))),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // أدوات تفاعلية
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('أدوات تفاعلية', style: amiri(s: 20)),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _buildToolCard(context, FontAwesomeIcons.gavel, 'سوابق قضائية', () => _push(context, const CaseSimulatorScreen()))),
                const SizedBox(width: 10),
                Expanded(child: _buildToolCard(context, FontAwesomeIcons.calculator, 'حاسبة المواعيد', () => _soon(context, 'الحاسبة'))),
                const SizedBox(width: 10),
                Expanded(child: _buildToolCard(context, FontAwesomeIcons.arrowsRotate, 'التحديثات', () => _soon(context, 'التحديثات'))),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // ماذا يقدم ميثاق
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                Text('ماذا يقدم ميثاق؟', style: amiri(s: 22)),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 0.95,
                    children: [
                      _buildFeatureCard(FontAwesomeIcons.bookOpen, 'القوانين', 'قوانين مشروحة', '9 عناصر'),
                      _buildFeatureCard(FontAwesomeIcons.circleQuestion, 'بنك الأسئلة', 'أسئلة النقابة', '141 عنصر'),
                      _buildFeatureCard(FontAwesomeIcons.mosque, 'الأسئلة الشرعية', 'مسائل فقهية', '5 عناصر'),
                      _buildFeatureCard(FontAwesomeIcons.route, 'المسار التدريبي', 'من التأسيس للامتحان', '5 عناصر'),
                      _buildFeatureCard(FontAwesomeIcons.fileLines, 'اللوائح والنماذج', 'مذكرات وعقود', '67 عنصر'),
                      _buildFeatureCard(FontAwesomeIcons.listCheck, 'الإجراءات', 'خطوات كل إجراء', '22 عنصر'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // تصفح حسب القسم
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('تصفح حسب القسم', style: amiri(s: 22)),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.2,
              children: [
                // ✅ تم إصلاح الخطأ هنا بتمرير context للدالة
                _buildBrowseCard(context, FontAwesomeIcons.book, 'الكتب القانونية', () => _push(context, const UnderConstructionScreen(title: 'الكتب القانونية', icon: Icons.menu_book))),
                _buildBrowseCard(context, FontAwesomeIcons.download, 'تحميل القوانين'),
                _buildBrowseCard(context, FontAwesomeIcons.landmark, 'المحاكم'),
                _buildBrowseCard(context, FontAwesomeIcons.magnifyingGlass, 'البحث القانوني'),
                _buildBrowseCard(context, FontAwesomeIcons.bullhorn, 'التحديثات'),
                _buildBrowseCard(context, FontAwesomeIcons.penNib, 'الأسئلة التحريرية'),
                _buildBrowseCard(context, FontAwesomeIcons.microphoneLines, 'الأسئلة الشفوية'),
                _buildBrowseCard(context, FontAwesomeIcons.userGraduate, 'دليل المتدرب'),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // الفوتر (الإهداء والمطور)
          Container(
            color: cBgAlt,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const FaIcon(FontAwesomeIcons.scaleBalanced, size: 30, color: cPrimary),
                const SizedBox(height: 10),
                Text('مِيثَاق', style: amiri(s: 22, c: cPrimary)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cBorder),
                  ),
                  child: Column(
                    children: [
                      Text('إهداء', style: amiri(s: 14, c: cBrown)),
                      const SizedBox(height: 8),
                      Text(
                        '"إلى كل من يجعل خدمة الناس والعدل غايته، ويجعل المعرفة وسيلته إلى إنصافهم."',
                        style: cairo(s: 12, c: const Color(0xFF58645D)).copyWith(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('© 2026 مِيثَاق — جميع الحقوق محفوظة', style: cairo(s: 10, c: cTextSoft, w: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('المنصة لأغراض تعليمية فقط، ولا تعتبر استشارة قانونية.', style: cairo(s: 9, c: cTextSoft), textAlign: TextAlign.center),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String num, String label) {
    return Column(children: [Text(num, style: amiri(s: 24, c: cPrimary)), Text(label, style: cairo(s: 12, c: cTextSoft))]);
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cBorder)),
        child: Column(
          children: [
            Icon(icon, color: cPrimary, size: 30),
            const SizedBox(height: 10),
            Text(title, style: cairo(s: 14, w: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: cBorder)),
        child: Column(
          children: [
            FaIcon(icon, color: cPrimary, size: 24),
            const SizedBox(height: 10),
            Text(title, style: amiri(s: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc, String count) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(15), border: Border.all(color: cBorder)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cPrimary, size: 30),
          const SizedBox(height: 10),
          Text(title, style: amiri(s: 15)),
          const SizedBox(height: 5),
          Text(desc, style: cairo(s: 11, c: cTextSoft), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(count, style: cairo(s: 10, c: cGold, w: FontWeight.bold)),
        ],
      ),
    );
  }

  // ✅ تم إضافة BuildContext هنا
  Widget _buildBrowseCard(BuildContext context, IconData icon, String title, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap ?? () => _soon(context, title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
        child: Row(
          children: [
            FaIcon(icon, color: cGold, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: cairo(s: 12, c: cNavy, w: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}

// ==================== 2. المكتبة (تقرأ من GitHub) ====================
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});
  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _currentFile = 'laws.json';
  bool loading = true;
  List<dynamic> items = [];
  String? errorMsg;

  final List<Map<String, String>> _categories = [
    {'file': 'laws.json', 'title': 'القوانين'},
    {'file': 'questions.json', 'title': 'الأسئلة'},
    {'file': 'procedures.json', 'title': 'الإجراءات'},
    {'file': 'templates.json', 'title': 'النماذج'},
    {'file': 'courts.json', 'title': 'المحاكم'},
    {'file': 'judicial-precedents.json', 'title': 'السوابق'},
    {'file': 'guides.json', 'title': 'دليل المتدرب'},
    {'file': 'research.json', 'title': 'البحث القانوني'},
    {'file': 'oral-exam.json', 'title': 'الشفوي'},
    {'file': 'sharia-questions.json', 'title': 'الشرعية'},
    {'file': 'training.json', 'title': 'المسار التدريبي'},
    {'file': 'updates.json', 'title': 'التحديثات'},
    {'file': 'written-exam.json', 'title': 'التحريري'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { loading = true; items = []; errorMsg = null; });
    try {
      final res = await fetchJson('$kJsonBase$_currentFile');
      
      // التعامل مع الملفات التي تحتوي على كائن بداخله مصفوفة (مثل questions.json)
      if (res is Map && res.containsKey('questions')) {
        items = res['questions'];
      } else if (res is Map && res.containsKey('cases')) {
        items = res['cases'];
      } else if (res is List) {
        items = res;
      } else {
        items = [];
      }
      
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMsg = e.toString().replaceAll('Exception: ', '');
          loading = false;
        });
      }
    }
  }

  String _getTitle(dynamic item) {
    if (item == null) return 'بدون عنوان';
    if (item is String) return item;
    String title = item['title'] ?? item['question'] ?? item['name'] ?? item['law_name'] ?? item['case_name'] ?? 'بدون عنوان';
    return title.toString().replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String _getContent(dynamic item) {
    if (item == null) return '';
    if (item['content'] != null) return item['content'].toString();
    if (item['answer'] != null) return item['answer'].toString();
    if (item['explanation'] != null) return item['explanation'].toString();
    if (item['description'] != null) return item['description'].toString();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('المكتبة القانونية', style: amiri(s: 24)),
          ),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _currentFile == cat['file'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentFile = cat['file']!);
                    _loadData();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? cPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? cPrimary : cBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(cat['title']!, style: cairo(s: 14, c: isSelected ? Colors.white : cText, w: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: cPrimary))
                : errorMsg != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('تعذر التحميل.\n$errorMsg', style: cairo(c: Colors.red), textAlign: TextAlign.center)))
                    : items.isEmpty
                        ? Center(child: Text('لا توجد بيانات حالياً', style: cairo(c: cTextSoft)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final title = _getTitle(item);
                              final content = _getContent(item);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: cBorder)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(15),
                                  title: Text(title, style: amiri(s: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: content.isNotEmpty 
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(content.replaceAll(RegExp(r'<[^>]*>'), ''), style: cairo(s: 12, c: cTextSoft), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        )
                                      : null,
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: cTextSoft),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(title: title, content: content))),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String title;
  final String content;
  const DetailScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('التفاصيل', style: amiri(s: 18)), backgroundColor: cBg, iconTheme: const IconThemeData(color: cPrimary)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: amiri(s: 22, c: cPrimary)),
            const Divider(height: 30),
            Html(
              data: content.isEmpty ? '<p>لا يوجد محتوى</p>' : content,
              style: {"body": Style(fontFamily: GoogleFonts.cairo().fontFamily, fontSize: FontSize(15), lineHeight: const LineHeight(1.8), color: cText)},
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 3. الاختبارات (تفاعلية) ====================
class ExamsTab extends StatefulWidget {
  const ExamsTab({super.key});
  @override
  State<ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends State<ExamsTab> {
  bool loading = true;
  List<dynamic> questions = [];
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  String? selectedOption;
  bool examFinished = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() { loading = true; errorMsg = null; });
    try {
      final res = await fetchJson('${kJsonBase}questions.json');
      if (res is Map && res.containsKey('questions')) {
        questions = res['questions'];
      } else if (res is List) {
        questions = res;
      } else {
        questions = [];
      }
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMsg = e.toString().replaceAll('Exception: ', '');
          loading = false;
        });
      }
    }
  }

  void _checkAnswer(String option) {
    if (answered) return;
    setState(() {
      selectedOption = option;
      answered = true;
      if (option == questions[currentIndex]['correct']) score++;
    });
  }

  void _nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() { currentIndex++; answered = false; selectedOption = null; });
    } else {
      setState(() => examFinished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: cPrimary));
    if (errorMsg != null) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('تعذر تحميل الأسئلة.\n$errorMsg', style: cairo(c: Colors.red), textAlign: TextAlign.center)));
    if (questions.isEmpty) return Center(child: Text('لا توجد أسئلة متاحة حالياً', style: cairo()));

    if (examFinished) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('النتيجة النهائية', style: amiri(s: 24)),
            const SizedBox(height: 20),
            Text('$score / ${questions.length}', style: amiri(s: 40, c: cPrimary)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => setState(() { currentIndex = 0; score = 0; answered = false; examFinished = false; }),
              style: ElevatedButton.styleFrom(backgroundColor: cPrimary),
              child: Text('إعادة الاختبار', style: cairo(c: Colors.white)),
            )
          ],
        ),
      );
    }

    final q = questions[currentIndex];
    final title = q['title'] ?? q['question'] ?? '';
    final correctOpt = q['correct'];
    final explain = q['explanation'] ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('السؤال ${currentIndex + 1} من ${questions.length}', style: cairo(s: 14, c: cTextSoft)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: (currentIndex + 1) / questions.length, backgroundColor: cBgAlt, color: cPrimary),
            const SizedBox(height: 25),
            Text(title, style: amiri(s: 18), maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 25),
            
            // الخيارات
            ...['a', 'b', 'c', 'd'].map((opt) {
              String optText = q['opt_$opt'] ?? '';
              if (optText.isEmpty) return const SizedBox.shrink();
              
              bool isCorrect = opt == correctOpt;
              Color color = Colors.white;
              Color borderColor = cBorder;
              
              if (answered) {
                if (opt == selectedOption) {
                  color = isCorrect ? Colors.green.shade50 : Colors.red.shade50;
                  borderColor = isCorrect ? Colors.green : Colors.red;
                } else if (isCorrect) {
                  color = Colors.green.shade50;
                  borderColor = Colors.green;
                }
              }

              return GestureDetector(
                onTap: () => _checkAnswer(opt),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderColor)),
                  child: Row(children: [
                    CircleAvatar(radius: 15, backgroundColor: cBgAlt, child: Text(opt.toUpperCase(), style: cairo(w: FontWeight.bold))),
                    const SizedBox(width: 15),
                    Expanded(child: Text(optText, style: cairo(s: 14))),
                    if (answered && isCorrect) const Icon(Icons.check_circle, color: Colors.green),
                    if (answered && !isCorrect && opt == selectedOption) const Icon(Icons.cancel, color: Colors.red),
                  ]),
                ),
              );
            }).toList(),

            // الشرح
            if (answered && explain.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: cBgAlt, borderRadius: BorderRadius.circular(15), border: Border.all(color: cBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الشرح:', style: cairo(s: 14, w: FontWeight.bold, c: cPrimary)),
                    const SizedBox(height: 5),
                    Text(explain, style: cairo(s: 13, c: cTextSoft)),
                  ],
                ),
              ),
            ],

            const Spacer(),
            if (answered)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(backgroundColor: cPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: Text(currentIndex < questions.length - 1 ? 'السؤال التالي' : 'عرض النتيجة', style: cairo(c: Colors.white, w: FontWeight.bold)),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// ==================== 4. محاكي القضايا (Court Cases) ====================
class CaseSimulatorScreen extends StatefulWidget {
  const CaseSimulatorScreen({super.key});
  @override
  State<CaseSimulatorScreen> createState() => _CaseSimulatorScreenState();
}

class _CaseSimulatorScreenState extends State<CaseSimulatorScreen> {
  bool loading = true;
  List<dynamic> cases = [];
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      final res = await fetchJson('${kJsonBase}court-cases.json');
      if (res is Map && res.containsKey('cases')) {
        cases = res['cases'];
      } else if (res is List) {
        cases = res;
      } else {
        cases = [];
      }
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMsg = e.toString().replaceAll('Exception: ', '');
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('محاكي القضايا', style: amiri(s: 20)), backgroundColor: cBg, iconTheme: const IconThemeData(color: cPrimary)),
      backgroundColor: cBg,
      body: loading 
        ? const Center(child: CircularProgressIndicator(color: cPrimary))
        : errorMsg != null
          ? Center(child: Text(errorMsg!, style: cairo(c: Colors.red)))
          : cases.isEmpty
            ? Center(child: Text('لا توجد قضايا حالياً', style: cairo(c: cTextSoft)))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final c = cases[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: cBorder)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      title: Text(c['title'] ?? 'قضية بدون عنوان', style: amiri(s: 16)),
                      subtitle: Text('${c['branch']} - صعوبة: ${c['difficulty']}', style: cairo(s: 12, c: cTextSoft)),
                      trailing: const Icon(Icons.play_circle_fill, color: cPrimary, size: 30),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CasePlayScreen(caseData: c))),
                    ),
                  );
                },
              ),
    );
  }
}

class CasePlayScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;
  const CasePlayScreen({super.key, required this.caseData});
  @override
  State<CasePlayScreen> createState() => _CasePlayScreenState();
}

class _CasePlayScreenState extends State<CasePlayScreen> {
  int currentStage = 0;
  int totalScore = 0;
  bool stageAnswered = false;
  String? selectedOptionFeedback;
  bool caseFinished = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.caseData['title'] ?? 'قضية';
    final facts = widget.caseData['facts'] as List<dynamic>? ?? [];
    final stages = widget.caseData['stages'] as List<dynamic>? ?? [];

    if (caseFinished) {
      return Scaffold(
        appBar: AppBar(title: Text('النتيجة النهائية', style: amiri(s: 18)), backgroundColor: cBg, iconTheme: const IconThemeData(color: cPrimary)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.gavel, size: 60, color: cGold),
              const SizedBox(height: 20),
              Text('لقد أكملت المحاكاة', style: amiri(s: 24)),
              const SizedBox(height: 10),
              Text('مجموع نقاطك: $totalScore', style: amiri(s: 30, c: cPrimary)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: cPrimary),
                child: Text('العودة للقضايا', style: cairo(c: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    if (stages.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title, style: amiri(s: 18))),
        body: const Center(child: Text('لا توجد مراحل لهذه القضية')),
      );
    }

    final stage = stages[currentStage];
    final question = stage['question'] ?? '';
    final options = stage['options'] as List<dynamic>? ?? [];
    final category = stage['category'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(title, style: amiri(s: 18)), backgroundColor: cBg, iconTheme: const IconThemeData(color: cPrimary)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الوقائع
            if (currentStage == 0) ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: cBgAlt, borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الوقائع:', style: amiri(s: 16, c: cPrimary)),
                    const SizedBox(height: 10),
                    ...facts.map((f) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Text('• $f', style: cairo(s: 14)))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text('المرحلة ${currentStage + 1}: $category', style: cairo(s: 14, c: cGold, w: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(question, style: amiri(s: 20)),
            const SizedBox(height: 20),

            // الخيارات
            ...options.map((opt) {
              final text = opt['text'] ?? '';
              final feedback = opt['feedback'] ?? '';
              final score = opt['score'] ?? 0;

              return GestureDetector(
                onTap: () {
                  if (stageAnswered) return;
                  setState(() {
                    stageAnswered = true;
                    totalScore += (score is int) ? score : 0;
                    selectedOptionFeedback = feedback;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: cBorder)),
                  child: Text(text, style: cairo(s: 15)),
                ),
              );
            }).toList(),

            // التغذية الراجعة
            if (stageAnswered) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('التحليل:', style: cairo(s: 14, w: FontWeight.bold, c: Colors.blue.shade800)),
                    const SizedBox(height: 5),
                    Text(selectedOptionFeedback ?? '', style: cairo(s: 14)),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (currentStage < stages.length - 1) {
                            setState(() {
                              currentStage++;
                              stageAnswered = false;
                              selectedOptionFeedback = null;
                            });
                          } else {
                            setState(() => caseFinished = true);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: cPrimary),
                        child: Text(currentStage < stages.length - 1 ? 'المرحلة التالية' : 'إنهاء المحاكاة', style: cairo(c: Colors.white)),
                      ),
                    )
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

// ==================== 5. حسابي ====================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(title, style: amiri(s: 20)),
      content: Text(content, style: cairo(s: 14), textAlign: TextAlign.center),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const CircleAvatar(radius: 40, backgroundColor: cBgAlt, child: Icon(Icons.person, size: 40, color: cPrimary)),
                const SizedBox(height: 15),
                Text('المحامي المتدرب', style: amiri(s: 22)),
                const SizedBox(height: 5),
                Text('النسخة التجريبية', style: cairo(s: 14, c: cTextSoft)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: cPrimary),
            title: Text('عن ميثاق', style: cairo(s: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: cTextSoft),
            onTap: () => _showDialog(context, 'عن ميثاق', 'منصة المحامي الفلسطيني — رحلتك تبدأ من هنا.'),
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode, color: cPrimary),
            title: Text('المطور', style: cairo(s: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: cTextSoft),
            onTap: () => _showDialog(context, 'المطور', 'المحامي أسعد محمد بدوي\nsmilestranger2@gmail.com'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: cPrimary),
            title: Text('إخلاء المسؤولية', style: cairo(s: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: cTextSoft),
            onTap: () => _showDialog(context, 'إخلاء المسؤولية', 'المنصة لأغراض تعليمية فقط، ولا تعتبر استشارة قانونية.'),
          ),
        ],
      ),
    );
  }
}
