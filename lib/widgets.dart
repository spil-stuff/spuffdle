import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'provider.dart';
import 'constants.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.quiz, required this.isDaily});

  final Quiz quiz;
  final bool isDaily;

  @override
  State<QuizPage> createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  final ScrollController _guessesScrollController = ScrollController();
  late Quiz _quiz;
  late bool _isDaily;
  late List<QuizElement> _shownGuesses;

  @override
  void initState() {
    super.initState();
    _quiz = widget.quiz;
    _isDaily = widget.isDaily;
    _shownGuesses = List<QuizElement>.of(_quiz.guesses);
  }

  @override
  void dispose() {
    _guessesScrollController.dispose();
    super.dispose();
  }

  Future<void> guess(QuizElement guess) async {
    final asyncProvider = Provider.of<AsyncProvider>(context, listen: false);
    final submission = asyncProvider.submitGuess(
      _quiz,
      guess,
      isDaily: _isDaily,
    );

    if (!_quiz.completed) {
      _shownGuesses.add(guess);
    }

    setState(() {});
    await submission;
  }

  void _selectGameMode(bool isDaily, {bool closeDrawer = true}) {
    final provider = Provider.of<AsyncProvider>(context, listen: false);
    setState(() {
      _isDaily = isDaily;
      _quiz = isDaily ? provider.dailyQuiz! : provider.createQuiz(false);
      _shownGuesses = List<QuizElement>.of(_quiz.guesses);
    });
    if (closeDrawer) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProvider = Provider.of<AsyncProvider>(context);
    final guesses = _shownGuesses.reversed.toList();
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
                  child: Text('Game mode', style: AppStyles.whiteText),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.today, color: AppColors.primaryColor),
                title: const Text('Daily mode', style: AppStyles.whiteText),
                selected: _isDaily,
                onTap: () => _selectGameMode(true),
              ),
              ListTile(
                leading: const Icon(
                  Icons.all_inclusive,
                  color: AppColors.primaryColor,
                ),
                title: const Text('Infinite mode', style: AppStyles.whiteText),
                selected: !_isDaily,
                onTap: () => _selectGameMode(false),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(
          'spuffdle ${_isDaily ? "Daily" : "Infinite"}',
          style: AppStyles.whiteText,
        ),
        backgroundColor: AppColors.primaryBackgroundColor,
        iconTheme: IconThemeData(color: AppColors.primaryColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 400,
              child: _quiz.completed
                  ? const SizedBox(height: 50)
                  : QuizElementGuessingMenu(
                      key: ValueKey(_isDaily),
                      elements: asyncProvider.quizElements
                          .where((element) => !_quiz.guesses.contains(element))
                          .toList(),
                      onSelected: guess,
                    ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QuizElementCategoryLabelWidget(label: 'Photo', width: 100),
                QuizElementCategoryLabelWidget(label: 'Name', width: 200),
                QuizElementCategoryLabelWidget(label: 'Gender', width: 100),
                QuizElementCategoryLabelWidget(
                  label: 'Hair Colour',
                  width: 100,
                ),
                QuizElementCategoryLabelWidget(label: 'Eye Colour', width: 100),
                QuizElementCategoryLabelWidget(label: 'Developers', width: 110),
                QuizElementCategoryLabelWidget(label: 'Games', width: 200),
                QuizElementCategoryLabelWidget(label: 'Year', width: 100),
                QuizElementCategoryLabelWidget(label: 'Engine', width: 100),
                QuizElementCategoryLabelWidget(label: 'Genres', width: 100),
              ],
            ),
            if (_quiz.completed) QuizElementWidget(quizElement: _quiz.answer),
            Expanded(
              child: guesses.isEmpty
                  ? const SizedBox.shrink()
                  : Scrollbar(
                      controller: _guessesScrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _guessesScrollController,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: guesses.length,
                        itemBuilder: (context, index) =>
                            QuizElementWidget(quizElement: guesses[index]),
                      ),
                    ),
            ),
            if (_quiz.completed && !_isDaily)
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _selectGameMode(false, closeDrawer: false),
                  icon: const Icon(Icons.refresh),
                  label: const Text('New character'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class QuizElementGuessingMenu extends StatefulWidget {
  const QuizElementGuessingMenu({
    super.key,
    required this.elements,
    required this.onSelected,
  });

  final List<QuizElement> elements;
  final ValueChanged<QuizElement> onSelected;

  @override
  State<QuizElementGuessingMenu> createState() =>
      _QuizElementGuessingMenuState();
}

class _QuizElementGuessingMenuState extends State<QuizElementGuessingMenu> {
  static const double _optionHeight = 48;
  static const int _maxVisibleOptions = 6;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final ScrollController _resultsScrollController = ScrollController();
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _resultsScrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _overlayController.show();
    } else {
      _overlayController.hide();
    }
    _refresh();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _dismiss() {
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final results = widget.elements
        .where((element) => element.name.toLowerCase().contains(query))
        .toList();
    final rowCount = results.length.clamp(1, _maxVisibleOptions);
    final menuHeight = rowCount * _optionHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth;

        return OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                ),
              ),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                child: Material(
                  color: AppColors.secondaryBackgroundColor,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: menuWidth,
                    height: menuHeight,
                    child: results.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching characters',
                              style: AppStyles.greyText,
                            ),
                          )
                        : Scrollbar(
                            controller: _resultsScrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _resultsScrollController,
                              padding: EdgeInsets.zero,
                              itemExtent: _optionHeight,
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final element = results[index];
                                return InkWell(
                                  onTap: () {
                                    widget.onSelected(element);
                                    _searchController.clear();
                                    _dismiss();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.asset(
                                            element.imagePath,
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            element.name,
                                            style: AppStyles.whiteText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onTapOutside: (_) {},
              style: AppStyles.whiteText,
              decoration: InputDecoration(
                hintText: 'Search characters...',
                hintStyle: AppStyles.greyText,
                filled: true,
                fillColor: AppColors.secondaryBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class QuizElementCategoryLabelWidget extends StatelessWidget {
  const QuizElementCategoryLabelWidget({
    super.key,
    required this.label,
    required this.width,
  });

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 30,
      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppStyles.greyText,
        ),
      ),
    );
  }
}

class QuizElementWidget extends StatelessWidget {
  const QuizElementWidget({super.key, required this.quizElement});

  final QuizElement quizElement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        QuizElementImageWidget(quizElement: quizElement),
        QuizElementCategoryWidget(
          category: quizElement.categories[0],
          width: 200,
        ),
        QuizElementCategoryWidget(
          category: quizElement.categories[1],
          width: 100,
        ),
        QuizElementCategoryWidget(
          category: quizElement.categories[2],
          width: 100,
        ),
        QuizElementCategoryWidget(
          category: quizElement.categories[3],
          width: 100,
        ),
        QuizElementCategoryWidget(
          category: quizElement.categories[4],
          width: 110,
        ),
        QuizElementCategoryWidget(
          category: quizElement.categories[5],
          width: 200,
        ),
        QuizElementCategoryWidget(
          category: quizElement.categories[6],
          width: 100,
        ),
        QuizElementCategoryWidget(
          category: quizElement.categories[7],
          width: 100,
        ),
        QuizElementCategoryWidget(
          category: quizElement.categories[8],
          width: 100,
        ),
      ],
    );
  }
}

class QuizElementImageWidget extends StatefulWidget {
  const QuizElementImageWidget({super.key, required this.quizElement});

  final QuizElement quizElement;

  @override
  State<QuizElementImageWidget> createState() => QuizElementImageWidgetState();
}

class QuizElementImageWidgetState extends State<QuizElementImageWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.all(2.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: widget.quizElement.image,
      ),
    );
  }
}

class QuizElementCategoryWidget<T> extends StatefulWidget {
  const QuizElementCategoryWidget({
    super.key,
    required this.category,
    required this.width,
  });

  final QuizElementCategory<T> category;
  final double width;

  @override
  State<QuizElementCategoryWidget<T>> createState() =>
      QuizElementCategoryWidgetState<T>();
}

class QuizElementCategoryWidgetState<T>
    extends State<QuizElementCategoryWidget<T>> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: 100,
      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: widget.category.matches.color,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              (widget.category.value is List
                      ? widget.category.value as List
                      : [widget.category.value])
                  .map(
                    (item) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item == null ? 'N/A' : item.toString(),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: AppStyles.whiteText,
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
