import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/services/chat_service.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/chat/screens/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Injecting the Mock Service here.
        // Later, we can swap `MockChatService()` with `GrpcChatService()`
        Provider<IChatService>(create: (_) => MockChatService()),

        // Chat Provider depends on IChatService
        ChangeNotifierProxyProvider<IChatService, ChatProvider>(
          create: (context) =>
              ChatProvider(chatService: context.read<IChatService>()),
          update: (context, service, previous) =>
              previous ?? ChatProvider(chatService: service),
        ),
      ],
      child: MaterialApp(
        title: 'Tabib AI',
        debugShowCheckedModeBanner: false,

        // Localization for Arabic Support
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'AE'), // RTL Layout default
        ],
        locale: const Locale('ar', 'AE'),

        // Theme
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,

        home: const ChatScreen(),
      ),
    );
  }
}
