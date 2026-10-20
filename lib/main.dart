import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  runApp(MithaqApp(initialLoggedIn: isLoggedIn));
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

// ============ الروابط ============
const String kBase = 'https://mithaqps.site.je';
const String kChatUrl = '$kBase/wp-json/fllm/v1/chat';
const String kHomeUrl = '$kBase/wp-json/mithaq/v1/home-data';
const String kLoginUrl = '$kBase/wp-json/mithaq/v1/login';
const String kTrialUrl = '$kBase/wp-json/mithaq/v1/trial';
const String kJsonBase = '$kBase/wp-content/themes/mithaq-theme/inc/seed-json/';

TextStyle amiri({double s = 22, Color c = cPrimary, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.amiri(fontSize: s, color: c, fontWeight: w);
TextStyle cairo({double s = 14, Color c = cText, FontWeight w = FontWeight.w500}) =>
    GoogleFonts.cairo(fontSize: s, color: c, fontWeight: w);

// ============ دالة جلب البيانات (مصححة) ============
Future<dynamic> fetchJson(String url, {bool isPost = false, Map<String, dynamic>? body}) async {
  final client = HttpClient();
  client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
  try {
    HttpClientRequest request;
    if (isPost) {
      request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36');
      request.headers.set('Accept', 'application/json');
      request.write(jsonEncode(body));
    } else {
      request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36');
      request.headers.set('Accept', 'application/json');
    }
    
    final response = await request.close().timeout(const Duration(seconds: 30));
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      try {
        final err = jsonDecode(responseBody);
        throw Exception(err['message'] ?? 'خطأ: ${response.statusCode}');
      } catch (_) {
        throw Exception('خطأ: ${response.statusCode}');
      }
    }
  } finally {
    client.close();
  }
}

// ==================== التطبيق الأساسي ====================
class MithaqApp extends StatelessWidget {
  final bool initialLoggedIn;
  const MithaqApp({super.key, required this.initialLoggedIn});

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
      home: initialLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}

// ==================== شاشة تسجيل الدخول ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool isLoading = false;
  bool isTrialLoading = false;
  String? errorMsg;

  Future<void> _login() async {
    final user = _userController.text.trim();
    final pass = _passController.text.trim();
    if (user.isEmpty || pass.isEmpty) {
      setState(() => errorMsg = 'يرجى إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() { isLoading = true; errorMsg = null; });

    try {
      final res = await fetchJson(kLoginUrl, isPost: true, body: {
        'username': user,
        'password': pass,
      });

      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', res['name'] ?? user);
        await prefs.setInt('userId', res['user_id'] ?? 0);
        
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
        }
      } else {
        setState(() => errorMsg = 'اسم المستخدم أو كلمة المرور غير صحيحة');
      }
    } catch (e) {
      setState(() => errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _startTrial() async {
    setState(() { isTrialLoading = true; errorMsg = null; });
    try {
      final res = await fetchJson(kTrialUrl, isPost: true, body: {});
      
      if (res['success'] == true) {
        _userController.text = res['username'];
        _passController.text = res['password'];
        await _login();
      } else {
        setState(() => errorMsg = 'تعذر تفعيل التجربة المجانية');
      }
    } catch (e) {
      setState(() => errorMsg = 'تعذر الاتصال بالخادم');
    } finally {
      if (mounted) setState(() => isTrialLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const FaIcon(FontAwesomeIcons.scaleBalanced, size: 80, color: cPrimary),
              const SizedBox(height: 20),
              Text('مِيثَاق', style: amiri(s: 40)),
              const SizedBox(height: 10),
              Text('منصة المحامي الفلسطيني', style: cairo(s: 16, c: cTextSoft)),
              const SizedBox(height: 40),
              
              if (errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                  child: Text(errorMsg!, style: cairo(s: 14, c: Colors.red), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 20),
              ],

              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم',
                  labelStyle: cairo(s: 14, c: cTextSoft),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person, color: cPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: cBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: cBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: cPrimary)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: cairo(s: 14, c: cTextSoft),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock, color: cPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: cBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: cBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: cPrimary)),
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: isLoading ? null : _login,
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('دخول', style: cairo(s: 16, c: Colors.white, w: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              
              Row(
                children: [
                  const Expanded(child: Divider(color: cBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text('أو', style: cairo(s: 14, c: cTextSoft)),
                  ),
                  const Expanded(child: Divider(color: cBorder)),
                ],
              ),
              
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cGold, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: isTrialLoading ? null : _startTrial,
                  child: isTrialLoading
                    ? const CircularProgressIndicator(color: cGold)
                    : Text('⭐ ابدأ تجربة محدودة — 30 يوم', style: cairo(s: 16, c: cPrimary, w: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
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
    const ChatTab(),
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

// ==================== 1. الشاشة الرئيسية ====================
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? homeData;
  String userName = 'المحامي';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userName = prefs.getString('userName') ?? 'المحامي');
    try {
      final res = await fetchJson(kHomeUrl);
      if (mounted) setState(() => homeData = res is Map ? Map<String, dynamic>.from(res) : {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: cPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً بك،', style: cairo(s: 14, c: cTextSoft)),
                    Text(userName, style: amiri(s: 24, c: cPrimary)),
                  ],
                ),
                const CircleAvatar(radius: 24, backgroundColor: cBgAlt, child: FaIcon(FontAwesomeIcons.scaleBalanced, color: cPrimary, size: 20)),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [cPrimary, cPrimaryLight]), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.lightbulb, color: cGold, size: 20),
                    const SizedBox(width: 8),
                    Text('سؤال اليوم', style: cairo(s: 14, c: Colors.white, w: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 15),
                  Text(
                    homeData?['daily_question']?['title']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? 'ما هو الأثر القانوني لتقديم طلب تجديد الدعوى المشطوبة بعد مرور ستين يوماً؟', 
                    style: amiri(s: 18, c: Colors.white), maxLines: 3, overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat(homeData?['stats']?['laws']?.toString() ?? '9', 'قانون'),
                _buildStat(homeData?['stats']?['questions']?.toString() ?? '141', 'سؤال'),
                _buildStat(homeData?['stats']?['templates']?.toString() ?? '67', 'نموذج'),
                _buildStat(homeData?['stats']?['procedures']?.toString() ?? '22', 'إجراء'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String num, String label) {
    return Column(children: [Text(num, style: amiri(s: 24, c: cPrimary)), Text(label, style: cairo(s: 12, c: cTextSoft))]);
  }
}

// ==================== 2. المكتبة ====================
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});
  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _currentType = 'laws.json';
  bool loading = true;
  List<dynamic> items = [];

  final List<Map<String, String>> _categories = [
    {'type': 'laws.json', 'title': 'القوانين'},
    {'type': 'questions.json', 'title': 'الأسئلة'},
    {'type': 'books', 'title': 'الكتب القانونية'},
    {'type': 'procedures.json', 'title': 'الإجراءات'},
    {'type': 'templates.json', 'title': 'النماذج'},
    {'type': 'courts.json', 'title': 'المحاكم'},
    {'type': 'court-cases.json', 'title': 'السوابق'},
    {'type': 'guides.json', 'title': 'دليل المتدرب'},
    {'type': 'research.json', 'title': 'البحث القانوني'},
    {'type': 'oral-exam.json', 'title': 'الشفوي'},
    {'type': 'sharia-questions.json', 'title': 'الشرعية'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { loading = true; items = []; });
    try {
      if (_currentType == 'books') {
        final res = await fetchJson('$kBase/wp-json/wp/v2/legal_book?per_page=50');
        if (mounted) {
          setState(() {
            items = res is List ? res : [];
            loading = false;
          });
        }
      } else {
        final res = await fetchJson('$kJsonBase$_currentType');
        if (mounted) {
          setState(() {
            items = res is List ? res : [];
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  String _getTitle(dynamic item) {
    if (item == null) return 'بدون عنوان';
    if (item is String) return item;
    String title = item['title']?['rendered'] ?? item['title'] ?? item['question'] ?? item['name'] ?? 'بدون عنوان';
    return title.toString().replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String _getContent(dynamic item) {
    if (item == null) return '';
    String content = item['content']?['rendered'] ?? item['content'] ?? item['answer'] ?? item['explanation'] ?? item['description'] ?? '';
    return content.toString();
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
                final isSelected = _currentType == cat['type'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentType = cat['type']!);
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
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(title: title, content: content, isBook: _currentType == 'books'))),
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
  final bool isBook;
  const DetailScreen({super.key, required this.title, required this.content, this.isBook = false});

  @override
  Widget build(BuildContext context) {
    String? pdfUrl;
    if (isBook) {
      final regex = RegExp(r'href="([^"]+\.pdf)"');
      final match = regex.firstMatch(content);
      if (match != null) pdfUrl = match.group(1);
    }

    return Scaffold(
      appBar: AppBar(title: Text('التفاصيل', style: amiri(s: 18)), backgroundColor: cBg, iconTheme: const IconThemeData(color: cPrimary)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: amiri(s: 22, c: cPrimary)),
            const Divider(height: 30),
            if (pdfUrl != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: cPrimary, padding: const EdgeInsets.all(15)),
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: Text('تحميل أو قراءة الكتاب (PDF)', style: cairo(s: 16, c: Colors.white)),
                  onPressed: () => launchUrl(Uri.parse(pdfUrl!)),
                ),
              ),
              const SizedBox(height: 20),
            ],
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

// ==================== 3. الاختبارات ====================
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

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() => loading = true);
    try {
      final res = await fetchJson('${kJsonBase}questions.json');
      if (mounted) {
        setState(() {
          questions = res is List ? res : [];
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _checkAnswer(String option) {
    if (answered) return;
    setState(() {
      selectedOption = option;
      answered = true;
      if (option == 'أ') score++;
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('السؤال ${currentIndex + 1} من ${questions.length}', style: cairo(s: 14, c: cTextSoft)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: (currentIndex + 1) / questions.length, backgroundColor: cBgAlt, color: cPrimary),
            const SizedBox(height: 30),
            Text(title, style: amiri(s: 20)),
            const SizedBox(height: 30),
            ...['أ', 'ب', 'ج', 'د'].map((opt) {
              bool isCorrect = opt == 'أ';
              Color color = Colors.white;
              if (answered) {
                if (opt == selectedOption) color = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
                if (isCorrect) color = Colors.green.shade100;
              }
              return GestureDetector(
                onTap: () => _checkAnswer(opt),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), border: Border.all(color: answered && opt == selectedOption ? cPrimary : cBorder)),
                  child: Row(children: [
                    CircleAvatar(radius: 15, backgroundColor: cBgAlt, child: Text(opt, style: cairo(w: FontWeight.bold))),
                    const SizedBox(width: 15),
                    Text('الخيار $opt (نص تجريبي)', style: cairo(s: 16)),
                  ]),
                ),
              );
            }).toList(),
            const Spacer(),
            if (answered)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(backgroundColor: cPrimary),
                  child: Text('السؤال التالي', style: cairo(c: Colors.white)),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// ==================== 4. المستشار الذكي ====================
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});
  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool sending = false;

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    setState(() { messages.add({'text': text, 'isUser': true}); controller.clear(); sending = true; });
    _scrollToBottom();

    try {
      final res = await fetchJson(kChatUrl, isPost: true, body: {'message': text, 'prompt': text});
      if (mounted) {
        String reply = res['reply']?.toString() ?? res['response']?.toString() ?? res['message']?.toString() ?? 'عذراً، لم أستلم رداً.';
        setState(() { messages.add({'text': reply, 'isUser': false}); sending = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { messages.add({'text': 'تعذر الاتصال بالخادم. تأكد من صلاحية الإنترنت.', 'isUser': false}); sending = false; });
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: cPrimary, child: Icon(Icons.smart_toy, color: Colors.white, size: 20)),
                const SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('المستشار الذكي', style: amiri(s: 18)),
                  Text('ميثاق AI', style: cairo(s: 12, c: cPrimary)),
                ]),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(child: Text('مرحباً بك، كيف يمكنني مساعدتك قانونياً؟', style: cairo(s: 16, c: cTextSoft)))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(15),
                    itemCount: messages.length + (sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.all(10), child: Text('يكتب...', style: cairo(s: 12, c: cTextSoft))));
                      }
                      final msg = messages[index];
                      final isUser = msg['isUser'];
                      return Align(
                        alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser ? cPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(15).copyWith(bottomLeft: Radius.circular(isUser ? 0 : 15), bottomRight: Radius.circular(isUser ? 15 : 0)),
                            border: isUser ? null : Border.all(color: cBorder),
                          ),
                          child: Text(msg['text'], style: cairo(s: 14, c: isUser ? Colors.white : cText)),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'اكتب سؤالك...',
                      hintStyle: cairo(s: 14, c: cTextSoft),
                      filled: true,
                      fillColor: cBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: sending ? cTextSoft : cPrimary,
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 5. حسابي ====================
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String userName = 'المحامي المتدرب';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userName = prefs.getString('userName') ?? 'المحامي المتدرب');
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
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
                Text(userName, style: amiri(s: 22)),
                const SizedBox(height: 5),
                Text('عضو مسجل', style: cairo(s: 14, c: cTextSoft)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          _buildTile(Icons.info_outline, 'عن ميثاق', () => _showDialog(context, 'عن ميثاق', 'منصة المحامي الفلسطيني — رحلتك تبدأ من هنا.')),
          _buildTile(Icons.developer_mode, 'المطور', () => _showDialog(context, 'المطور', 'المحامي أسعد محمد بدوي\nsmilestranger2@gmail.com')),
          _buildTile(Icons.privacy_tip_outlined, 'إخلاء المسؤولية', () => _showDialog(context, 'إخلاء المسؤولية', 'المنصة لأغراض تعليمية فقط، ولا تعتبر استشارة قانونية.')),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text('تسجيل الخروج', style: cairo(s: 16, c: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: cPrimary),
      title: Text(title, style: cairo(s: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: cTextSoft),
      onTap: onTap,
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(title, style: amiri(s: 20)),
      content: Text(content, style: cairo(s: 14), textAlign: TextAlign.center),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
    ));
  }
}
