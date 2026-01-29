import 'dart:async';
// import 'package:uuid/uuid.dart';

import '../../features/chat/models/message.dart';

/// Abstract Interface for Chat Service
/// This allows us to switch between Mock and Real gRPC easily.
abstract class IChatService {
  Stream<String> sendMessage(String message, List<ChatMessage> history);
}

/// Simulated Service (No Backend Required)
class MockChatService implements IChatService {
  @override
  Stream<String> sendMessage(String message, List<ChatMessage> history) async* {
    // 1. Simulate Network Delay
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Simulate Reasoning (Thinking Process)
    // We send the reasoning inside special tags like the real backend
    final String reasoning =
        """<think>
Checking medical knowledge base...
Analyzing symptoms: "$message"...
Querying vector database...
Found relevant documents: [Document A, Document B]
Formulating response based on medical guidelines...
</think>
""";

    // Simulate streaming the reasoning character by character
    for (int i = 0; i < reasoning.length; i++) {
      yield reasoning.substring(0, i + 1);
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // 3. Simulate Final Response
    String response =
        """
Based on your query regarding "$message", here is the analysis:

**Diagnosis:**
The symptoms described are consistent with common seasonal allergies, but could also indicate a mild viral infection.

**Recommendations:**
1.  **Monitor Temperature:** Keep track of body temperature every 4 hours.
2.  **Hydration:** Drink plenty of fluids.
3.  **Rest:** Ensure adequate sleep.

*Note: This is an AI-generated suggestion. Please consult a doctor.*
""";

    String buffer = reasoning;
    for (int i = 0; i < response.length; i++) {
      buffer += response[i];
      yield buffer;
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }
}
