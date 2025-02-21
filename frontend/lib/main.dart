import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/src/response.dart';
import 'package:provider/provider.dart';
import 'package:frontend/pages/root.dart';


void main() {
  runApp(const Frontend());
}

class Frontend extends StatelessWidget {
  const Frontend({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FrontendState(),
      child: MaterialApp(
        title: 'Uillem',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
          fontFamily: 'Raleway',
          useMaterial3: true,
        ),
        home: Root(),
      ),
    );
  }
}

class FrontendState extends ChangeNotifier {
  static const enablePrompt = bool.fromEnvironment('ENABLE_PROMPT',
    defaultValue: true);
  static const enablePresets = bool.fromEnvironment('ENABLE_PRESETS',
    defaultValue: true);

  final TextEditingController promptController = TextEditingController();
  var cache = Map();
  var isPrompting = false;
  var paragraphs = [];

  final TextEditingController batchSizeController = TextEditingController(text: '2048');
  final TextEditingController contextSizeController = TextEditingController(text: '4096');

  getPromptResult(String prompt) async {
    if (cache.containsKey(prompt)) {
      paragraphs = cache[prompt];
      notifyListeners();
      return;
    }

    if (isPrompting) return;
    isPrompting = true;
    paragraphs = [];
    notifyListeners();

    // Configure request args (prompt required)
    var args = {'p': prompt};
    if (batchSizeController.text.length > 0) {
      args['batch_size'] = batchSizeController.text;
    }
    if (contextSizeController.text.length > 0) {
      args['ctx_size'] = contextSizeController.text;
    }

    var url = Uri.http(
      'localhost:8088',
      'prompt',
      args,
    );

    var response = Response('', 400);
    try {
      response = await http.get(url);
    } on Exception catch (e) {
      print('Server call failed');
      print(e);
      isPrompting = false;
      notifyListeners();
    }

    if (response.statusCode == 200) {
      paragraphs = response.body.split(RegExp(r'\r?\n'));
      cache[prompt] = paragraphs;
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }

    isPrompting = false;
    notifyListeners();
  }
}
