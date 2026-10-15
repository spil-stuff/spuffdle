import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:spuffdle/encyclopedia_widgets.dart';
import 'quiz_widgets.dart';
import 'provider.dart';
import 'constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => AsyncProvider(),
        child: const MainApp(),
      ),
    );
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBackgroundColor),
        useMaterial3: true,
      ),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            // Keeps text between 80% and 100% of normal size
            textScaler: mediaQueryData.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.0, 
            ),
          ),
          child: child!,
        );
      },
      home: const HomePage(),
    );
  }
}

enum Page {
  daily("Daily"),
  infinite("Infinite"),
  encyclopedia("Encyclopedia");

  const Page(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  Page _currentPage = Page.daily;
  Quiz? _infiniteQuiz; // Preserves infinite quiz data across rebuilds
  int _dailyKeyCounter = 0;
  int _infiniteKeyCounter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AsyncProvider>().loadQuizElements();
      }
    });
  }

  void _selectPage(Page newPage) {
    setState(() {
      _currentPage = newPage;
      
      if (newPage == Page.daily) _dailyKeyCounter++;
      if (newPage == Page.infinite) _infiniteKeyCounter++;
    });

    Navigator.pop(context); // Close drawer
  }

  Widget _buildBody(AsyncProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentPage) {
      case Page.daily:
        if (provider.dailyQuiz == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return QuizPage(key: ValueKey('daily_$_dailyKeyCounter'), quiz: provider.dailyQuiz!, isDaily: true);

      case Page.infinite:
        _infiniteQuiz ??= provider.createQuiz(false);
        return QuizPage(key: ValueKey('infinite_$_infiniteKeyCounter'),quiz: _infiniteQuiz!, isDaily: false);

      case Page.encyclopedia:
        return EncyclopediaOverviewPage(elements: provider.quizElements);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProvider = Provider.of<AsyncProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.primaryBackgroundColor,
      drawer: Drawer(
        backgroundColor: AppColors.secondaryBackgroundColor,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('Pages', style: AppStyles.whiteText),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.today, color: AppColors.primaryColor),
                title: const Text('Daily Quiz', style: AppStyles.whiteText),
                selected: _currentPage == Page.daily,
                onTap: () => _selectPage(Page.daily),
              ),
              ListTile(
                leading: const Icon(
                  Icons.all_inclusive,
                  color: AppColors.primaryColor,
                ),
                title: const Text('Infinite Quiz', style: AppStyles.whiteText),
                selected: _currentPage == Page.infinite,
                onTap: () => _selectPage(Page.infinite),
              ),
              ListTile(
                leading: const Icon(
                  Icons.book_outlined,
                  color: AppColors.primaryColor,
                ),
                title: const Text('Encyclopedia', style: AppStyles.whiteText),
                selected: _currentPage == Page.encyclopedia,
                onTap: () => _selectPage(Page.encyclopedia),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(
          'spuffdle ${_currentPage.displayName}',
          style: AppStyles.whiteText,
        ),
        backgroundColor: AppColors.primaryBackgroundColor,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
      ),
      body: _buildBody(asyncProvider),
    );
  }
}