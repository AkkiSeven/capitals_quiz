import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> countriesData = [];
  List<Map<String, dynamic>> questions = [];
  int currentQuestion = 0;
  List<bool> isAnswerVisible = [];
  List<IconData?> buttonIcon = [];
  int correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    _loadCountriesData().then((data) {
      setState(() {
        countriesData = data;
        _generateQuestions();
      });
    });
  }

  Future<List<Map<String, dynamic>>> _loadCountriesData() async {
    String jsonString = await rootBundle.loadString('assets/countries.json');
    return List<Map<String, dynamic>>.from(json.decode(jsonString));
  }

  void _generateQuestions() {
    countriesData.shuffle();
    questions = countriesData.sublist(0, 10).map((countryData) {
      List<String> answers = [
        countryData['capital'],
        ...countriesData
            .where((data) => data['capital'] != countryData['capital'])
            .map((data) => data['capital'])
            .toList()
            .sublist(0, 3)
      ]..shuffle();
      return {
        'country': countryData['country'],
        'answers': answers,
        'correctAnswer': countryData['capital']
      };
    }).toList();

    isAnswerVisible = List.filled(questions.length * 4, true);
    buttonIcon = List.filled(questions.length * 4, null);
  }

  void _checkAnswer(String selectedAnswer) {
    int buttonIndex = currentQuestion * 4 +
        (questions[currentQuestion]['answers'].indexOf(selectedAnswer) as int);

    if (questions[currentQuestion]['correctAnswer'] == selectedAnswer) {
      setState(() {
        correctAnswers++;
        buttonIcon[buttonIndex] = Icons.check;
      });
    } else {
      setState(() {
        buttonIcon[buttonIndex] = Icons.close;
      });
    }

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        isAnswerVisible[buttonIndex] = false;
      });
    });
  }

    void _nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      // Use WidgetsBinding.instance.addPostFrameCallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultsDialog();
      });
    }
  }

  void _showResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Well Done!'),
        content: Text(
          'You got $correctAnswers/10 correct!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentQuestion = 0;
                correctAnswers = 0;
                _generateQuestions();
              });
            },
            child: Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(255, 0, 0, 0),
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 20,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Capitals Quiz'),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    questions.isEmpty
                        ? 'Loading questions...'
                        : 'Question ${currentQuestion + 1}/10:\nWhat is the capital of ${questions[currentQuestion]['country']}?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              height: MediaQuery.of(context).size.height / 3,
              child: questions.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: 4,
                      padding: EdgeInsets.all(16.0),
                      itemBuilder: (context, index) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: isAnswerVisible[currentQuestion * 4 + index]
                              ? ElevatedButton(
                                  key: ValueKey<int>(
                                      currentQuestion * 4 + index),
                                  onPressed: () {
                                    _checkAnswer(questions[currentQuestion]
                                        ['answers'][index]);
                                    // NO NEED FOR Future.delayed HERE
                                    _nextQuestion();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                  ),
                                  child: Center(
                                    child: buttonIcon[
                                                currentQuestion * 4 + index] !=
                                            null
                                        ? Icon(
                                            buttonIcon[
                                                currentQuestion * 4 + index],
                                            color: questions[currentQuestion]
                                                        ['answers'][index] ==
                                                    questions[currentQuestion]
                                                        ['correctAnswer']
                                                ? Colors.green
                                                : Colors.red,
                                            size: 30,
                                          )
                                        : Text(questions[currentQuestion]
                                            ['answers'][index]),
                                  ),
                                )
                              : SizedBox.shrink(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
