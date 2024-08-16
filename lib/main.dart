import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
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
      home: GameMenuScreen(),
    );
  }
}

class GameMenuScreen extends StatefulWidget {
  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  String? selectedContinent;
  int? numRandomCountries; // Start with null

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capitals Quiz'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select a Continent:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            _buildContinentButton('All', 'All'),
            _buildContinentButton('Africa', 'Africa'),
            _buildContinentButton('Asia', 'Asia'),
            _buildContinentButton('Europe', 'Europe'),
            _buildContinentButton('North America', 'North America'),
            _buildContinentButton('South America', 'South America'),
            _buildContinentButton('Random', 'Random'),
            SizedBox(height: 20),
            if (selectedContinent == 'Random')
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Number of Countries',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      numRandomCountries = int.tryParse(value);
                    });
                  },
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedContinent != null &&
                      (selectedContinent != 'Random' ||
                          (numRandomCountries != null &&
                              numRandomCountries! > 0))
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CapitalsQuizScreen(
                            continent: selectedContinent,
                            numRandomCountries: numRandomCountries,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text('Start Quiz', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinentButton(String continent, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 30),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedContinent = continent;
            // Reset numRandomCountries when a new continent is selected
            if (continent != 'Random') {
              numRandomCountries = null; 
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedContinent == continent
              ? Colors.blue
              : Colors.black,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
        ),
        child: Text(label, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class CapitalsQuizScreen extends StatefulWidget {
  final String? continent;
  final int? numRandomCountries;

  CapitalsQuizScreen({this.continent, this.numRandomCountries});

  @override
  _CapitalsQuizScreenState createState() => _CapitalsQuizScreenState();
}

class _CapitalsQuizScreenState extends State<CapitalsQuizScreen> {
  List<Map<String, dynamic>> countriesData = [];
  List<Map<String, dynamic>> questions = [];
  int currentQuestion = 0;
  int correctAnswers = 0;
  List<bool> isAnswered = [];

  @override
  void initState() {
    super.initState();
    _loadCountriesData().then((data) {
      setState(() {
        // Filter countriesData based on selectedContinent
        if (widget.continent != null && widget.continent != 'All') {
          countriesData = (data[widget.continent!] as List<dynamic>)
              .cast<Map<String, dynamic>>();
        } else if (widget.continent == 'Random' &&
            widget.numRandomCountries != null) {
          // Null check for numRandomCountries
          countriesData = data.entries
              .map((entry) => entry.value)
              .expand((list) => list)
              .toList()
              .cast<Map<String, dynamic>>()
            ..shuffle(Random());
          countriesData =
              countriesData.sublist(0, widget.numRandomCountries!);
        } else {
          countriesData = data.entries
              .map((entry) => entry.value)
              .expand((list) => list)
              .toList()
              .cast<Map<String, dynamic>>();
        }
        _generateQuestions();
      });
    });
  }

  Future<Map<String, dynamic>> _loadCountriesData() async {
    String jsonString = await rootBundle.loadString('assets/countries.json');
    Map<String, dynamic> data = json.decode(jsonString);
    return data;
  }

  void _generateQuestions() {
  countriesData.shuffle(Random());

  questions = [];
  isAnswered = List.filled(
      countriesData.length * 4, false); // Adjust isAnswered length

  // Generate questions for ALL countries in the chosen continent
  for (int i = 0; i < countriesData.length; i++) { 
    Map<String, dynamic> countryData = countriesData[i];
    String correctCapital = countryData['capital'];
    List<String> answers = [correctCapital];

    while (answers.length < 4) {
      String randomCapital =
          countriesData[Random().nextInt(countriesData.length)]['capital'];
      if (!answers.contains(randomCapital)) {
        answers.add(randomCapital);
      }
    }

    answers.shuffle(Random());

    questions.add({
      'country': countryData['country'],
      'answers': answers,
      'correctAnswer': correctCapital,
    });
  }
}


  void _checkAnswer(String selectedAnswer) {
    int buttonIndex =
        questions[currentQuestion]['answers'].indexOf(selectedAnswer);

    setState(() {
      if (buttonIndex != -1) {
        int flatIndex = currentQuestion * 4 + buttonIndex;
        isAnswered[flatIndex] = true;

        if (questions[currentQuestion]['correctAnswer'] == selectedAnswer) {
          correctAnswers++;
        }
      }
    });

    Future.delayed(Duration(milliseconds: 500), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultsDialog();
      });
    }
  }

    void _showResultsDialog() {
    setState(() {
      currentQuestion = 0;
      correctAnswers = 0;
      _generateQuestions(); // Generate questions HERE!
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Well Done!'),
        content: Text('You got $correctAnswers/${questions.length} correct!'), // Now uses the updated length
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => GameMenuScreen()),
                (route) => false,
              );
            },
            child: Text('Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // No need to call _generateQuestions() here again
            },
            child: Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capitals Quiz'),
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
                      final buttonIndex = currentQuestion * 4 + index;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: !isAnswered[buttonIndex]
                            ? ElevatedButton(
                                key: ValueKey<int>(buttonIndex),
                                onPressed: () {
                                  _checkAnswer(questions[currentQuestion]
                                      ['answers'][index]);
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                ),
                                child: Center(
                                  child: Text(questions[currentQuestion]
                                      ['answers'][index]),
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: Icon(
                                  questions[currentQuestion]['correctAnswer'] ==
                                          questions[currentQuestion]['answers']
                                              [index]
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 40,
                                  color: questions[currentQuestion]
                                              ['correctAnswer'] ==
                                          questions[currentQuestion]['answers']
                                              [index]
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}