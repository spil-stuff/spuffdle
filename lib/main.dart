import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'widgets.dart';
import 'provider.dart';
import 'constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => AsyncProvider(),
        child: const MainApp(),
      ),
    );
  });
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AsyncProvider>().loadQuizElements();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncProvider = Provider.of<AsyncProvider>(context);

    return MaterialApp(
      title: 'spuffdle',
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          selectionHandleColor: AppColors.highlightColor,
          selectionColor: AppColors.secondaryHighlightColor,
          cursorColor: AppColors.highlightColor,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Colors.cyan.shade600),
          trackColor: WidgetStateProperty.all(AppColors.secondaryColor),
          crossAxisMargin: 5,
          minThumbLength: 40,
          thickness: WidgetStateProperty.all(8.0),
          radius: const Radius.circular(4),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBackgroundColor,
        ),
        useMaterial3: true,
      ),
      home: asyncProvider.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : QuizPage(quiz: asyncProvider.getDailyQuiz()),
    );
  }
}
