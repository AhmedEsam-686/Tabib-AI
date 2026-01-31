import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message.dart';
import '../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.role == MessageRole.user) {
      return _buildUserMessage(context);
    } else {
      return _buildAssistantMessage(context);
    }
  }

  Widget _buildUserMessage(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85, // Reduced width to avoid "stretched" look
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text("🩺", style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Text(
                  "المساعد الطبي الذكي",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduced vertical spacing
            
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thinking Section
                  if (message.thinkingContent != null)
                    _buildReasoningBox(context, message.thinkingContent!, message.isThinking),

                  if (message.thinkingContent != null)
                    const SizedBox(height: 6), // Reduced spacing between thinking and card

                  // Main Response - Valid Template
                  Container(
                    padding: const EdgeInsets.all(14), // Reduced padding inside card
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.cairo(
                          fontSize: 15, // Slightly smaller font
                          height: 1.6,
                          color: theme.colorScheme.onSurface,
                        ),
                        h1: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                        h2: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface, // Adapt to theme
                        ),
                        h3: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        listBullet: const TextStyle(color: AppTheme.secondary),
                        code: GoogleFonts.robotoMono(
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        blockquote: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(right: BorderSide(color: AppTheme.secondary, width: 4)),
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningBox(BuildContext context, String content, bool isThinking) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B).withOpacity(0.5) 
            : const Color(0xFFE2E8F0), // Lighter grey for light mode
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.1),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: const Border(), // Remove default borders
        collapsedShape: const Border(),
        leading: Icon(
          Icons.psychology_outlined, 
          color: theme.hintColor, 
          size: 20
        ),
        title: Text(
          isThinking ? "جاري التفكير..." : "تم تحليل الاستفسار",
          style: GoogleFonts.cairo(
            fontSize: 13, 
            color: theme.hintColor,
            fontWeight: FontWeight.w600
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.cairo(
                fontSize: 13, 
                color: theme.textTheme.bodySmall?.color,
                height: 1.5
              ),
              code: GoogleFonts.robotoMono(
                  fontSize: 12,
                  backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
