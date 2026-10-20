import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ============ الروابط ============
const String kBase = 'https://mithaqps.site.je';
const String kChatUrl = '$kBase/wp-json/fllm/v1/chat';
const String kJsonBase = '$kBase/wp-content/themes/mithaq-theme/inc/seed-json/';

TextStyle amiri({double s = 22, Color c = cPrimary, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.amiri(fontSize: s, color: c, fontWeight: w);
TextStyle cairo({double s = 14, Color c = cText, FontWeight w = FontWeight.w500}) =>
    GoogleFonts.cairo(fontSize: s, color: c, fontWeight: w);

// ============ دالة جلب البيانات ============
Future<dynamic> fetchJson(String url, {bool isPost = false, Map<String, dynamic>? body}) async {
  final client = HttpClient();
  client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
  try {
    HttpClientRequest request;
    if (isPost) {
      request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    } else {
      request = await client.getUrl(Uri.parse(url));
    }
    request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36');
    request.headers.set('Accept', 'application/json');
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
        colorScheme: ColorScheme.fromSeed(seedColor: cPrimary, primary: cPrimary, secondary: cGold),
      ),
      locale: const Locale('ar', 'PS'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox.shrink()),
      home: const MainScreen(),
    );
  }
}

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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await fetchJson('$kBase/wp-json/mithaq/v1/home-data');
      if (mounted) setState(() => loading = false);
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً بك', style: cairo(s: 14, c: cTextSoft)),
                    Text('مِيثَاق', style: amiri(s: 28, c: cPrimary)),
                  ],
                ),
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: cBgAlt,
                  child: FaIcon(FontAwesomeIcons.scaleBalanced, color: cPrimary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Search Bar
            Container(
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
            const SizedBox(height: 25),

            // Daily Question
            Container(
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
                    style: amiri(s: 18, c: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text('اعرف الجواب', style: cairo(s: 12, c: Colors.white, w: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('9', 'قانون'),
                _buildStat('141', 'سؤال'),
                _buildStat('67', 'نموذج'),
                _buildStat('22', 'إجراء'),
              ],
            ),
            const SizedBox(height: 30),

            // Quick Actions
            Text('وصول سريع', style: amiri(s: 20)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildActionCard(Icons.menu_book, 'المكتبة', cPrimary)),
                const SizedBox(width: 15),
                Expanded(child: _buildActionCard(Icons.assignment, 'الاختبارات', cGold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String num, String label) {
    return Column(
      children: [
        Text(num, style: amiri(s: 24, c: cPrimary)),
        Text(label, style: cairo(s: 12, c: cTextSoft)),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: cairo(s: 14, w: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==================== 2. المكتبة ====================
class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});
  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _currentFile = 'laws.json';
  bool loading = true;
  List<dynamic> items = [];

  final List<Map<String, String>> _categories = [
    {'file': 'laws.json', 'title': 'القوانين'},
    {'file': 'questions.json', 'title': 'الأسئلة'},
    {'file': 'court-cases.json', 'title': 'السوابق'},
    {'file': 'templates.json', 'title': 'النماذج'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFile(_currentFile);
  }

  Future<void> _loadFile(String fileName) async {
    setState(() { loading = true; items = []; });
    try {
      final res = await fetchJson('$kJsonBase$fileName');
      if (mounted) {
        setState(() {
          items = res is List ? res : [];
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
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
          // Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _currentFile == cat['file'];
                return GestureDetector(
                  onTap: () {
                    setState(() { _currentFile = cat['file']!; });
                    _loadFile(_currentFile);
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
          const SizedBox(height: 20),

          // List
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: cPrimary))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final title = item['title'] ?? item['question'] ?? item['name'] ?? 'بدون عنوان';
                      final content = item['content'] ?? item['answer'] ?? item['explanation'] ?? item['description'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: cBorder),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          title: Text(title, style: amiri(s: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: content.isNotEmpty 
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(content, style: cairo(s: 12, c: cTextSoft), maxLines: 2, overflow: TextOverflow.ellipsis),
                                )
                              : null,
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: cTextSoft),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(title: title, content: content)));
                          },
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
              style: {
                "body": Style(fontFamily: GoogleFonts.cairo().fontFamily, fontSize: FontSize(15), lineHeight: const LineHeight(1.8), color: cText),
              },
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
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(color: cBgAlt, shape: BoxShape.circle),
              child: const Icon(Icons.assignment, size: 60, color: cPrimary),
            ),
            const SizedBox(height: 20),
            Text('الاختبارات التجريبية', style: amiri(s: 24)),
            const SizedBox(height: 10),
            Text('هنا ستتمكن من خوض اختبارات تفاعلية\nلقياس مستواك القانوني', textAlign: TextAlign.center, style: cairo(s: 14, c: cTextSoft)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('قريباً...', style: cairo(c: Colors.white)), backgroundColor: cPrimary));
              },
              child: Text('ابدأ الاختبار الآن', style: cairo(s: 16, c: Colors.white, w: FontWeight.bold)),
            ),
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
    setState(() {
      messages.add({'text': text, 'isUser': true});
      controller.clear();
      sending = true;
    });
    _scrollToBottom();

    try {
      final res = await fetchJson(kChatUrl, isPost: true, body: {'message': text, 'prompt': text});
      if (mounted) {
        String reply = res['reply']?.toString() ?? res['response']?.toString() ?? res['message']?.toString() ?? 'عذراً، لم أستلم رداً.';
        setState(() {
          messages.add({'text': reply, 'isUser': false});
          sending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add({'text': 'تعذر الاتصال بالخادم.', 'isUser': false});
          sending = false;
        });
      }
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المستشار الذكي', style: amiri(s: 18)),
                    Text('ميثاق AI', style: cairo(s: 12, c: cPrimary)),
                  ],
                ),
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
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isLoggedIn = prefs.getBool('isLoggedIn') ?? false);
  }

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    setState(() => isLoggedIn = true);
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
                Text(isLoggedIn ? 'المحامي المتدرب' : 'زائر', style: amiri(s: 22)),
                const SizedBox(height: 5),
                Text(isLoggedIn ? 'تجربة مجانية (متبقي 30 يوم)' : 'يرجى تسجيل الدخول', style: cairo(s: 14, c: cTextSoft)),
                if (!isLoggedIn) ...[
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: cPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    onPressed: _login,
                    child: Text('تسجيل الدخول', style: cairo(c: Colors.white)),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          _buildTile(Icons.info_outline, 'عن ميثاق', () => _showAboutDialog(context)),
          _buildTile(Icons.developer_mode, 'المطور', () => _showDevDialog(context)),
          // تم حذف شكر وتقدير بناءً على طلبك
          _buildTile(Icons.privacy_tip_outlined, 'إخلاء المسؤولية', () => _showDisclaimerDialog(context)),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('عن ميثاق', style: amiri(s: 20)),
      content: Text('منصة المحامي الفلسطيني — رحلتك تبدأ من هنا. تهدف المنصة إلى تقديم محتوى قانوني وأدوات تفاعلية للمحامي المتدرب.', style: cairo(s: 14)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
    ));
  }

  void _showDevDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('المطور', style: amiri(s: 20)),
      content: Text('صُمم وطُوّر بعناية\nالمحامي أسعد محمد بدوي\n\nللاستفسار: smilestranger2@gmail.com', style: cairo(s: 14), textAlign: TextAlign.center),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
    ));
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('إخلاء المسؤولية', style: amiri(s: 20)),
      content: Text('المنصة لأغراض تعليمية فقط، ولا تعتبر استشارة قانونية. يجب مراجعة النصوص القانونية قبل اتخاذ أي إجراء.', style: cairo(s: 14)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
    ));
  }
}
