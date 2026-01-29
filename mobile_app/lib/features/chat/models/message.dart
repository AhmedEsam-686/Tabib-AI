import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isThinking; // For reasoning UI state (expanded/collapsed)
  final String? thinkingContent; // separation of reasoning

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isThinking = false,
    this.thinkingContent,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: const Uuid().v4(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String content, {String? thinkingContent}) {
    return ChatMessage(
      id: const Uuid().v4(),
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      thinkingContent: thinkingContent,
    );
  }
}
