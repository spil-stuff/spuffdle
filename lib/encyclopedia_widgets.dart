import 'package:flutter/material.dart';
import 'provider.dart';
import 'constants.dart';

class EncyclopediaOverviewPage extends StatelessWidget {
  const EncyclopediaOverviewPage({super.key, required this.elements});

  final List<QuizElement> elements;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: elements.length,
        itemBuilder: (context, index) {
          return Container(
              decoration: BoxDecoration(
                color: AppColors.secondaryBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(70.0),
                  topRight: Radius.circular(70.0),
                  bottomLeft: Radius.circular(16.0),
                  bottomRight: Radius.circular(16.0)
                ),
              ),
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EncyclopediaPage(index: index, elements: elements),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(70.0,),
                      child: elements[index].image,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(elements[index].name, style: AppStyles.whiteText,),
                    ),
                  ],
                ),
              ),
          );
        },
      ),
    );
  }
}

class EncyclopediaPage extends StatefulWidget {
  const EncyclopediaPage({super.key, required this.index, required this.elements});

  final int index;
  final List<QuizElement> elements;

  @override
  State<EncyclopediaPage> createState() => EncyclopediaPageState();
}

class EncyclopediaPageState extends State<EncyclopediaPage> {
  late final PageController pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.index;
    pageController = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void goToNextPage() {
    if (_currentPage < widget.elements.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPreviousPage() {
    if (_currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canGoPrevious = _currentPage > 0;
    final bool canGoNext = _currentPage < widget.elements.length - 1;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackgroundColor,
        iconTheme: const IconThemeData(
          color: AppColors.primaryColor,
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            itemCount: widget.elements.length,
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return EncyclopediaElementPage(
                index: index,
                pageController: pageController,
                element: widget.elements[index],
              );
            },
          ),

          // Previous Page Button (Left Side)
          if (canGoPrevious)
            Positioned(
              left: 12,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: AppColors.secondaryBackgroundColor.withValues(alpha: 0.8),
                onPressed: goToPreviousPage,
              ),
            ),

          // Next Page Button (Right Side)
          if (canGoNext)
            Positioned(
              right: 12,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.arrow_forward_ios),
                color: AppColors.secondaryBackgroundColor.withValues(alpha: 0.8),
                onPressed: goToNextPage,
              ),
            ),
        ],
      ),
    );
  }
}

class EncyclopediaElementPage extends StatelessWidget {
  const EncyclopediaElementPage({
    super.key,
    required this.index,
    required this.pageController,
    required this.element,
  });

  final int index;
  final PageController pageController;
  final QuizElement element;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(64.0, 0.0, 64.0, 64.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              element.name,
              style: AppStyles.whiteText.copyWith(fontSize: 34),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              element.games.join(', '),
              style: AppStyles.greyText.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackgroundColor,
                borderRadius: BorderRadius.circular(64.0),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < constraints.maxHeight || constraints.maxWidth < 600;

                  return Flex(
                    direction: isNarrow ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: isNarrow ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: element.image,
                        ),
                      ),
                      SizedBox(
                        width: 16,
                        height: 32,
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Text(
                            element.description ?? "No description!",
                            style: AppStyles.whiteText.copyWith(fontSize: 22),
                            textAlign: TextAlign.start,
                          ),
                          ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}