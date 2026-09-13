// مهم جداً لفك تشفير بيانات الـ JSON القادمة من الذكاء الاصطناعي
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // حزمة Gemini الرسمية
//import 'package:http/http.dart' as http;
// حزمة الـ http للاتصال المستقر بالخوادم
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_gg/Services/notification_service.dart';
import 'secret.dart';

//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService().initNotification();

  runApp(const DogHealthApp());
}

// ==========================================
// 1. App Design System (نظام الألوان والأحجام الموحد)
// ==========================================
class AppTheme {
  static const Color primary = Color(0xFF9C27B0); // البنفسجي الموحد
  static const Color textWhite = Colors.white;
  static const Color textBlack = Colors.black87;

  // الشفافية والزجاج
  static final Color glassBackground = Colors.white.withValues(alpha: 0.15);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.3);
  static final Color glassDarkBackground = Colors.black.withValues(alpha: 0.35);

  // الأحجام الموحدة تماماً عبر كل الصفحات
  static const double padding = 24.0;
  static const double titleSize = 28.0;
  static const double borderRadius = 20.0;
  static const double buttonHeight = 60.0;
}

// ==========================================
// 2. Shared Widgets (المكونات المشتركة)
// ==========================================

// --- الزر الزجاجي الموحد ---
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final Color? color;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = double.infinity,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Container(
            width: width,
            height: AppTheme.buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color ?? AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppTheme.glassBorder, width: 1.5),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const GlassOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppTheme.glassBorder, width: 1.3),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: AppTheme.textWhite, size: 30),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textWhite.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textWhite,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  final String message;
  const LoadingScreen({super.key, this.message = 'جاري التحميل...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E24AA), Color(0xFF512DA8), Color(0xFF1976D2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserSessionService {
  static const String _nameKey = 'saved_user_name';
  static const String _emailKey = 'saved_user_email';
  static const String _passwordKey = 'saved_user_password';

  Future<void> saveUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_emailKey, email.trim().toLowerCase());
    await prefs.setString(_passwordKey, password);
  }

  Future<Map<String, String>> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey) ?? '',
      'email': prefs.getString(_emailKey) ?? '',
      'password': prefs.getString(_passwordKey) ?? '',
    };
  }

  Future<bool> login({required String email, required String password}) async {
    final user = await loadUser();
    final storedEmail = user['email']?.toLowerCase() ?? '';
    final storedPassword = user['password'] ?? '';
    return storedEmail.isNotEmpty &&
        storedEmail == email.trim().toLowerCase() &&
        storedPassword == password;
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }
}

