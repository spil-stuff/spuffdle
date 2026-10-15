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
  final Set<QuizElement> _pendingGuessReveals = {};

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
      _pendingGuessReveals.add(guess);
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
      _pendingGuessReveals.clear();
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QuizElementCategoryLabelWidget(label: 'Photo', width: 100),
                  QuizElementCategoryLabelWidget(label: 'Name', width: 200),
                  QuizElementCategoryLabelWidget(label: 'Gender', width: 100),
                  QuizElementCategoryLabelWidget(label: 'Hair Colour', width: 100),
                  QuizElementCategoryLabelWidget(label: 'Eye Colour', width: 100),
                  QuizElementCategoryLabelWidget(label: 'Developers', width: 110),
                  QuizElementCategoryLabelWidget(label: 'Games', width: 200),
                  QuizElementCategoryLabelWidget(label: 'Year', width: 100),
                  QuizElementCategoryLabelWidget(label: 'Engine', width: 100),
                  QuizElementCategoryLabelWidget(label: 'Genres', width: 100),
                ],
              ),
            ),
            if (_quiz.completed) QuizElementWidget(quizElement: _quiz.answer, answer: _quiz.answer),
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
                        findChildIndexCallback: (key) {
                          if (key is ObjectKey) {
                            final index = guesses.indexWhere(
                              (guess) => identical(guess, key.value),
                            );
                            return index == -1 ? null : index;
                          }
                          return null;
                        },
                        itemBuilder: (context, index) {
                          final guess = guesses[index];
                          final reveal = _pendingGuessReveals.contains(guess);
                          return QuizElementWidget(
                            key: ObjectKey(guess),
                            quizElement: guess,
                            answer: _quiz.answer,
                            reveal: reveal,
                            onRevealStarted: reveal
                                ? () => _pendingGuessReveals.remove(guess)
                                : null,
                          );
                        },
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
  static const double _optionHeight = 80;
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
                                        SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4,),
                                            child: element.image,
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

class QuizElementWidget extends StatefulWidget {
  const QuizElementWidget({
    super.key,
    required this.quizElement,
    required this.answer,
    this.reveal = false,
    this.onRevealStarted,
  });

  final QuizElement quizElement;
  final QuizElement answer;
  final bool reveal;
  final VoidCallback? onRevealStarted;

  @override
  State<QuizElementWidget> createState() => _QuizElementWidgetState();
}

class _QuizElementWidgetState extends State<QuizElementWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  bool _hasStartedReveal = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.reveal) {
      _startReveal();
    }
  }

  @override
  void didUpdateWidget(covariant QuizElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reveal && !_hasStartedReveal) {
      _startReveal();
    }
  }

  void _startReveal() {
    _hasStartedReveal = true;
    widget.onRevealStarted?.call();
    _revealController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Widget _category(int index, double width) {
    return QuizElementCategoryWidget(
      category: widget.quizElement.categories[index],
      quizElement: widget.quizElement,
      answer: widget.answer,
      width: width,
      revealAnimation: _hasStartedReveal ? _revealController : null,
      revealIndex: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QuizElementImageWidget(quizElement: widget.quizElement),
          _category(0, 200),
          _category(1, 100),
          _category(2, 100),
          _category(3, 100),
          _category(4, 110),
          _category(5, 200),
          _category(6, 100),
          _category(7, 100),
          _category(8, 100),
        ],
      ),
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
    required this.quizElement,
    required this.answer,
    required this.category,
    required this.width,
    this.revealAnimation,
    this.revealIndex = 0,
  });

  final QuizElement quizElement;
  final QuizElement answer;
  final QuizElementCategory<T> category;
  final double width;
  final Animation<double>? revealAnimation;
  final int revealIndex;

  @override
  State<QuizElementCategoryWidget<T>> createState() =>
      QuizElementCategoryWidgetState<T>();
}

class QuizElementCategoryWidgetState<T>
    extends State<QuizElementCategoryWidget<T>> {
  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: widget.width,
      height: 100,
      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: widget.category.matches.color,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                if(widget.category.value is int)
                  (
                    widget.quizElement.getYearDifferenceIcon(widget.answer.year) ?? SizedBox()
                  ),
                ...(widget.category.value is List
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
                    ),
            ],
          ),
        ),
      ),
    );

    final animation = widget.revealAnimation;
    if (animation == null) {
      return card;
    }

    return AnimatedBuilder(
      animation: animation,
      child: card,
      builder: (context, child) {
        const stagger = 0.075;
        const flipDuration = 0.2;
        final progress =
            ((animation.value - widget.revealIndex * stagger) / flipDuration)
                .clamp(0.0, 1.0)
                .toDouble();
        final rotation =
            (1 - Curves.easeInOutCubic.transform(progress)) *
            (3.141592653589793 / 2);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotation),
          child: child,
        );
      },
    );
  }
}
