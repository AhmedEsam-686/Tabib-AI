// lib/features/chat/models/message.dart

import 'package:uuid/uuid.dart';
// نقوم باستيراد ملفات البروتو المولدة ونعطيها اسماً مستعاراً (alias)
// لتجنب تضارب الأسماء إذا كان هناك كلاسات متشابهة
import '../../../generated/rag.pb.dart' as pb;

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  // حالة التفكير (خاصة بالواجهة فقط)
  final bool isThinking;
  final String? thinkingContent;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isThinking = false,
    this.thinkingContent,
  });

  // Factory لإنشاء رسالة مستخدم
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: const Uuid().v4(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
  }

  // Factory لإنشاء رسالة مساعد (بوت)
  factory ChatMessage.assistant(String content, {String? thinkingContent}) {
    return ChatMessage(
      id: const Uuid().v4(),
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      thinkingContent: thinkingContent,
    );
  }

  /// --------------------------------------------------------------------------
  /// New: gRPC Mapping
  /// تحويل كلاس الرسالة الخاص بالتطبيق إلى كلاس الرسالة الخاص بـ Protobuf
  /// ليتم إرساله للسيرفر
  /// --------------------------------------------------------------------------
  pb.Message toProto() {
    return pb.Message(
      // نقوم بتحويل الـ Enum إلى نص (String) لأن السيرفر يتوقع نصاً
      // MessageRole.user.name => "user"
      role: role.name,
      content: content,
    );
  }

  /// --------------------------------------------------------------------------
  /// Utility: CopyWith
  /// مفيد جداً عند تحديث الرسالة أثناء استقبال الـ Stream
  /// بدلاً من إنشاء كائن جديد يدوياً في كل مرة
  /// --------------------------------------------------------------------------
  ChatMessage copyWith({
    String? content,
    bool? isThinking,
    String? thinkingContent,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      timestamp: timestamp,
      content: content ?? this.content,
      isThinking: isThinking ?? this.isThinking,
      thinkingContent: thinkingContent ?? this.thinkingContent,
    );
  }
}



// import 'package:uuid/uuid.dart';
//
// enum MessageRole { user, assistant, system }
//
// class ChatMessage {
//   final String id;
//   final String content;
//   final MessageRole role;
//   final DateTime timestamp;
//   final bool isThinking; // For reasoning UI state (expanded/collapsed)
//   final String? thinkingContent; // separation of reasoning
//
//   ChatMessage({
//     required this.id,
//     required this.content,
//     required this.role,
//     required this.timestamp,
//     this.isThinking = false,
//     this.thinkingContent,
//   });
//
//   factory ChatMessage.user(String content) {
//     return ChatMessage(
//       id: const Uuid().v4(),
//       content: content,
//       role: MessageRole.user,
//       timestamp: DateTime.now(),
//     );
//   }
//
//   factory ChatMessage.assistant(String content, {String? thinkingContent}) {
//     return ChatMessage(
//       id: const Uuid().v4(),
//       content: content,
//       role: MessageRole.assistant,
//       timestamp: DateTime.now(),
//       thinkingContent: thinkingContent,
//     );
//   }
// }
