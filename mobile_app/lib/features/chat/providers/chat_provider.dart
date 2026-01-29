import 'package:flutter/foundation.dart';
import 'package:tabib_app/core/services/chat_service.dart';
// import 'package:uuid/uuid.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  final IChatService _chatService;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _currentStreamBuffer = ""; // To hold the incoming stream

  ChatProvider({required IChatService chatService})
    : _chatService = chatService {
    // Initial Welcome Message
    _messages.add(
      ChatMessage.assistant(
        "أهلاً بك 🩺. أنا مساعدك الطبي الذكي. كيف يمكنني مساعدتك اليوم؟",
      ),
    );
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get currentStreamBuffer => _currentStreamBuffer;

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // 1. Add User Message
    final userMsg = ChatMessage.user(content);
    _messages.add(userMsg);
    _isLoading = true;
    _currentStreamBuffer = "";
    notifyListeners();

    try {
      // 2. Start Streaming Response
      Stream<String> stream = _chatService.sendMessage(content, _messages);

      await for (final chunk in stream) {
        _currentStreamBuffer = chunk;
        notifyListeners();
      }

      // 3. Finalize Message
      // Parse <think> tags to separate reasoning
      String finalContent = _currentStreamBuffer;
      String? thinking;

      if (finalContent.contains("</think>")) {
        final parts = finalContent.split("</think>");
        thinking = parts[0].replaceFirst("<think>", "").trim();
        finalContent = parts.length > 1 ? parts[1].trim() : "";
      }

      _messages.add(
        ChatMessage.assistant(finalContent, thinkingContent: thinking),
      );
    } catch (e) {
      _messages.add(ChatMessage.assistant("عذراً، حدث خطأ أثناء المعالجة: $e"));
    } finally {
      _isLoading = false;
      _currentStreamBuffer = "";
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
