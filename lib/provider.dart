import 'dart:math';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

enum Gender {
  male('Male'),
  female('Female'),
  other('Other'),
  unknown('Unknown');

  const Gender(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

enum Developer {
  tacecaps('tacecapS'),
  slayervictor('slayervictor'),
  pancakeey('Pancakeey');

  const Developer(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

enum Engine {
  gamemaker('GameMaker'),
  unity('Unity'),
  godot('Godot'),
  unreal('Unreal'),
  custom('Custom'),
  pyqt('PyQt'),
  pygame('Pygame');

  const Engine(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

enum Genre {
  action('Action'),
  adventure('Adventure'),
  rpg('RPG'),
  simulation('Simulation'),
  strategy('Strategy'),
  sports('Sports'),
  racing('Racing'),
  puzzle('Puzzle'),
  platformer('Platformer'),
  turnbased('Turn-Based'),
  roguelike('Roguelike'),
  fighting('Fighting'),
  horror('Horror'),
  narrative('Narrative'),
  rhythm('Rhythm'),
  tool('Tool'),
  sandbox('Sandbox'),
  shooter('Shooter');

  const Genre(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

enum QuizElementCategoryMatch {
  no(AppColors.red),
  partial(AppColors.yellow),
  yes(AppColors.green);

  const QuizElementCategoryMatch(this.color);

  final Color color;
}

class QuizElementCategory<T> {
  final T value;

  QuizElementCategory(this.value);

  QuizElementCategoryMatch matches = QuizElementCategoryMatch.no;
}

class QuizElement {
  QuizElement({
    required this.imagePath,
    required this.name,
    required this.gender,
    required this.hairColor,
    required this.eyeColor,
    required this.developers,
    required this.games,
    required this.year,
    required this.engine,
    required this.genres,
  }) : categories = [
         QuizElementCategory<String>(name),
         QuizElementCategory<Gender>(gender),
         QuizElementCategory<String>(hairColor),
         QuizElementCategory<String>(eyeColor),
         QuizElementCategory<List<Developer>>(developers),
         QuizElementCategory<List<String>>(games),
         QuizElementCategory<int?>(year),
         QuizElementCategory<List<Engine>>(engine),
         QuizElementCategory<List<Genre>>(genres),
       ];

  final String imagePath;
  final String name;
  final Gender gender;
  final String hairColor;
  final String eyeColor;
  final List<Developer> developers;
  final List<String> games;
  final int? year;
  final List<Engine> engine;
  final List<Genre> genres;

  Image get image => Image.asset(imagePath, fit: BoxFit.cover);

  List<QuizElementCategory> categories;

  void updateMatches(QuizElement other) {
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].value is List && other.categories[i].value is List) {
        List<dynamic> list1 = categories[i].value as List<dynamic>;
        List<dynamic> list2 = other.categories[i].value as List<dynamic>;

        if (list2.every((element) => list1.contains(element))) {
          categories[i].matches = QuizElementCategoryMatch.yes;
        } else if (list2.any((element) => list1.contains(element))) {
          categories[i].matches = QuizElementCategoryMatch.partial;
        } else {
          categories[i].matches = QuizElementCategoryMatch.no;
        }
      } else if (categories[i].value == other.categories[i].value) {
        categories[i].matches = QuizElementCategoryMatch.yes;
      } else {
        categories[i].matches = QuizElementCategoryMatch.no;
      }
    }
  }
}

class Quiz {
  Quiz({required this.answer});

  QuizElement answer;
  List<QuizElement> guesses = [];
  bool completed = false;
}

class AsyncProvider with ChangeNotifier {
  static const String _dailyProgressKey = 'dailyQuizProgress';

  List<QuizElement> quizElements = [];
  Quiz? dailyQuiz;
  bool isLoading = true;
  bool isInitialized = false;

  Future<void> loadQuizElements() async {
    isLoading = true;
    notifyListeners();

    try {
      final csvContents = await rootBundle.loadString(
        'assets/data/quiz_elements.csv',
      );
      final rows = csv.decode(csvContents);

      if (rows.isEmpty) {
        throw const FormatException('Quiz elements CSV is empty.');
      }

      final headers = rows.first
          .map((header) => header.toString().trim().toLowerCase())
          .toList();

      final parsedElements = <QuizElement>[];
      for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        if (row.length != headers.length) {
          throw FormatException(
            'Quiz elements CSV row ${rowIndex + 1} has ${row.length} '
            'columns; expected ${headers.length}.',
          );
        }
        final values = <String, String>{
          for (var columnIndex = 0; columnIndex < headers.length; columnIndex++)
            headers[columnIndex]: row[columnIndex].toString().trim(),
        };

        String requiredValue(String column) {
          final value = values[column]!;
          if (value.isEmpty) {
            throw FormatException(
              'Quiz elements CSV row ${rowIndex + 1} has an empty $column.',
            );
          }
          return value;
        }

        List<String> listValues(String column) {
          final items = requiredValue(column)
              .split('|')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
          if (items.isEmpty) {
            throw FormatException(
              'Quiz elements CSV row ${rowIndex + 1} has no $column values.',
            );
          }
          return items;
        }

        T enumValue<T extends Enum>(String column, List<T> values) {
          final value = requiredValue(column).toLowerCase();
          for (final candidate in values) {
            if (candidate.name == value) {
              return candidate;
            }
          }
          throw FormatException(
            'Quiz elements CSV row ${rowIndex + 1} has an invalid $column: '
            '$value.',
          );
        }

        final yearText = requiredValue('year');
        final year = int.tryParse(yearText);

        parsedElements.add(
          QuizElement(
            imagePath: "assets/images/${requiredValue('image')}",
            name: requiredValue('name'),
            gender: enumValue('gender', Gender.values),
            hairColor: requiredValue('hair'),
            eyeColor: requiredValue('eye'),
            developers: listValues('developers')
                .map(
                  (value) => _enumValueFromString(
                    value,
                    Developer.values,
                    'developers',
                    rowIndex,
                  ),
                )
                .toList(),
            games: listValues('games'),
            year: year,
            engine: listValues('engine')
                .map(
                  (value) => _enumValueFromString(
                    value,
                    Engine.values,
                    'engine',
                    rowIndex,
                  ),
                )
                .toList(),
            genres: listValues('genres')
                .map(
                  (value) => _enumValueFromString(
                    value,
                    Genre.values,
                    'genres',
                    rowIndex,
                  ),
                )
                .toList(),
          ),
        );
      }

      if (parsedElements.isEmpty) {
        throw const FormatException('Quiz elements CSV has no data rows.');
      }

      parsedElements.sort((a, b) => a.name.compareTo(b.name));

      quizElements = parsedElements;
      isInitialized = true;
      dailyQuiz = await _loadDailyQuiz();
    } finally {
      isLoading = false;
      isInitialized = true;
      notifyListeners();
    }
  }

  T _enumValueFromString<T extends Enum>(
    String value,
    List<T> candidates,
    String column,
    int rowIndex,
  ) {
    for (final candidate in candidates) {
      if (candidate.name == value.toLowerCase()) {
        return candidate;
      }
    }
    throw FormatException(
      'Quiz elements CSV row ${rowIndex + 1} has an invalid $column: $value.',
    );
  }

  Quiz createQuiz(bool isDaily) {
    if (!isInitialized) {
      throw StateError('Quiz elements have not been loaded yet.');
    }

    final random = isDaily
        ? Random(
            DateTime.now().year * 10000 +
                DateTime.now().month * 100 +
                DateTime.now().day,
          )
        : Random();

    QuizElement answer = quizElements[random.nextInt(quizElements.length)];
    return Quiz(answer: answer);
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<Quiz> _loadDailyQuiz() async {
    final preferences = await SharedPreferences.getInstance();
    final savedProgress = preferences.getString(_dailyProgressKey);
    if (savedProgress != null) {
      final decoded = jsonDecode(savedProgress);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Saved daily quiz progress is invalid.');
      }

      if (decoded['date'] == _todayKey()) {
        final answerName = decoded['answer'];
        if (answerName is! String) {
          throw const FormatException('Saved daily quiz answer is invalid.');
        }
        final answer = quizElements.where((item) => item.name == answerName);
        if (answer.isEmpty) {
          throw FormatException(
            'Saved daily quiz answer "$answerName" is not in the quiz data.',
          );
        }

        final quiz = Quiz(answer: answer.first);
        final savedGuesses = decoded['guesses'];
        if (savedGuesses is! List) {
          throw const FormatException('Saved daily quiz guesses are invalid.');
        }
        for (final name in savedGuesses) {
          if (name is! String) {
            throw const FormatException(
              'Saved daily quiz contains an invalid guess.',
            );
          }
          final guessedElement = quizElements.where(
            (item) => item.name == name,
          );
          if (guessedElement.isEmpty) {
            throw FormatException(
              'Saved daily guess "$name" is not in the quiz data.',
            );
          }
          guess(quiz, guessedElement.first);
        }
        if (decoded['completed'] == true) {
          quiz.completed = true;
          guess(quiz, quiz.answer);
        }
        return quiz;
      }
    }

    final quiz = createQuiz(true);
    await _saveDailyQuiz(quiz);
    return quiz;
  }

  Future<void> _saveDailyQuiz(Quiz quiz) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _dailyProgressKey,
      jsonEncode({
        'date': _todayKey(),
        'answer': quiz.answer.name,
        'guesses': quiz.guesses.map((element) => element.name).toList(),
        'completed': quiz.completed,
      }),
    );
    if (!saved) {
      throw StateError('Could not save daily quiz progress.');
    }
  }

  Future<void> submitGuess(
    Quiz quiz,
    QuizElement selected, {
    required bool isDaily,
  }) async {
    guess(quiz, selected);
    if (isDaily) {
      await _saveDailyQuiz(quiz);
    }
  }

  void guess(Quiz quiz, QuizElement guess) {
    if (quiz.answer == guess) {
      quiz.completed = true;
    } else {
      quiz.guesses.add(guess);
    }

    guess.updateMatches(quiz.answer);
  }
}
