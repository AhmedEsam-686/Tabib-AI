import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:tabib_app/features/chat/models/message.dart';

import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "المساعد الطبي الذكي",
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            Text(
              "متصل (وضع المحاكاة)",
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.read<ChatProvider>().clearChat(),
          ),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.messages;

                // Show current stream buffer as a temporary message if loading
                final showStream =
                    provider.isLoading &&
                    provider.currentStreamBuffer.isNotEmpty;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: messages.length + (showStream ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < messages.length) {
                      return FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: MessageBubble(message: messages[index]),
                      );
                    } else {
                      // Live Streaming Message
                      // We create a temporary message to render the streaming content
                      // including <think> tags handling if implemented in Bubble,
                      // but for now let's just show raw text or parse simple

                      // Simple check for now:
                      String content = provider.currentStreamBuffer;
                      String? thinking;

                      if (content.contains("</think>")) {
                        final parts = content.split("</think>");
                        thinking = parts[0].replaceFirst("<think>", "").trim();
                        content = parts.length > 1 ? parts[1] : "";
                      } else if (content.contains("<think>")) {
                        thinking = content.replaceFirst("<think>", "").trim();
                        content = ""; // Still in thinking phase
                      }

                      // If entirely thinking, show as such
                      if (content.isEmpty && thinking == null)
                        return const SizedBox();

                      return FadeIn(
                        child: MessageBubble(
                          message: ChatMessage(
                            id: "stream",
                            content: content,
                            role: MessageRole.assistant,
                            timestamp: DateTime.now(),
                            thinkingContent: thinking,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),

          // Input Area
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final textController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: "اكتب سؤالك الطبي هنا...",
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                onSubmitted: (_) {
                  final text = textController.text;
                  textController.clear();
                  context.read<ChatProvider>().sendMessage(text);
                },
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              onPressed: () {
                final text = textController.text;
                textController.clear();
                context.read<ChatProvider>().sendMessage(text);
              },
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
