// lib/features/chat/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/theme_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "المساعد الطبي الذكي",
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (!AppConfig.useMockService)
              Text(
                "متصل (السيرفر الحقيقي)",
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.green),
              ),
          ],
        ),
        centerTitle: false, // User asked for start alignment (implied by "not in the middle")
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.messages;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: MessageBubble(message: messages[index]),
                    );
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.backgroundDark,
            ),
            currentAccountPicture: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
              ),
              child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 30),
            ),
            accountName: Text("Tabib AI", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            accountEmail: Text("v2.1 | Medical Assistant", style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.add_comment_outlined, color: AppTheme.secondary),
            title: Text("محادثة جديدة", style: GoogleFonts.cairo()),
            onTap: () {
              context.read<ChatProvider>().clearChat();
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              final isDark = themeProvider.isDarkMode;
              return ListTile(
                leading: Icon(
                    isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                    color: isDark ? Colors.orange : Colors.indigo),
                title: Text(isDark ? "الوضع النهاري" : "الوضع الليلي",
                    style: GoogleFonts.cairo()),
                onTap: () {
                  context.read<ThemeProvider>().toggleTheme();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final textController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced outer padding
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            // Use lighter color for light mode, deep dark for dark mode
            color: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9), 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.5)),
          ),
          padding: const EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 0), // Minimal internal padding
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  // Adaptive text color
                  style: GoogleFonts.cairo(
                    color: theme.textTheme.bodyMedium?.color, 
                    fontSize: 14,
                    height: 1.2, // Tighter line height
                  ),
                  decoration: InputDecoration(
                    hintText: "اكتب سؤالك الطبي هنا...",
                    hintStyle: GoogleFonts.cairo(
                      color: theme.hintColor.withOpacity(0.6), 
                      fontSize: 13
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Adjust content padding
                    filled: false,
                    isDense: true,
                  ),
                  onSubmitted: (_) {
                    final text = textController.text;
                    textController.clear();
                    context.read<ChatProvider>().sendMessage(text);
                  },
                ),
              ),
              const SizedBox(width: 4),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),// Very small margin
                height: 35, // Small button size
                width: 35,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20), // Small icon
                  onPressed: () {
                    final text = textController.text;
                    textController.clear();
                    context.read<ChatProvider>().sendMessage(text);
                  },
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // Tiny button
                  padding: EdgeInsets.zero,
                  tooltip: 'إرسال',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
