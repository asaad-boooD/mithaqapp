import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MithaqApp());
}

// ============ الألوان من HTML ============
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
const Color cGoldLight = Color(0xFFD4A574);

// ============ API ============
const String kBase = 'https://mithaqps.site.je';
const String kHomeUrl = '$kBase/wp-json/mithaq/v1/home-data';
const String kChatUrl = '$kBase/wp-json/fllm/v1/chat';
String kListUrl(String type) => '$kBase/wp-json/wp/v2/$type';

// ============ أنماط النصوص ============
TextStyle amiri({double s = 22, Color c = cPrimary, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.amiri(fontSize: s, color: c, fontWeight: w);
TextStyle cairo({double s = 14, Color c = cText, FontWeight w = FontWeight.w500}) =>
    GoogleFonts.cairo(fontSize: s, color: c, fontWeight: w);

// ==================== التطبيق ====================
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: cPrimary,
          primary: cPrimary,
          secondary: cGold,
        ),
      ),
      locale: const Locale('ar', 'PS'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomeScreen(),
    );
  }
}

// ==================== الشاشة الرئيسية ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await http.get(Uri.parse(kHomeUrl)).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (r.statusCode == 200) {
        final j = jsonDecode(utf8.decode(r.bodyBytes));
        setState(() {
          data = j is Map ? Map<String, dynamic>.from(j) : {};
          loading = false;
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => loading = false);
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int _stat(String key, int fallback) {
    if (data == null) return fallback;
    final src = data!['stats'] is Map ? data!['stats'] as Map : data;
    final v = _asInt(src?[key]);
    return v == 0 ? fallback : v;
  }

  String _dailyQ() {
    if (data == null) return 'ما هو الأثر القانوني لتقديم طلب تجديد الدعوى المشطوبة بعد مرور ستين يوماً؟';
    for (final k in ['daily_question', 'today_question', 'question_of_day']) {
      if (data![k] is Map) {
        final t = data![k]['title'];
        if (t is Map && t['rendered'] != null) {
          return t['rendered'].toString().replaceAll(RegExp(r'<[^>]*>'), '').trim();
        }
        if (t is String) return t;
      }
    }
    return 'ما هو الأثر القانوني لتقديم طلب تجديد الدعوى المشطوبة بعد مرور ستين يوماً؟';
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _soon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — قريباً', style: cairo(c: Colors.white)),
      backgroundColor: cPrimary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: cPrimary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _buildHero(),
              _buildDailyAndStats(),
              _buildGuestZone(),
              _buildTools(),
              _buildFeatures(),
              _buildBrowse(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ============ 1. Hero ============
  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cBg, Color(0xFFEFE9DE)],
        ),
      ),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: cBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: cPrimary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('منصة المحامي الفلسطيني',
                    style: cairo(s: 12, c: cPrimary, w: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text('مِيثَاق', style: amiri(s: 60, c: cPrimary)),
          const SizedBox(height: 10),
          Text('رحلتك تبدأ من هنا', style: amiri(s: 20, c: cGoldLight)),
          const SizedBox(height: 8),
          Text('منصة المحامي الفلسطيني', style: cairo(s: 14, c: cTextSoft)),
          const SizedBox(height: 30),
          // Buttons grid
          Row(
            children: [
              Expanded(child: _heroBtn(
                icon: FontAwesomeIcons.arrowLeft,
                text: 'ابدأ رحلتك',
                primary: true,
                onTap: () => _push(const SectionsScreen(intro: true)),
              )),
              const SizedBox(width: 12),
              Expanded(child: _heroBtn(
                icon: FontAwesomeIcons.squareCheck,
                text: 'اختبار تجريبي',
                onTap: () => _push(const NativeListScreen(postType: 'question', title: 'الاختبارات')),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _heroBtn(
                icon: FontAwesomeIcons.robot,
                text: 'المستشار الذكي',
                onTap: () => _push(const ChatScreen()),
              )),
              const SizedBox(width: 12),
              Expanded(child: _heroBtn(
                icon: FontAwesomeIcons.bookOpen,
                text: 'المكتبة',
                onTap: () => _push(const NativeListScreen(postType: 'law', title: 'المكتبة القانونية')),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroBtn({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: primary ? cPrimaryLight : Colors.white,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: primary ? null : Border.all(color: cBorder, width: 1.5),
            boxShadow: primary
                ? [BoxShadow(color: cPrimaryLight.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 16, color: primary ? Colors.white : cPrimary),
              const SizedBox(width: 8),
              Text(text,
                  style: cairo(
                    s: 13,
                    c: primary ? Colors.white : cText,
                    w: FontWeight.w700,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ============ 2. Daily Question + Stats ============
  Widget _buildDailyAndStats() {
    final stats = [
      {'num': _stat('laws', 9), 'label': 'قانون'},
      {'num': _stat('questions', 141), 'label': 'سؤال'},
      {'num': _stat('templates', 67), 'label': 'نموذج'},
      {'num': _stat('procedures', 22), 'label': 'إجراء'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Daily Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cBorder),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0EC),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(FontAwesomeIcons.circleQuestion, size: 12, color: cPrimary),
                      const SizedBox(width: 6),
                      Text('سؤال اليوم',
                          style: cairo(s: 12, c: cPrimary, w: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(_dailyQ(), style: amiri(s: 16)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => _push(const NativeListScreen(
                        postType: 'question', title: 'بنك الأسئلة')),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('اعرف الجواب',
                            style: cairo(s: 13, c: cPrimary, w: FontWeight.w700)),
                        const SizedBox(width: 5),
                        const FaIcon(FontAwesomeIcons.chevronLeft, size: 12, color: cPrimary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cBorder),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
            ),
            child: Row(
              children: [
                Expanded(child: _statItem(stats[0]['num'] as int, stats[0]['label'] as String)),
                _divider(),
                Expanded(child: _statItem(stats[1]['num'] as int, stats[1]['label'] as String)),
                _divider(),
                Expanded(child: _statItem(stats[2]['num'] as int, stats[2]['label'] as String)),
                _divider(),
                Expanded(child: _statItem(stats[3]['num'] as int, stats[3]['label'] as String)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: cBorder);

  Widget _statItem(int num, String label) {
    return Column(
      children: [
        Text('$num', style: amiri(s: 22, c: cPrimary)),
        Text(label, style: cairo(s: 12, c: cTextSoft, w: FontWeight.w600)),
      ],
    );
  }

  // ============ 3. Guest Zone ============
  Widget _buildGuestZone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Login box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F5F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.comments, size: 24, color: cPrimary),
                  ),
                ),
                const SizedBox(height: 15),
                Text('مرحباً بك في ميثاق', style: amiri(s: 22)),
                const SizedBox(height: 8),
                Text('للبدء في محادثة مع المساعد الذكي، يرجى تسجيل الدخول.',
                    textAlign: TextAlign.center,
                    style: cairo(s: 14, c: cTextSoft)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: cPrimary,
                    borderRadius: BorderRadius.circular(50),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => _soon('تسجيل الدخول'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text('تسجيل الدخول الآن',
                              style: cairo(s: 14, c: Colors.white, w: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Court box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cBorder),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المحكمة الصورية', style: amiri(s: 18)),
                      const SizedBox(height: 4),
                      Text('تدرّب على المرافعة واتخاذ القرارات.',
                          style: cairo(s: 12, c: cTextSoft)),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => _soon('المحكمة الصورية'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: cPrimary),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text('ابدأ المحاكاة',
                              style: cairo(s: 12, c: cPrimary, w: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const FaIcon(FontAwesomeIcons.buildingColumns, size: 30, color: cGold),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============ 4. Tools ============
  Widget _buildTools() {
    final tools = [
      {
        'icon': FontAwesomeIcons.gavel,
        'title': 'سوابق قضائية',
        'desc': 'تصفح الأحكام',
        'onTap': () => _push(const NativeListScreen(
            postType: 'precedent', title: 'السوابق القضائية')),
      },
      {
        'icon': FontAwesomeIcons.calculator,
        'title': 'حاسبة المواعيد',
        'desc': 'احسب المدد بدقة',
        'onTap': () => _soon('حاسبة المواعيد'),
      },
      {
        'icon': FontAwesomeIcons.arrowsRotate,
        'title': 'التحديثات',
        'desc': 'تابع التشريعات',
        'onTap': () => _soon('التحديثات'),
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          Text('أدوات تفاعلية',
              style: cairo(s: 12, c: cTextSoft, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('اختبر نفسك', style: amiri(s: 24)),
          const SizedBox(height: 20),
          Row(
            children: tools.map((t) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Material(
                    color: cBg,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: t['onTap'] as VoidCallback,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cBorder),
                        ),
                        child: Column(
                          children: [
                            FaIcon(t['icon'] as IconData, size: 24, color: cPrimary),
                            const SizedBox(height: 10),
                            Text(t['title'] as String, style: amiri(s: 13)),
                            const SizedBox(height: 4),
                            Text(t['desc'] as String,
                                style: cairo(s: 10, c: cTextSoft),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============ 5. Features ============
  Widget _buildFeatures() {
    final features = [
      {'icon': FontAwesomeIcons.bookOpen, 'title': 'القوانين', 'desc': 'قوانين مشروحة', 'count': '9 عناصر',
       'onTap': () => _push(const NativeListScreen(postType: 'law', title: 'القوانين'))},
      {'icon': FontAwesomeIcons.circleQuestion, 'title': 'بنك الأسئلة', 'desc': 'أسئلة النقابة', 'count': '141 عنصر',
       'onTap': () => _push(const NativeListScreen(postType: 'question', title: 'بنك الأسئلة'))},
      {'icon': FontAwesomeIcons.mosque, 'title': 'الأسئلة الشرعية', 'desc': 'مسائل فقهية', 'count': '5 عناصر',
       'onTap': () => _soon('الأسئلة الشرعية')},
      {'icon': FontAwesomeIcons.route, 'title': 'المسار التدريبي', 'desc': 'من التأسيس للامتحان', 'count': '5 عناصر',
       'onTap': () => _soon('المسار التدريبي')},
      {'icon': FontAwesomeIcons.fileLines, 'title': 'اللوائح والنماذج', 'desc': 'مذكرات وعقود', 'count': '67 عنصر',
       'onTap': () => _push(const NativeListScreen(postType: 'article', title: 'اللوائح والنماذج'))},
      {'icon': FontAwesomeIcons.listCheck, 'title': 'الإجراءات', 'desc': 'خطوات كل إجراء', 'count': '22 عنصر',
       'onTap': () => _soon('الإجراءات')},
    ];

    return Container(
      color: cBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          Text('ماذا يقدم ميثاق؟', style: amiri(s: 24)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 0.95,
            children: features.map((f) => _featureCard(f)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(Map<String, dynamic> f) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: f['onTap'] as VoidCallback,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(f['icon'] as IconData, size: 20, color: cPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Text(f['title'] as String, style: amiri(s: 15)),
              const SizedBox(height: 6),
              Text(f['desc'] as String,
                  style: cairo(s: 11, c: cTextSoft),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(f['count'] as String,
                  style: cairo(s: 10, c: cGold, w: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  // ============ 6. Browse ============
  Widget _buildBrowse() {
    final items = [
      {'icon': FontAwesomeIcons.book, 'label': 'الكتب القانونية',
       'onTap': () => _push(const NativeListScreen(postType: 'law', title: 'الكتب القانونية'))},
      {'icon': FontAwesomeIcons.download, 'label': 'تحميل القوانين',
       'onTap': () => _push(const NativeListScreen(postType: 'law', title: 'تحميل القوانين'))},
      {'icon': FontAwesomeIcons.landmark, 'label': 'المحاكم',
       'onTap': () => _soon('المحاكم')},
      {'icon': FontAwesomeIcons.magnifyingGlass, 'label': 'البحث القانوني',
       'onTap': () => _soon('البحث القانوني')},
      {'icon': FontAwesomeIcons.bullhorn, 'label': 'التحديثات',
       'onTap': () => _soon('التحديثات')},
      {'icon': FontAwesomeIcons.penNib, 'label': 'الأسئلة التحريرية',
       'onTap': () => _push(const NativeListScreen(postType: 'question', title: 'الأسئلة التحريرية'))},
      {'icon': FontAwesomeIcons.microphoneLines, 'label': 'الأسئلة الشفوية',
       'onTap': () => _push(const NativeListScreen(postType: 'question', title: 'الأسئلة الشفوية'))},
      {'icon': FontAwesomeIcons.userGraduate, 'label': 'دليل المتدرب',
       'onTap': () => _soon('دليل المتدرب')},
    ];

    return Container(
      color: cBgAlt,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          Text('تصفح حسب القسم', style: amiri(s: 22)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.2,
            children: items.map((it) {
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: it['onTap'] as VoidCallback,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cBorder),
                    ),
                    child: Row(
                      children: [
                        FaIcon(it['icon'] as IconData, size: 16, color: cGold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(it['label'] as String,
                              style: cairo(s: 12, c: cNavy, w: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============ 7. Footer ============
  Widget _buildFooter() {
    return Container(
      color: cBgAlt,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Column(
        children: [
          const FaIcon(FontAwesomeIcons.scaleBalanced, size: 40, color: cPrimary),
          const SizedBox(height: 10),
          Text('مِيثَاق', style: amiri(s: 24, c: cPrimary)),
          const SizedBox(height: 5),
          Text('رحلتك تبدأ من هنا', style: cairo(s: 12, c: cTextSoft)),
          const SizedBox(height: 25),
          // Dedication
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إهداء', style: amiri(s: 14, c: cBrown)),
                const SizedBox(height: 8),
                Text(
                  '"إلى كل من يجعل خدمة الناس والعدل غايته، ويجعل المعرفة وسيلته إلى إنصافهم."',
                  style: cairo(s: 12, c: const Color(0xFF58645D)).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Two columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _footerCol(
                  title: 'شكر وتقدير',
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showThanksDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: cGold),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(FontAwesomeIcons.star, size: 12, color: cGold),
                              const SizedBox(width: 6),
                              Text('عرض القائمة',
                                  style: cairo(s: 12, c: cPrimary, w: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _footerCol(
                  title: 'المصادر القانونية',
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text('صادرة من خلال',
                          style: cairo(s: 11, c: cTextSoft),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text('نقابة المحامين الفلسطينيين',
                          style: cairo(s: 13, c: cNavy, w: FontWeight.w700),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      const FaIcon(FontAwesomeIcons.gem, size: 8, color: cGold),
                      const SizedBox(height: 4),
                      Text('فرع غزة',
                          style: cairo(s: 13, c: cNavy, w: FontWeight.w700),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Dev card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cBorder),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
            ),
            child: Row(
              children: [
                // Social icons (left in RTL)
                Row(
                  children: [
                    _socialBtn(FontAwesomeIcons.whatsapp),
                    const SizedBox(width: 6),
                    _socialBtn(FontAwesomeIcons.envelope),
                    const SizedBox(width: 6),
                    _socialBtn(FontAwesomeIcons.globe),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('صُمّم وطُوّر بعناية',
                          style: cairo(s: 9, c: cTextSoft)),
                      const SizedBox(height: 2),
                      Text('المحامي أسعد محمد بدوي',
                          style: amiri(s: 15, c: cNavy)),
                      const SizedBox(height: 2),
                      Text('المحامي',
                          style: cairo(s: 11, c: cGold, w: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text('© 2026 مِيثَاق — جميع الحقوق محفوظة',
              style: cairo(s: 10, c: cTextSoft, w: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('المنصة لأغراض تعليمية فقط، ولا تعتبر استشارة قانونية.',
              style: cairo(s: 9, c: const Color(0xFF94A3AE)),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _footerCol({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: cBorder)),
            ),
            child: Text(title, style: amiri(s: 14, c: cPrimary), textAlign: TextAlign.center),
          ),
          child,
        ],
      ),
    );
  }

  Widget _socialBtn(IconData icon) {
    return InkWell(
      onTap: () => _soon('التواصل'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: cBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cBorder),
        ),
        child: Center(child: FaIcon(icon, size: 14, color: cPrimary)),
      ),
    );
  }

  // ============ مودال الشكر ============
  void _showThanksDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: cNavy.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: cBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cGold),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: cBorder),
                      ),
                      child: const Center(
                        child: FaIcon(FontAwesomeIcons.xmark, size: 12, color: cPrimary),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text('شكر وتقدير',
                        style: amiri(s: 20, c: cPrimary),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 30),
                ],
              ),
              const SizedBox(height: 20),
              _thanksItem(
                role: 'المراجعة القانونية وتوفير المصادر',
                name: 'الأستاذ المحامي يوسف جمال فرحات',
              ),
              const SizedBox(height: 10),
              _thanksItem(
                role: 'مساهمة في توفير المصادر',
                name: 'المحامي محمد خالد الغنام',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thanksItem({required String role, required String name}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cBorder),
      ),
      child: Column(
        children: [
          Text(role, style: cairo(s: 10, c: cTextSoft), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(name, style: amiri(s: 15, c: cNavy), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ==================== شاشة الأقسام ====================
class SectionsScreen extends StatelessWidget {
  final bool intro;
  const SectionsScreen({super.key, this.intro = false});

  static const List<Map<String, dynamic>> sections = [
    {'type': 'law', 'title': 'القوانين', 'desc': 'التشريعات والقوانين الفلسطينية',
     'icon': FontAwesomeIcons.bookOpen},
    {'type': 'question', 'title': 'الأسئلة القانونية', 'desc': 'أسئلة وأجوبة قانونية شاملة',
     'icon': FontAwesomeIcons.circleQuestion},
    {'type': 'precedent', 'title': 'السوابق القضائية', 'desc': 'أحكام وقرارات قضائية سابقة',
     'icon': FontAwesomeIcons.scaleBalanced},
    {'type': 'article', 'title': 'المقالات', 'desc': 'مقالات ودراسات قانونية',
     'icon': FontAwesomeIcons.fileLines},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        title: Text(intro ? 'ابدأ رحلتك' : 'تصفح الأقسام', style: amiri(s: 20)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: cPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (intro)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cBgAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cGold.withOpacity(0.3)),
              ),
              child: Text(
                'مرحباً بك في ميثاق، منصة المحامي الفلسطيني. اختر القسم الذي ترغب باستكشافه لتبدأ رحلتك القانونية.',
                style: cairo(s: 14),
              ),
            ),
          ...sections.map((s) => _sectionCard(context, s)),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => NativeListScreen(postType: s['type'], title: s['title']),
          )),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FaIcon(s['icon'] as IconData, color: cPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['title'] as String, style: amiri(s: 16)),
                      const SizedBox(height: 2),
                      Text(s['desc'] as String, style: cairo(s: 12, c: cTextSoft)),
                    ],
                  ),
                ),
                const FaIcon(FontAwesomeIcons.chevronLeft, color: cTextSoft, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== شاشة القوائم ====================
class NativeListScreen extends StatefulWidget {
  final String postType;
  final String title;
  const NativeListScreen({super.key, required this.postType, required this.title});
  @override
  State<NativeListScreen> createState() => _NativeListScreenState();
}

class _NativeListScreenState extends State<NativeListScreen> {
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final url = '${kListUrl(widget.postType)}?per_page=50&_fields=id,title,excerpt,content,date,link';
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (r.statusCode == 200) {
        final j = jsonDecode(utf8.decode(r.bodyBytes));
        setState(() {
          items = j is List ? j : [];
          loading = false;
        });
      } else {
        setState(() { error = 'خطأ ${r.statusCode}'; loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { error = 'تعذر تحميل البيانات'; loading = false; });
    }
  }

  String _plain(dynamic v) {
    if (v == null) return '';
    String s;
    if (v is Map && v['rendered'] != null) {
      s = v['rendered'].toString();
    } else {
      s = v.toString();
    }
    return s
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&#8211;', '-')
        .replaceAll('&#8217;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        title: Text(widget.title, style: amiri(s: 20)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: cPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: cPrimary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) return const Center(child: CircularProgressIndicator(color: cPrimary));
    if (error != null) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(children: [
              const FaIcon(FontAwesomeIcons.cloud, size: 56, color: cTextSoft),
              const SizedBox(height: 12),
              Text(error!, style: cairo(s: 14, c: cTextSoft)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cPrimary,
                  foregroundColor: Colors.white,
                ),
              ),
            ]),
          ),
        ],
      );
    }
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(children: [
              const FaIcon(FontAwesomeIcons.inbox, size: 56, color: cTextSoft),
              const SizedBox(height: 12),
              Text('لا توجد عناصر بعد', style: cairo(s: 14, c: cTextSoft)),
            ]),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final title = _plain(item['title']);
        final excerpt = _plain(item['excerpt']);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => NativeDetailScreen(
                  title: title.isEmpty ? 'بدون عنوان' : title,
                  html: (item['content'] is Map ? item['content']['rendered'] : item['content']) ?? '',
                ),
              )),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${i + 1}',
                            style: cairo(s: 11, c: cGold, w: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title.isEmpty ? 'بدون عنوان' : title,
                          style: amiri(s: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(excerpt,
                          style: cairo(s: 12, c: cTextSoft),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('اقرأ المزيد',
                            style: cairo(s: 12, c: cPrimary, w: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const FaIcon(FontAwesomeIcons.arrowLeft, color: cPrimary, size: 12),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==================== شاشة التفاصيل ====================
class NativeDetailScreen extends StatelessWidget {
  final String title;
  final String html;
  const NativeDetailScreen({super.key, required this.title, required this.html});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        title: Text('التفاصيل', style: amiri(s: 20)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: cPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [cPrimary, cPrimaryLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(title, style: amiri(s: 20, c: Colors.white)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cBorder),
              ),
              child: Html(
                data: html.isEmpty ? '<p>لا يوجد محتوى</p>' : html,
                style: {
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(15),
                    color: cText,
                    lineHeight: const LineHeight(1.8),
                    fontFamily: GoogleFonts.cairo().fontFamily,
                  ),
                  'p': Style(margin: Margins.only(bottom: 10)),
                  'h1': Style(fontFamily: GoogleFonts.amiri().fontFamily, color: cPrimary),
                  'h2': Style(fontFamily: GoogleFonts.amiri().fontFamily, color: cPrimary),
                  'h3': Style(fontFamily: GoogleFonts.amiri().fontFamily, color: cPrimary),
                  'a': Style(color: cGold, textDecoration: TextDecoration.underline),
                  'li': Style(margin: Margins.only(bottom: 6)),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== شاشة الشات ====================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_ChatMsg> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool sending = false;

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    setState(() {
      messages.add(_ChatMsg(text: text, isUser: true));
      controller.clear();
      sending = true;
    });
    _scrollToBottom();

    try {
      final r = await http.post(
        Uri.parse(kChatUrl),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'message': text, 'prompt': text}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      String reply;
      if (r.statusCode == 200) {
        final j = jsonDecode(utf8.decode(r.bodyBytes));
        reply = j['reply']?.toString()
            ?? j['response']?.toString()
            ?? j['message']?.toString()
            ?? j['answer']?.toString()
            ?? j['content']?.toString()
            ?? 'عذراً، لم أستلم رداً من الخادم.';
      } else {
        reply = 'حدث خطأ (${r.statusCode})، حاول لاحقاً.';
      }
      setState(() {
        messages.add(_ChatMsg(text: reply, isUser: false));
        sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add(const _ChatMsg(
            text: 'تعذر الاتصال بالخادم، تحقق من الإنترنت.', isUser: false));
        sending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: cPrimary),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: cPrimary, shape: BoxShape.circle),
              child: const FaIcon(FontAwesomeIcons.robot, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Text('المستشار الذكي', style: amiri(s: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == messages.length) return _typingIndicator();
                      return _ChatBubble(msg: messages[i]);
                    },
                  ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F5F2),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(FontAwesomeIcons.comments, color: cPrimary, size: 36),
            ),
            const SizedBox(height: 20),
            Text('مرحباً بك في المستشار الذكي',
                style: amiri(s: 20),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('اسألني أي سؤال قانوني وسأساعدك بأفضل ما لدي',
                style: cairo(s: 13, c: cTextSoft),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: cPrimary),
          ),
          const SizedBox(width: 8),
          Text('يكتب...', style: cairo(s: 12, c: cTextSoft)),
        ]),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: cBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: cairo(s: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب سؤالك هنا...',
                  hintStyle: cairo(s: 13, c: cTextSoft),
                  filled: true,
                  fillColor: cBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sending ? null : _send,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: sending ? cTextSoft : cPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isUser;
  const _ChatMsg({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: msg.isUser ? cPrimary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 4 : 16),
            bottomRight: Radius.circular(msg.isUser ? 16 : 4),
          ),
          border: msg.isUser ? null : Border.all(color: cBorder),
        ),
        child: Text(
          msg.text,
          style: cairo(s: 14, c: msg.isUser ? Colors.white : cText),
        ),
      ),
    );
  }
}
