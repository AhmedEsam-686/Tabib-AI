// lib/core/services/chat_service.dart

import 'dart:async';
import 'dart:developer' as developer;

import 'package:grpc/grpc.dart';
// استيراد ملفات gRPC المولدة
import '../../generated/rag.pbgrpc.dart' as grpc_lib;
import '../../generated/rag.pb.dart' as pb;

// استيراد المودل وإدارة الاتصال
import '../../features/chat/models/message.dart';
import '../grpc/grpc_connection.dart';

/// الواجهة الأساسية (العقد)
abstract class IChatService {
  Stream<String> sendMessage(String message, List<ChatMessage> history);
}

/// ============================================================================
/// 1. خدمة الـ gRPC الحقيقية (Real Backend Service)
/// ============================================================================
class GrpcChatService implements IChatService {

  @override
  Stream<String> sendMessage(String message, List<ChatMessage> history) async* {
    final logName = 'GrpcChatService';

    // 1. التحقق من الاتصال
    if (!GrpcConnection().isInitialized) {
      developer.log('❌ Error: Connection not initialized', name: logName);
      throw Exception('لم يتم تهيئة الاتصال بالسيرفر.');
    }

    try {
      // 2. إنشاء العميل (Stub)
      // نستخدم القناة المفتوحة مسبقاً في GrpcConnection
      final stub = grpc_lib.MedicalChatServiceClient(GrpcConnection().channel);

      // 3. تحضير البيانات (Data Preparation)
      developer.log('🛠️ Preparing request payload...', name: logName);

      // تحويل قائمة الرسائل من ChatMessage إلى pb.Message
      // ملاحظة: الـ Provider يرسل القائمة كاملة (بما فيها رسالة المستخدم الأخيرة)
      final protoMessages = history.map((m) => m.toProto()).toList();

      // إعدادات التوليد (يمكنك تعديلها لاحقاً لتكون ديناميكية)
      final config = pb.GenerationConfig(
        maxTokens: 4096,
        temperature: 0.7,
        topP: 0.8,
      );

      // بناء الطلب النهائي
      final request = pb.ChatRequest(
        messages: protoMessages,
        config: config,
        sessionId: 'mobile-session-${DateTime.now().millisecondsSinceEpoch}', // معرف جلسة مؤقت
      );

      developer.log('🚀 Sending request to server... (Messages: ${protoMessages.length})', name: logName);

      // 4. بدء الاتصال واستقبال التدفق (Streaming)
      final responseStream = stub.generateStream(request);

      bool isFirstChunk = true;
      int chunkCount = 0;

      await for (final response in responseStream) {
        // تتبع أول استجابة (لحساب زمن الاستجابة Latency)
        if (isFirstChunk) {
          developer.log('✅ Received first chunk from server!', name: logName);
          isFirstChunk = false;
        }

        // إذا كانت الرسالة تحتوي على نص، قم بإرساله للواجهة
        if (response.token.isNotEmpty) {
          chunkCount++;
          yield response.token;
        }
      }

      developer.log('🏁 Stream finished successfully. Total chunks: $chunkCount', name: logName);

    } on GrpcError catch (e) {
      // التعامل الخاص مع أخطاء gRPC
      developer.log('🔥 gRPC Error: Code=${e.code}, Message=${e.message}', name: logName, error: e);

      if (e.code == StatusCode.unavailable) {
        throw Exception('عذراً، الخادم غير متاح حالياً. تأكد من تشغيل Ngrok.');
      } else if (e.code == StatusCode.deadlineExceeded) {
        throw Exception('استغرق الخادم وقتاً طويلاً للرد.');
      } else {
        throw Exception('خطأ في الاتصال: ${e.message}');
      }
    } catch (e) {
      // أي خطأ آخر غير متوقع
      developer.log('💥 Unexpected Error', name: logName, error: e);
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}

/// ============================================================================
/// 2. الخدمة الوهمية (للاختبار فقط عند عدم وجود سيرفر)
/// ============================================================================
class MockChatService implements IChatService {
  @override
  Stream<String> sendMessage(String message, List<ChatMessage> history) async* {
    // محاكاة تأخير الشبكة
    await Future.delayed(const Duration(milliseconds: 500));

    // محاكاة عملية التفكير
    final String reasoning = """<think>
Checking medical database...
Analyzing symptoms: "$message"...
Found match in document [ID: 123]
Formulating answer...
</think>
""";

    // إرسال التفكير حرفاً حرفاً
    for (int i = 0; i < reasoning.length; i++) {
      yield reasoning[i]; // محاكاة إرسال الحرف كـ Token
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // محاكاة الرد النهائي
    String response = "بناءً على الأعراض المذكورة، يُنصح بشرب الكثير من السوائل والراحة.";

    for (int i = 0; i < response.length; i++) {
      yield response[i];
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }
}


// import 'dart:async';
// // import 'package:uuid/uuid.dart';
//
// import '../../features/chat/models/message.dart';
//
// /// Abstract Interface for Chat Service
// /// This allows us to switch between Mock and Real gRPC easily.
// abstract class IChatService {
//   Stream<String> sendMessage(String message, List<ChatMessage> history);
// }
//
// /// Simulated Service (No Backend Required)
// class MockChatService implements IChatService {
//   @override
//   Stream<String> sendMessage(String message, List<ChatMessage> history) async* {
//     // 1. Simulate Network Delay
//     await Future.delayed(const Duration(milliseconds: 500));
//
//     // 2. Simulate Reasoning (Thinking Process)
//     // We send the reasoning inside special tags like the real backend
//     final String reasoning =
//         """<think>
// Checking medical knowledge base...
// Analyzing symptoms: "$message"...
// Querying vector database...
// Found relevant documents: [Document A, Document B]
// Formulating response based on medical guidelines...
// </think>
// """;
//
//     // Simulate streaming the reasoning character by character
//     for (int i = 0; i < reasoning.length; i++) {
//       yield reasoning.substring(0, i + 1);
//       await Future.delayed(const Duration(milliseconds: 10));
//     }
//
//     // 3. Simulate Final Response
//     String response =
//         """
// Based on your query regarding "$message", here is the analysis:
//
// **Diagnosis:**
// The symptoms described are consistent with common seasonal allergies, but could also indicate a mild viral infection.
//
// **Recommendations:**
// 1.  **Monitor Temperature:** Keep track of body temperature every 4 hours.
// 2.  **Hydration:** Drink plenty of fluids.
// 3.  **Rest:** Ensure adequate sleep.
//
// *Note: This is an AI-generated suggestion. Please consult a doctor.*
// """;
//
//     String buffer = reasoning;
//     for (int i = 0; i < response.length; i++) {
//       buffer += response[i];
//       yield buffer;
//       await Future.delayed(const Duration(milliseconds: 20));
//     }
//   }
// }
