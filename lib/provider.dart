import 'dart:math';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
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
  shooter('Shooter'),
  gacha('Gacha'),
  idle('Idle');

  const Genre(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

enum QuizElementCategoryMatch {
  no(AppColors.red, "🟥"),
  partial(AppColors.yellow, "🟨"),
  yes(AppColors.green, "🟩");

  const QuizElementCategoryMatch(this.color, this.pastableSquare);

  final Color color;
  final String pastableSquare;
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
    required csvDescription,
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
       ],
       description = (csvDescription == "null" ? null : csvDescription);

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
  final String? description;

  Image get image => Image.asset(imagePath, fit: BoxFit.cover);

  List<QuizElementCategory> categories;

  void updateMatches(QuizElement other) {
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].value is List && other.categories[i].value is List) {
        List<dynamic> list1 = categories[i].value as List<dynamic>;
        List<dynamic> list2 = other.categories[i].value as List<dynamic>;

        final unorderedEq = const UnorderedIterableEquality();

        if (unorderedEq.equals(list1, list2)) {
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

  Icon? getYearDifferenceIcon(int? year) {
    if(this.year == null || year == null) {
      return null;
    }
    
    int diff = year - this.year!;

    if(diff == 0) return null;

    IconData icon;

    if(diff < 0) {
      if(diff == -1) {
        icon = Icons.keyboard_arrow_down;
      }
      else {
        icon = Icons.keyboard_double_arrow_down;
      }
    }
    else {
      if(diff == 1) {
        icon = Icons.keyboard_arrow_up;
      }
      else {
        icon = Icons.keyboard_double_arrow_up;
      }
    }

    return Icon(icon, color: AppColors.primaryColor);
  }

  String getPastable() {
    String pastable = "";

    for(QuizElementCategory cat in categories) {
      pastable += cat.matches.pastableSquare;
    }

    return pastable;
  }
}

class Quiz {
  Quiz({required this.answer, required this.date});

  final DateTime date;

  QuizElement answer;
  List<QuizElement> guesses = [];
  bool completed = false;

  void reroll(List<QuizElement> elements) {
    answer = elements[Random().nextInt(elements.length)];
    guesses.clear();
    completed = false;
  }

  void updateAllMatches() {
    for(QuizElement guess in guesses) {
      guess.updateMatches(answer);
    }
  }

  String getPastable() {
    List<String> pastables = [];

    for(QuizElement guess in guesses) {
      pastables.add(guess.getPastable());
    }
    
    if(completed) {
      pastables.add(answer.getPastable());
    }

    return pastables.reversed.join("\n");
  }
}

class Game {
  const Game({
    required this.developers,
    required this.year,
    required this.engine,
    required this.genres,
  });

  final List<Developer> developers;
  final int year;
  final List<Engine> engine;
  final List<Genre> genres;
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
      final gameContents = await rootBundle.loadString('assets/data/games.csv');
      final gameRows = _decodeCsvRows(gameContents, 'Games');
      final gameByName = <String, Game>{};
      for (var rowIndex = 0; rowIndex < gameRows.length; rowIndex++) {
        final rowNumber = rowIndex + 2;
        final values = gameRows[rowIndex];
        final name = _requiredCsvValue(values, 'name', 'Games', rowNumber);
        if (gameByName.containsKey(name)) {
          throw FormatException(
            'Games CSV row $rowNumber duplicates game "$name".',
          );
        }

        final yearText = _requiredCsvValue(values, 'year', 'Games', rowNumber);
        final year = int.tryParse(yearText);
        if (year == null) {
          throw FormatException(
            'Games CSV row $rowNumber has an invalid year: $yearText.',
          );
        }

        gameByName[name] = Game(
          developers: _csvEnumValues(
            values,
            'developers',
            Developer.values,
            'Games',
            rowNumber,
          ),
          year: year,
          engine: _csvEnumValues(
            values,
            'engine',
            Engine.values,
            'Games',
            rowNumber,
          ),
          genres: _csvEnumValues(
            values,
            'genres',
            Genre.values,
            'Games',
            rowNumber,
          ),
        );
      }

      if (gameByName.isEmpty) {
        throw const FormatException('Games CSV has no data rows.');
      }

      final csvContents = await rootBundle.loadString(
        'assets/data/quiz_elements.csv',
      );
      final rows = _decodeCsvRows(csvContents, 'Quiz elements');
      final parsedElements = <QuizElement>[];
      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final rowNumber = rowIndex + 2;
        final values = rows[rowIndex];
        final gameNames = _csvListValues(
          values,
          'games',
          'Quiz elements',
          rowNumber,
        );
        final associatedGames = gameNames.map((name) {
          final game = gameByName[name];
          if (game == null) {
            throw FormatException(
              'Quiz elements CSV row $rowNumber references unknown game '
              '"$name".',
            );
          }
          return game;
        }).toList();

        parsedElements.add(
          QuizElement(
            imagePath:
                "assets/images/${_requiredCsvValue(values, 'image', 'Quiz elements', rowNumber)}",
            name: _requiredCsvValue(values, 'name', 'Quiz elements', rowNumber),
            gender: _csvEnumValue(
              values,
              'gender',
              Gender.values,
              'Quiz elements',
              rowNumber,
            ),
            hairColor: _requiredCsvValue(
              values,
              'hair',
              'Quiz elements',
              rowNumber,
            ),
            eyeColor: _requiredCsvValue(
              values,
              'eye',
              'Quiz elements',
              rowNumber,
            ),
            developers: associatedGames
                .expand((game) => game.developers)
                .toSet()
                .toList(),
            games: gameNames,
            year: associatedGames
                .map((game) => game.year)
                .reduce((a, b) => a < b ? a : b),
            engine: associatedGames
                .expand((game) => game.engine)
                .toSet()
                .toList(),
            genres: associatedGames
                .expand((game) => game.genres)
                .toSet()
                .toList(),
            csvDescription: _requiredCsvValue(values, 'description', 'Quiz elements', rowNumber)
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

  List<Map<String, String>> _decodeCsvRows(String contents, String source) {
    final rows = csv.decode(contents);
    if (rows.isEmpty) {
      throw FormatException('$source CSV is empty.');
    }

    final headers = rows.first
        .map((header) => header.toString().trim().toLowerCase())
        .toList();
    final decodedRows = <Map<String, String>>[];
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.length != headers.length) {
        throw FormatException(
          '$source CSV row ${rowIndex + 1} has ${row.length} columns; '
          'expected ${headers.length}.',
        );
      }
      decodedRows.add({
        for (var columnIndex = 0; columnIndex < headers.length; columnIndex++)
          headers[columnIndex]: row[columnIndex].toString().trim(),
      });
    }
    return decodedRows;
  }

  String _requiredCsvValue(
    Map<String, String> values,
    String column,
    String source,
    int rowNumber,
  ) {
    final value = values[column];
    if (value == null || value.isEmpty) {
      throw FormatException('$source CSV row $rowNumber has an empty $column.');
    }
    return value;
  }

  List<String> _csvListValues(
    Map<String, String> values,
    String column,
    String source,
    int rowNumber,
  ) {
    final items = _requiredCsvValue(values, column, source, rowNumber)
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (items.isEmpty) {
      throw FormatException(
        '$source CSV row $rowNumber has no $column values.',
      );
    }
    return items;
  }

  List<T> _csvEnumValues<T extends Enum>(
    Map<String, String> values,
    String column,
    List<T> candidates,
    String source,
    int rowNumber,
  ) => _csvListValues(values, column, source, rowNumber)
      .map(
        (value) => _csvEnumValueFromString(
          value,
          candidates,
          column,
          source,
          rowNumber,
        ),
      )
      .toList();

  T _csvEnumValue<T extends Enum>(
    Map<String, String> values,
    String column,
    List<T> candidates,
    String source,
    int rowNumber,
  ) => _csvEnumValueFromString(
    _requiredCsvValue(values, column, source, rowNumber),
    candidates,
    column,
    source,
    rowNumber,
  );

  T _csvEnumValueFromString<T extends Enum>(
    String value,
    List<T> candidates,
    String column,
    String source,
    int rowNumber,
  ) {
    for (final candidate in candidates) {
      if (candidate.name == value.toLowerCase()) {
        return candidate;
      }
    }
    throw FormatException(
      '$source CSV row $rowNumber has an invalid $column: $value.',
    );
  }

  QuizElement getTimeAnswer(DateTime time) {
    final random = Random(time.year * 10000 + time.month * 100 + time.day);
    return quizElements[random.nextInt(quizElements.length)];
  }

  Quiz createQuiz(bool isDaily) {
    if (!isInitialized) {
      throw StateError('Quiz elements have not been loaded yet.');
    }

    QuizElement answer = isDaily
      ? getTimeAnswer(DateTime.now())
      : quizElements[Random().nextInt(quizElements.length)];
    
    return Quiz(answer: answer, date: DateTime.now());
  }

  QuizElement getYesterdayAnswer() {
    if (!isInitialized) {
      throw StateError('Quiz elements have not been loaded yet.');
    }

    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));

    return getTimeAnswer(yesterday);
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

        final quiz = Quiz(answer: answer.first, date: DateTime.now());
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