// ==========================================
// Chat Screen (تم ربطها بـ Gemini والـ JSON Mode)
// ==========================================
// ==========================================
// AI Vet Chat - Real Gemini Chat
// ==========================================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];

  late final GenerativeModel _model;
  late final ChatSession _chat;

  bool _isLoading = false;

  // حط الـ API Key الجديد بتاعك هنا
  static const String _apiKey = AppSecrets.geminiApiKey;

  @override
  void initState() {
    super.initState();

    _model = GenerativeModel(
      model: 'gemini-3.6-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('''
أنت PetWhiz AI Vet، مساعد بيطري ذكي متخصص في الحيوانات الأليفة
وخاصة الكلاب والقطط.

مهمتك هي التحدث مع صاحب الحيوان في محادثة طبيعية، وفهم حالة الحيوان
من خلال الأسئلة والإجابات المتتالية.

قواعد مهمة:

- تحدث دائماً باللغة العربية.
- لا تقدم تشخيصاً مؤكداً.
- استخدم المعلومات التي يعطيها المستخدم في المحادثة السابقة.
- إذا كانت المعلومات غير كافية، اسأل أسئلة توضيحية قبل إعطاء رأي.
- اسأل عن عمر الحيوان، نوعه، الأعراض، مدة الأعراض، شدة الحالة،
  الأكل والشرب، القيء أو الإسهال، درجة الحرارة إن كانت معروفة،
  والأدوية المستخدمة عند الحاجة.
- إذا ظهرت علامات خطيرة، أخبر المستخدم بوضوح أنه يجب التوجه للطبيب
  البيطري أو الطوارئ في أسرع وقت.
- لا تصف أدوية أو جرعات خطيرة بدون ضرورة.
- لا تدّعي أنك طبيب بيطري حقيقي.
- كن واضحاً وودوداً ومختصراً قدر الإمكان.
- لا تستخدم JSON.
- لا تستخدم Markdown بشكل مبالغ فيه.
- تعامل مع المحادثة كأنها Chat حقيقية وليست تقرير تشخيص واحد.
'''),
    );

    _chat = _model.startChat(
      history: [
        Content.text(
          'ابدأ المحادثة بتحية قصيرة واطلب من المستخدم أن يخبرك '
          'باسم الحيوان ونوعه وما الذي يحدث معه.',
        ),
      ],
    );

    // رسالة البداية للمستخدم
    _messages.add({
      'text':
          'أهلاً 👋 أنا PetWhiz AI Vet 🐾\n\n'
          'أنا هنا أساعدك تفهم حالة حيوانك الأليف. '
          'قولي اسم الحيوان ونوعه وإيه اللي مضايقه؟',
      'isUser': false,
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});

      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));

      final reply = response.text?.trim();

      if (reply == null || reply.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      if (!mounted) return;

      setState(() {
        _messages.add({'text': reply, 'isUser': false});

        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Gemini Chat Error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حصل خطأ في الاتصال بالمساعد البيطري.\n$e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _newChat() {
    setState(() {
      _messages.clear();

      _messages.add({
        'text':
            'أهلاً من جديد 👋🐾\n\n'
            'ابدأ معايا وقولي اسم الحيوان ونوعه وإيه المشكلة اللي عنده.',
        'isUser': false,
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final bool isUser = message['isUser'] as bool;
    final String text = message['text'] as String;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primary.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.48),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 20),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textWhite,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'جاري الكتابة...',
              style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // الخلفية
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1651833826115-7530e72ce504?q=80&w=927&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(color: Colors.black.withValues(alpha: 0.38)),

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textWhite,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),

                      const Expanded(
                        child: Center(
                          child: Text(
                            'PetWhiz AI Vet 🐾',
                            style: TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        tooltip: 'محادثة جديدة',
                        icon: const Icon(
                          Icons.refresh,
                          color: AppTheme.textWhite,
                          size: 26,
                        ),
                        onPressed: _isLoading ? null : _newChat,
                      ),
                    ],
                  ),
                ),

                // Chat
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 15, bottom: 10),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        return _buildMessage(_messages[index]);
                      }

                      return _buildTypingIndicator();
                    },
                  ),
                ),

                // Input
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !_isLoading,
                          minLines: 1,
                          maxLines: 5,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 16,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالتك...',
                            hintStyle: TextStyle(
                              color: AppTheme.textWhite.withValues(alpha: 0.55),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.5),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppTheme.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.grey : AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isLoading ? null : _sendMessage,
                          icon: const Icon(
                            Icons.send_rounded,
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ),
                    ],
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

// ==========================================
// شاشة عرض النتائج واللقاحات المستقلة (Result Screen)
// ==========================================
class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // استخراج وتوزيع قيم الـ JSON مع نصوص بديلة للحماية من الأخطاء
    final String diseaseName = data['disease_name'] ?? 'تشخيص غير محدد';
    final String details =
        data['details'] ?? 'لا تتوفر تفاصيل إضافية حول هذه الأعراض.';
    final List<dynamic> vaccines = data['vaccines'] ?? [];

    return Scaffold(
      body: Stack(
        children: [
          // خلفية متناسقة وموحدة مع طابع التطبيق الزجاجي
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1651833826115-7530e72ce504?q=80&w=927&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          SafeArea(
            child: Column(
              children: [
                const CustomTopBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.padding),
                    child: Directionality(
                      textDirection: TextDirection
                          .rtl, // لتنسيق عرض التقرير الطبي العربي بشكل سليم
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تقرير التشخيص واللقاحات 📋',
                            style: TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 1. بطاقة عرض اسم المرض (زجاج داكن لحمل طابع التحذير)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassDarkBackground,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadius,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.glassBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.healing_outlined,
                                      color: Colors.amberAccent,
                                      size: 36,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'المرض أو الإصابة المتوقعة:',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            diseaseName,
                                            style: const TextStyle(
                                              color: AppTheme.textWhite,
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 2. حاوية تفاصيل ومعلومات المرض
                          const Text(
                            '📝 تفاصيل التقرير الطبي والأعراض:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            flex: 2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.glassBackground,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius,
                                    ),
                                    border: Border.all(
                                      color: AppTheme.glassBorder,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      details,
                                      style: const TextStyle(
                                        color: AppTheme.textWhite,
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 3. قائمة اللقاحات والأدوية المطلوبة للحالة
                          const Text(
                            '💉 اللقاحات والإجراءات الطبية المطلوبة:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            flex: 3,
                            child: vaccines.isEmpty
                                ? const Center(
                                    child: Text(
                                      'لا توجد لقاحات مسجلة أو أدوية إسعافية مطلوبة لهذه الحالة.',
                                      style: TextStyle(
                                        color: AppTheme.textWhite,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: vaccines.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 5,
                                              sigmaY: 5,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppTheme.glassBackground,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: AppTheme.glassBorder,
                                                ),
                                              ),
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor: AppTheme
                                                      .primary
                                                      .withValues(alpha: 0.6),
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(
                                                      color: AppTheme.textWhite,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                title: Text(
                                                  vaccines[index].toString(),
                                                  style: const TextStyle(
                                                    color: AppTheme.textWhite,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
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

// --- حقل الإدخال الزجاجي الموحد ---
class GlassTextField extends StatefulWidget {
  final String hint;
  final bool isPassword;
  final IconData? icon;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool readOnly;

  const GlassTextField({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.icon,
    this.onTap,
    this.controller,
    this.readOnly = false,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final bool obscureText = widget.isPassword && !_showPassword;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: TextField(
          controller: widget.controller,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          obscureText: obscureText,
          style: const TextStyle(color: AppTheme.textWhite, fontSize: 16),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppTheme.textWhite.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: AppTheme.glassBackground,
            suffixIcon: widget.isPassword
                ? IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textWhite.withValues(alpha: 0.75),
                    ),
                  )
                : widget.icon != null
                ? Icon(widget.icon, color: AppTheme.textWhite)
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              borderSide: BorderSide(color: AppTheme.glassBorder, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              borderSide: BorderSide(color: AppTheme.textWhite, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// --- شريط التنقل العلوي الموحد هندسياً لكل الصفحات ---
class CustomTopBar extends StatelessWidget {
  final List<Widget>? actions;
  const CustomTopBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.textWhite,
              size: 26,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          if (actions != null)
            Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ],
      ),
    );
  }
}

// ==========================================
// 3. Main App
// ==========================================
class DogHealthApp extends StatelessWidget {
  const DogHealthApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dog Health App',
      home: const AuthGate(),
      // مسارات مسمّاة لتسهيل التنقل عبر التطبيق
      routes: {'/chat': (context) => const ChatScreen()},
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen(message: 'جاري التحقق من الحساب...');
        }

        if (snapshot.hasData) {
          return const MenuScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}

// ==========================================
// 4. Welcome Screen
// ==========================================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1544568100-847a948585b9?q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.3)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    'Welcome To',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: AppTheme.titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    ' Animal Health',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: AppTheme.titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 200),
                  GlassButton(
                    text: 'Login',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassButton(
                    text: 'Sign Up',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  GlassButton(
                    text: 'About us',
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. Login Screen
// ==========================================
// ==========================================
// 5. Login Screen
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<String> _savedEmails = [];

  @override
  void initState() {
    super.initState();
    _loadSavedEmails();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // تحميل الإيميلات المحفوظة
  Future<void> _loadSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();

    final emails = prefs.getStringList('saved_emails') ?? [];

    if (!mounted) return;

    setState(() {
      _savedEmails = emails;
    });
  }

  // حفظ الإيميل بعد تسجيل الدخول بنجاح
  Future<void> _saveLoginData(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    final emails = prefs.getStringList('saved_emails') ?? [];

    final normalizedEmail = email.trim().toLowerCase();

    emails.remove(normalizedEmail);
    emails.insert(0, normalizedEmail);

    if (emails.length > 5) {
      emails.removeRange(5, emails.length);
    }

    await prefs.setStringList('saved_emails', emails);

    // حفظ الباسورد بشكل آمن
    await _secureStorage.write(
      key: 'password_$normalizedEmail',
      value: password,
    );

    if (!mounted) return;

    setState(() {
      _savedEmails = emails;
    });
  }

  // إظهار الإيميلات المحفوظة
  void _showSavedEmails() {
    FocusScope.of(context).unfocus();

    if (_savedEmails.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('مفيش إيميلات محفوظة لسه')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.glassDarkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose an account',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                ..._savedEmails.map(
                  (email) => ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      email,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 16,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                    onTap: () async {
                      _emailController.text = email;

                      final savedPassword = await _secureStorage.read(
                        key: 'password_$email',
                      );

                      if (savedPassword != null) {
                        _passwordController.text = savedPassword;
                      }

                      if (!context.mounted) return;

                      Navigator.pop(context);
                    },
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور'),
        ),
      );
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // حفظ الإيميل فقط
      await _saveLoginData(email, password);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تسجيل الدخول بنجاح ✅')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'حدث خطأ أثناء تسجيل الدخول')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1544568100-847a948585b9?q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(color: Colors.black.withValues(alpha: 0.53)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.padding,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomTopBar(),

                  const SizedBox(height: 30),

                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.glassDarkBackground,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius + 10,
                      ),
                      border: Border.all(
                        color: AppTheme.glassBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.flash_on,
                                    color: AppTheme.primary,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fast Access',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // Email
                        Row(
                          children: [
                            Expanded(
                              child: GlassTextField(
                                hint: 'Email',
                                icon: Icons.email_outlined,
                                controller: _emailController,
                              ),
                            ),

                            const SizedBox(width: 8),

                            IconButton(
                              onPressed: _showSavedEmails,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip: 'Choose account',
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Password
                        GlassTextField(
                          hint: 'Password',
                          isPassword: true,
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                        ),

                        const SizedBox(height: 16),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textWhite.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            child: const Text('Forgot Password?'),
                          ),
                        ),

                        const SizedBox(height: 12),

                        GlassButton(
                          text: 'Sign In',
                          color: AppTheme.primary.withValues(alpha: 0.85),
                          onPressed: _signIn,
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 16,
                          ),
                        ),

                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. Sign Up Screen
// ==========================================
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isChecked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول')));
      return;
    }

    if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى الموافقة على الشروط أولاً')),
      );
      return;
    }
    try {
      // إنشاء الحساب في Firebase Authentication
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('لم يتم إنشاء المستخدم');
      }

      // حفظ اسم المستخدم في Firebase Authentication
      await user.updateDisplayName(name);

      // حفظ بيانات المستخدم في Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء الحساب بنجاح ✅')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حصل خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1544568100-847a948585b9?q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.55)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.padding,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTopBar(
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications,
                          color: AppTheme.textWhite,
                        ),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                            initialDate: DateTime.now(),
                          );

                          if (date == null) return;
                          if (!context.mounted) return;

                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );

                          if (time == null) return;

                          final selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );

                          NotificationService().scheduleNotification(
                            selectedDateTime,
                            "Reminder 🐶",
                            "ميعاد الريمندر بتاعك",
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.glassDarkBackground,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius + 10,
                      ),
                      border: Border.all(
                        color: AppTheme.glassBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.34),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal details',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlassTextField(
                          hint: 'Full Name',
                          icon: Icons.person_outline,
                          controller: _nameController,
                        ),
                        const SizedBox(height: 16),
                        GlassTextField(
                          hint: 'Email',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 16),
                        GlassTextField(
                          hint: 'Password',
                          isPassword: true,
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isChecked,
                              activeColor: AppTheme.primary,
                              checkColor: AppTheme.textWhite,
                              side: const BorderSide(
                                color: AppTheme.textWhite,
                                width: 1.5,
                              ),
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the Terms and Conditions and privacy policy',
                                style: TextStyle(
                                  color: AppTheme.textWhite.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GlassButton(
                          text: 'Create Account',
                          color: AppTheme.primary.withValues(alpha: 0.9),
                          onPressed: _createAccount,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Account Screen - Firebase
// ==========================================
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول');
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      return doc.data() ?? {};
    }

    // لو بيانات Firestore مش موجودة، نستخدم بيانات Firebase Auth
    return {'name': user.displayName ?? 'مستخدم', 'email': user.email ?? ''};
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1544568100-847a948585b9?q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(color: Colors.black.withValues(alpha: 0.45)),

          SafeArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.textWhite),
                  );
                }

                final data = snapshot.data ?? {};

                final String name =
                    data['name']?.toString() ??
                    FirebaseAuth.instance.currentUser?.displayName ??
                    'مستخدم';

                final String email =
                    data['email']?.toString() ??
                    FirebaseAuth.instance.currentUser?.email ??
                    '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTopBar(),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),

                            const Text(
                              'الحساب',
                              style: TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Profile Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.glassDarkBackground,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadius + 8,
                                ),
                                border: Border.all(
                                  color: AppTheme.glassBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Profile Image
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundColor: AppTheme.primary
                                        .withValues(alpha: 0.8),
                                    child: const Icon(
                                      Icons.person,
                                      size: 48,
                                      color: AppTheme.textWhite,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Name
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppTheme.textWhite,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Email
                                  Text(
                                    email,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.textWhite.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Account Information
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.verified_user_outlined,
                                              color: AppTheme.primary,
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text(
                                                'Firebase Account',
                                                style: TextStyle(
                                                  color: AppTheme.textWhite,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.greenAccent,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // Logout
                                  GlassButton(
                                    text: 'تسجيل الخروج',
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.85,
                                    ),
                                    onPressed: () => _logout(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 7. Menu Screen
// ==========================================
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1544568100-847a948585b9?q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTopBar(
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_active,
                        color: AppTheme.textWhite,
                        size: 30,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReminderScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.person_outline,
                        color: AppTheme.textWhite,
                        size: 30,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.padding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 55),
                      const Text(
                        'Hello, Pet Lover! 👋',
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How can we help your furry friend today?',
                        style: TextStyle(
                          color: AppTheme.textWhite.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.padding,
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                      children: [
                        _buildDashboardCard(
                          context,
                          title: 'AI Vet Chat',
                          icon: Icons.smart_toy,
                          color: AppTheme.primary,
                          onTap: () => Navigator.pushNamed(context, '/chat'),
                        ),
                        _buildDashboardCard(
                          context,
                          title: 'Health Info',
                          icon: Icons.pets,
                          onTap: () => _navigateWithLoading(
                            context,
                            const DogInfoScreen(),
                          ),
                        ),
                        _buildDashboardCard(
                          context,
                          title: 'Find Clinic',
                          icon: Icons.local_hospital,
                          onTap: () => _navigateWithLoading(
                            context,
                            const ChooseCityScreen(),
                          ),
                        ),
                        _buildDashboardCard(
                          context,
                          title: 'Vaccines',
                          icon: Icons.vaccines,
                          onTap: () => _navigateWithLoading(
                            context,
                            const DiseasesVaccinesScreen(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateWithLoading(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color:
                  color?.withValues(alpha: 0.25) ??
                  AppTheme.glassDarkBackground,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: color?.withValues(alpha: 0.5) ?? AppTheme.glassBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        color?.withValues(alpha: 0.2) ??
                        Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 8. Reminder Screen
// ==========================================
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  DateTime _fullSelectedDate = DateTime.now();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // ✅ مهم علشان ميبقاش فيه memory leak
  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fullSelectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _fullSelectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _fullSelectedDate.hour,
          _fullSelectedDate.minute,
        );

        _dateController.text = "${picked.year}/${picked.month}/${picked.day}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fullSelectedDate),
    );

    if (picked != null) {
      setState(() {
        _fullSelectedDate = DateTime(
          _fullSelectedDate.year,
          _fullSelectedDate.month,
          _fullSelectedDate.day,
          picked.hour,
          picked.minute,
        );

        final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final period = picked.period == DayPeriod.am ? "AM" : "PM";

        _timeController.text =
            "$hour:${picked.minute.toString().padLeft(2, '0')} $period";
      });
    }
  }

  Future<void> _showReminderDialog() async {
    // ✅ تأكد إن المستخدم اختار التاريخ والوقت
    if (_dateController.text.isEmpty || _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Enter Date And Time❗")),
      );
      return;
    }

    try {
      // ✅ 1. جدولة النوتيفيكيشن
      await NotificationService().scheduleNotification(
        _fullSelectedDate,
        "Pet vaccination reminder 💉",
        "It's time for the vaccination you scheduled",
      );

      // ✅ 2. حفظ في فايربيز
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .add({
            'date': _fullSelectedDate.toIso8601String(),
            'petType': 'dog',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // ✅ 3. رسالة نجاح
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('The reminder has been saved ✅'),
          content: Text(
            '📅 ${_dateController.text}\n⏰ ${_timeController.text}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                // ✅ تنظيف الحقول بعد النجاح
                _dateController.clear();
                _timeController.clear();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Eror ❌"),
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1602979677071-1781b7f40023',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(color: Colors.black.withValues(alpha: 0.4)),

          SafeArea(
            child: Column(
              children: [
                const CustomTopBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.padding,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 200),

                        GlassTextField(
                          hint: _dateController.text.isEmpty
                              ? 'Select Date'
                              : _dateController.text,
                          icon: Icons.calendar_today,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),

                        const SizedBox(height: 20),

                        GlassTextField(
                          hint: _timeController.text.isEmpty
                              ? 'Select Time'
                              : _timeController.text,
                          icon: Icons.access_time,
                          readOnly: true,
                          onTap: () => _selectTime(context),
                        ),

                        const SizedBox(height: 40),

                        GlassButton(
                          text: 'Set Reminder',
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          onPressed: _showReminderDialog,
                        ),
                      ],
                    ),
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

// ==========================================
// 9. Dog Information Screen
// ==========================================
class DogInfoScreen extends StatefulWidget {
  const DogInfoScreen({super.key});
  @override
  State<DogInfoScreen> createState() => _DogInfoScreenState();
}

class _DogInfoScreenState extends State<DogInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  int? _selectedAgeIndex;
  String? _selectedPetType;

  final List<String> _ageRanges = [
    "1 - 6 months",
    "6 - 12 months",
    "1 - 3 years",
    "Over 3 years",
  ];

  final List<String> _dogSymptoms = [
    "Weight loss",
    "Ear secretion",
    "Malnutrition",
    "Diarrhea by blood",
    "Bad smell",
    "Vomiting",
    "Skin irritation",
    "Limping",
  ];

  final List<String> _catSymptoms = [
    "Loss of appetite",
    "Sneezing",
    "Hairball",
    "Lethargy",
    "Vomiting",
    "Eye discharge",
    "Urinary issues",
    "Itchy skin",
  ];

  final Map<String, bool> _selectedSymptoms = {};
  bool _isLoading = false;
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDataToFirebase() async {
    // 1. نتأكد إنك كتبت الاسم واخترت النوع والسن
    if (_selectedPetType == null ||
        _nameController.text.isEmpty ||
        _selectedAgeIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك اختار الحيوان واكتب الاسم والسن أولاً!'),
        ),
      );
      return;
    }

    // 2. نشغل علامة التحميل
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final userId = user.uid;
      final ageText = _ageRanges[_selectedAgeIndex!];

      final List<String> activeSymptoms = _selectedSymptoms.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('pets')
          .add({
            'petType': _selectedPetType,
            'petName': _nameController.text.trim(),
            'ageRange': ageText,
            'symptoms': activeSymptoms,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 5. رسالة النجاح
      // 5. إظهار الرسالة المنبثقة بتاعتك
      if (mounted) {
        _showConfirmation();
      }
    } catch (e) {
      debugPrint("حصل خطأ: $e");
    } finally {
      // 6. نوقف التحميل
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectPetType(String type) {
    if (_selectedPetType != type) {
      setState(() {
        _selectedPetType = type;
        _selectedAgeIndex = null;
        _selectedSymptoms.clear();
      });
    }
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      _selectedSymptoms[symptom] = !(_selectedSymptoms[symptom] ?? false);
    });
  }

  void _showConfirmation() {
    final petName = _nameController.text.trim().isEmpty
        ? 'Your pet'
        : _nameController.text.trim();
    final petType = _selectedPetType ?? 'pet';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: const Text(
          "تم حفظ البيانات",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: Text(
          "$petName ($petType) information saved successfully!",
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 1. قفل رسالة التأكيد
              Navigator.pop(context);

              // 2. الانتقال إلى شاشة الأمراض واللقاحات
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiseasesVaccinesScreen(),
                ),
              );
            },
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }

  List<String> get _currentSymptoms {
    if (_selectedPetType == 'Dog') return _dogSymptoms;
    if (_selectedPetType == 'Cat') return _catSymptoms;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1728661631084-5f44797184e3?q=80&w=2069&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.55)),
          SafeArea(
            child: Column(
              children: [
                const CustomTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.padding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Animal Information',
                            style: TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: AppTheme.titleSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Select Pet Type',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: buildTypeOption(
                                title: 'Dog',
                                selected: _selectedPetType == 'Dog',
                                onTap: () => _selectPetType('Dog'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: buildTypeOption(
                                title: 'Cat',
                                selected: _selectedPetType == 'Cat',
                                onTap: () => _selectPetType('Cat'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GlassTextField(
                          hint: 'Animal Name',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Age Range',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.glassDarkBackground,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            border: Border.all(
                              color: AppTheme.glassBorder,
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedAgeIndex == null
                                  ? null
                                  : _ageRanges[_selectedAgeIndex!],
                              hint: const Text(
                                'Select age range',
                                style: TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 16,
                                ),
                              ),
                              items: _ageRanges.map((range) {
                                return DropdownMenuItem<String>(
                                  value: range,
                                  child: Text(
                                    range,
                                    style: const TextStyle(
                                      color: AppTheme.textWhite,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAgeIndex = value == null
                                      ? null
                                      : _ageRanges.indexOf(value);
                                });
                              },
                              dropdownColor: AppTheme.glassDarkBackground,
                              isExpanded: true,
                              iconEnabledColor: AppTheme.textWhite,
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Select conditions',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.glassDarkBackground,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: _selectedPetType == null
                              ? const Text(
                                  'Please choose Dog or Cat first to show the specific conditions.',
                                  style: TextStyle(
                                    color: AppTheme.textWhite,
                                    fontSize: 16,
                                  ),
                                )
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _currentSymptoms.map((symptom) {
                                    final selected =
                                        _selectedSymptoms[symptom] ?? false;
                                    return GestureDetector(
                                      onTap: () => _toggleSymptom(symptom),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppTheme.primary
                                              : Colors.white.withValues(
                                                  alpha: 0.08,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.borderRadius,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? AppTheme.primary
                                                : AppTheme.glassBorder,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Text(
                                          symptom,
                                          style: TextStyle(
                                            color: selected
                                                ? AppTheme.textWhite
                                                : AppTheme.textWhite.withValues(
                                                    alpha: 0.95,
                                                  ),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 30),
                        GlassButton(
                          text: 'Confirm Information',
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          onPressed: () {
                            if (!_isLoading) {
                              _saveDataToFirebase();
                            }
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTypeOption({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final imageUrl = title == 'Dog'
        ? 'https://images.unsplash.com/photo-1517423440428-a5a00ad493e8?auto=format&fit=crop&w=500&q=80'
        : 'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?auto=format&fit=crop&w=500&q=80';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.glassBorder,
            width: 1.5,
          ),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.25),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTheme.borderRadius),
                    bottomRight: Radius.circular(AppTheme.borderRadius),
                  ),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 10. Choose City Screen
// ==========================================
// ==========================================
// 10. Choose City Screen
// ==========================================
class ChooseCityScreen extends StatelessWidget {
  const ChooseCityScreen({super.key});

  // المدن والمناطق
  final Map<String, List<String>> cityData = const {
    "Cairo": ["Nasr City", "Maadi", "Zamalek", "New Cairo"],
    "Giza": ["Dokki", "6th of October", "Haram", "Sheikh Zayed"],
    "Minya": ["Minya City", "Mallawi", "Maghagha"],
    "Alexandria": ["Smouha", "Sidi Gaber", "Montaza"],
    "Menoufia": ["Shebin El Kom", "Sadat City"],
    "Matrouh": ["Marsa Matrouh", "Siwa"],
  };

  // فتح Google Maps والبحث عن المكان الحقيقي
  Future<void> _searchGoogleMaps(
    BuildContext context,
    String cityName,
    String areaName,
    String service,
  ) async {
    try {
      final String searchQuery = '$service in $areaName, $cityName, Egypt';

      final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(searchQuery)}',
      );

      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح Google Maps')),
        );
      }
    } catch (e) {
      debugPrint('Google Maps Error: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء فتح Google Maps')),
      );
    }
  }

  // اختيار نوع المكان
  void _showServiceChooser(
    BuildContext context,
    String cityName,
    String areaName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.glassDarkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What are you looking for?',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$areaName, $cityName',
                  style: TextStyle(
                    color: AppTheme.textWhite.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 24),

                // Veterinary Clinics
                _buildServiceOption(
                  context,
                  icon: Icons.local_hospital,
                  title: 'Veterinary Clinics',
                  subtitle: 'Find veterinary clinics near this area',
                  onTap: () {
                    Navigator.pop(context);

                    _searchGoogleMaps(
                      context,
                      cityName,
                      areaName,
                      'Veterinary clinics',
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Vaccination Centers
                _buildServiceOption(
                  context,
                  icon: Icons.vaccines,
                  title: 'Vaccination Centers',
                  subtitle: 'Find pet vaccination centers near this area',
                  onTap: () {
                    Navigator.pop(context);

                    _searchGoogleMaps(
                      context,
                      cityName,
                      areaName,
                      'Pet vaccination centers',
                    );
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // تصميم اختيار نوع الخدمة
  Widget _buildServiceOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppTheme.glassBorder, width: 1.3),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppTheme.textWhite, size: 28),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textWhite.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textWhite,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> cities = cityData.keys.toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(color: Colors.black.withValues(alpha: 0.4)),

          SafeArea(
            child: Column(
              children: [
                const CustomTopBar(),

                const SizedBox(height: 20),

                const Text(
                  'Choose City',
                  style: TextStyle(
                    fontSize: AppTheme.titleSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Select your city and area',
                  style: TextStyle(
                    color: AppTheme.textWhite.withValues(alpha: 0.75),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.padding,
                    ),
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final String cityName = cities[index];
                      final List<String> areas = cityData[cityName] ?? [];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              color: Colors.black.withValues(alpha: 0.90),
                              elevation: 12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadius + 5,
                                ),
                                side: BorderSide(
                                  color: AppTheme.glassBorder,
                                  width: 1.3,
                                ),
                              ),
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            offset: const Offset(0, 68),

                            constraints: BoxConstraints(
                              minWidth:
                                  MediaQuery.of(context).size.width -
                                  (AppTheme.padding * 2),
                              maxWidth:
                                  MediaQuery.of(context).size.width -
                                  (AppTheme.padding * 2),
                            ),

                            onSelected: (String selectedArea) {
                              _showServiceChooser(
                                context,
                                cityName,
                                selectedArea,
                              );
                            },

                            itemBuilder: (context) {
                              final List<PopupMenuEntry<String>> menuItems = [];

                              for (int i = 0; i < areas.length; i++) {
                                menuItems.add(
                                  PopupMenuItem<String>(
                                    value: areas[i],
                                    height: 58,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: AppTheme.primary,
                                            size: 21,
                                          ),

                                          const SizedBox(width: 12),

                                          Expanded(
                                            child: Text(
                                              areas[i],
                                              style: const TextStyle(
                                                color: AppTheme.textWhite,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),

                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: AppTheme.textWhite
                                                .withValues(alpha: 0.35),
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                                if (i < areas.length - 1) {
                                  menuItems.add(
                                    const PopupMenuDivider(height: 1),
                                  );
                                }
                              }

                              return menuItems;
                            },

                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                              child: Container(
                                height: AppTheme.buttonHeight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassDarkBackground,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadius,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.glassBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_city,
                                      color: AppTheme.primary,
                                      size: 25,
                                    ),

                                    const SizedBox(width: 15),

                                    Text(
                                      cityName,
                                      style: const TextStyle(
                                        color: AppTheme.textWhite,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    const Spacer(),

                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppTheme.textWhite.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

// ==========================================
// 11. Diseases & Vaccines Screen
// ==========================================
class DiseasesVaccinesScreen extends StatelessWidget {
  const DiseasesVaccinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1534361960057-19889db9621e?q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.5)),
          SafeArea(
            child: Column(
              children: [
                const CustomTopBar(), // البار العلوي الموحد
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.padding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Health Guide',
                            style: TextStyle(
                              fontSize: AppTheme.titleSize,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textWhite,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Diseases',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        buildGlassCard(
                          title: 'Worm infection',
                          contents: [
                            'Stomach bloating',
                            'Malnutrition',
                            'Hair loss',
                          ],
                        ),
                        const SizedBox(height: 16),
                        buildGlassCard(
                          title: 'Ear infection',
                          contents: ['Bad smell', 'Ear secretion', 'Swelling'],
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Vaccinations',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        buildGlassCard(
                          title: 'Seven-cell Vaccination',
                          isVaccine: true,
                        ),
                        const SizedBox(height: 16),
                        buildGlassCard(
                          title: 'Eight-cell Vaccination',
                          isVaccine: true,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGlassCard({
    required String title,
    List<String>? contents,
    bool isVaccine = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.glassDarkBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          if (isVaccine)
            const Text(
              '45th Day',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            ...(contents ?? []).map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: AppTheme.primary, size: 8),
                    const SizedBox(width: 8),
                    Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
