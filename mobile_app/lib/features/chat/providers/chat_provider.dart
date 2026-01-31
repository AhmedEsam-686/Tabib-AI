// lib/features/chat/providers/chat_provider.dart


import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../../../core/grpc/grpc_connection.dart';
import '../../../core/services/chat_service.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  final IChatService _chatService;

  // القائمة التي تعرض في الشاشة
  final List<ChatMessage> _messages = [];

  // حالة التحميل (لإظهار مؤشر loading إذا احتجنا، رغم أن التدفق يغني عنه)
  bool _isLoading = false;

  ChatProvider({required IChatService chatService})
      : _chatService = chatService {
    // رسالة ترحيبية
    _messages.add(
      ChatMessage.assistant(
        "أهلاً بك 🩺. أنا مساعدك الطبي الذكي. كيف يمكنني مساعدتك اليوم؟",
      ),
    );
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  /// دالة لتهيئة الاتصال بالسيرفر (يتم استدعاؤها من الواجهة عند البدء)
  void connectToServer() {
    // استبدل العنوان والمنفذ بالقيم التي يعطيها لك Ngrok
    // مثال: Host: 0.tcp.ngrok.io, Port: 15678
    try {
      // يمكنك وضع قيم افتراضية أو تمريرها كباراميترات
      GrpcConnection().initConnection(
        host: '10.0.2.2', // <--- ضع هوست نجروك هنا
        port: 50052,            // <--- ضع بورت نجروك هنا
      );
      notifyListeners();
    } catch (e) {
      developer.log('Connection Error', error: e);
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // 1. إضافة رسالة المستخدم
    final userMsg = ChatMessage.user(content);
    _messages.add(userMsg);

    // 2. إضافة رسالة "فارغة" للبوت فوراً (PlaceHolder)
    // هذا يضمن ظهور فقاعة الرد فوراً وتبدأ بالامتلاء
    _messages.add(ChatMessage.assistant("", thinkingContent: null));

    _isLoading = true;
    notifyListeners();

    final parser = _ThinkingStreamParser();

    try {
      // إرسال التاريخ السابق (بدون الرسالة الفارغة الأخيرة)
      final history = _messages.sublist(0, _messages.length - 1);

      // بدء الاستماع للتدفق
      final stream = _chatService.sendMessage(content, history);

      await for (final token in stream) {
        parser.addChunk(token);
        final parsed = parser.result();

        _messages.last = _messages.last.copyWith(
          content: parsed.content,
          thinkingContent:
              parsed.thinking.isNotEmpty ? parsed.thinking : null,
          isThinking: parsed.isThinking,
        );

        // تنبيه الواجهة لتحديث الشاشة حرفاً بحرف
        notifyListeners();
      }

      // إنهاء أي بقايا من وسم التفكير ومعالجة الحالات الشاذة
      parser.finalize();
      final parsed = parser.result();

      String finalThinking = parsed.thinking;
      String finalContent = parsed.content;

      // إذا لم تظهر أي وسوم تفكير نهائياً، اعتبر النص كله ردّاً نهائياً
      if (!parsed.sawAnyTag) {
        finalContent = '$finalThinking$finalContent';
        finalThinking = '';
      }

      _messages.last = _messages.last.copyWith(
        content: finalContent.trim(),
        thinkingContent:
            finalThinking.trim().isNotEmpty ? finalThinking.trim() : null,
        isThinking: false,
      );

    } catch (e) {
      // في حال الخطأ، نحدث الرسالة الأخيرة لتظهر الخطأ
      _messages.last = _messages.last.copyWith(
        content: "عذراً، حدث خطأ أثناء الاتصال: $e",
      );
      developer.log('Provider Error', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _messages.add(
      ChatMessage.assistant(
        "أهلاً بك 🩺. أنا مساعدك الطبي الذكي. كيف يمكنني مساعدتك اليوم؟",
      ),
    );
    notifyListeners();
  }
}

class _StreamParseResult {
  final String thinking;
  final String content;
  final bool isThinking;
  final bool sawAnyTag;

  const _StreamParseResult({
    required this.thinking,
    required this.content,
    required this.isThinking,
    required this.sawAnyTag,
  });
}

class _ThinkingStreamParser {
  static const String _openTag = '<think>';
  static const String _closeTag = '</think>';

  final StringBuffer _thinking = StringBuffer();
  final StringBuffer _content = StringBuffer();
  final StringBuffer _tagBuffer = StringBuffer();

  bool _inThinking = true; // نفترض التفكير أولاً لمعالجة غياب وسم البداية
  bool _sawAnyTag = false;

  void addChunk(String chunk) {
    for (final codeUnit in chunk.codeUnits) {
      final char = String.fromCharCode(codeUnit);

      if (_tagBuffer.isEmpty && char != '<') {
        _write(char);
        continue;
      }

      if (_tagBuffer.isEmpty && char == '<') {
        _tagBuffer.write(char);
        continue;
      }

      _tagBuffer.write(char);
      final tagCandidate = _tagBuffer.toString();

      if (tagCandidate == _openTag) {
        _sawAnyTag = true;
        _inThinking = true;
        _tagBuffer.clear();
        continue;
      }

      if (tagCandidate == _closeTag) {
        _sawAnyTag = true;
        _inThinking = false;
        _tagBuffer.clear();
        continue;
      }

      final isOpenPrefix = _openTag.startsWith(tagCandidate);
      final isClosePrefix = _closeTag.startsWith(tagCandidate);

      if (!isOpenPrefix && !isClosePrefix) {
        _write(tagCandidate);
        _tagBuffer.clear();
      }
    }
  }

  void finalize() {
    if (_tagBuffer.isNotEmpty) {
      _write(_tagBuffer.toString());
      _tagBuffer.clear();
    }
  }

  _StreamParseResult result() {
    return _StreamParseResult(
      thinking: _thinking.toString(),
      content: _content.toString(),
      isThinking: _inThinking,
      sawAnyTag: _sawAnyTag,
    );
  }

  void _write(String text) {
    if (text.isEmpty) return;
    if (_inThinking) {
      _thinking.write(text);
    } else {
      _content.write(text);
    }
  }
}


// import 'package:flutter/foundation.dart';
// import 'package:tabib_app/core/services/chat_service.dart';
// // import 'package:uuid/uuid.dart';
// import '../models/message.dart';
//
// class ChatProvider extends ChangeNotifier {
//   final IChatService _chatService;
//
//   List<ChatMessage> _messages = [];
//   bool _isLoading = false;
//   String _currentStreamBuffer = ""; // To hold the incoming stream
//
//   ChatProvider({required IChatService chatService})
//     : _chatService = chatService {
//     // Initial Welcome Message
//     _messages.add(
//       ChatMessage.assistant(
//         "أهلاً بك 🩺. أنا مساعدك الطبي الذكي. كيف يمكنني مساعدتك اليوم؟",
//       ),
//     );
//   }
//
//   List<ChatMessage> get messages => List.unmodifiable(_messages);
//   bool get isLoading => _isLoading;
//   String get currentStreamBuffer => _currentStreamBuffer;
//
//   Future<void> sendMessage(String content) async {
//     if (content.trim().isEmpty) return;
//
//     // 1. Add User Message
//     final userMsg = ChatMessage.user(content);
//     _messages.add(userMsg);
//     _isLoading = true;
//     _currentStreamBuffer = "";
//     notifyListeners();
//
//     try {
//       // 2. Start Streaming Response
//       Stream<String> stream = _chatService.sendMessage(content, _messages);
//
//       await for (final chunk in stream) {
//         _currentStreamBuffer = chunk;
//         notifyListeners();
//       }
//
//       // 3. Finalize Message
//       // Parse <think> tags to separate reasoning
//       String finalContent = _currentStreamBuffer;
//       String? thinking;
//
//       if (finalContent.contains("</think>")) {
//         final parts = finalContent.split("</think>");
//         thinking = parts[0].replaceFirst("<think>", "").trim();
//         finalContent = parts.length > 1 ? parts[1].trim() : "";
//       }
//
//       _messages.add(
//         ChatMessage.assistant(finalContent, thinkingContent: thinking),
//       );
//     } catch (e) {
//       _messages.add(ChatMessage.assistant("عذراً، حدث خطأ أثناء المعالجة: $e"));
//     } finally {
//       _isLoading = false;
//       _currentStreamBuffer = "";
//       notifyListeners();
//     }
//   }
//
//   void clearChat() {
//     _messages.clear();
//     _messages.add(
//       ChatMessage.assistant(
//         "أهلاً بك 🩺. أنا مساعدك الطبي الذكي. كيف يمكنني مساعدتك اليوم؟",
//       ),
//     );
//     notifyListeners();
//   }
// }
