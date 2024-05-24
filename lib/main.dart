import 'package:desktest/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollama/ollama.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final darkProvider = StateProvider<bool>((ref) => true);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Ollama ollama = Ollama();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AssistMe',
      theme: ref.watch(darkProvider) ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(
        ollama: ollama,
      ),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  final Ollama ollama;
  HomePage({super.key, required this.ollama});

  int selectedModel = 1;
  List<String> models = ['llama2', 'gemma:2b'];
  Stream message = Ollama().generate("Hello World!", model: 'gemma:2b');
  List<String> questions = [];
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    TextEditingController textController = TextEditingController();
    Ollama ollama = widget.ollama;
    List<String> messages = [];
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: TextButton(
          child: const Text('Chat'),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  ollama: ollama,
                ),
              ),
            );
          },
        ),
        actions: [
          Switch(
              value: ref.watch(darkProvider),
              onChanged: (value) =>
                  ref.read(darkProvider.notifier).state = value),
          const Text('Model: '),
          DropdownMenu(
            initialSelection: 1,
            onSelected: (value) {
              setState(() {
                widget.selectedModel = widget.models.indexOf(
                    value != null ? widget.models[value] : widget.models[0]);
              });
            },
            dropdownMenuEntries: [
              DropdownMenuEntry(value: 0, label: widget.models[0]),
              DropdownMenuEntry(value: 1, label: widget.models[1]),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: widget.message,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Display the chat messages
                  String data = snapshot.data.toString();

                  messages.add(data);
                  print(messages);
                  return Center(
                    child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: ref.watch(darkProvider)
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.all(16.0),
                        child: SelectableText(
                          cursorColor: Colors.green,
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: messages.join('')));
                          },
                          messages.join('') == ''
                              ? 'Type a message...'
                              : messages.join(''),
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                            color: ref.watch(darkProvider)
                                ? Colors.white
                                : Colors.black,
                            //backgroundColor: Colors.white,
                            decoration: TextDecoration.none,
                            decorationColor: Colors.black,
                            decorationStyle: TextDecorationStyle.solid,
                            decorationThickness: 1.0,
                            letterSpacing: 0.0,
                            wordSpacing: 0.0,
                            height: 1.2,
                            locale: Locale('en', 'US'),
                          ),
                        )),
                  );
                } else if (snapshot.hasError) {
                  // Display an error message
                  return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Please Connect to Ollama and Try Again.',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                                color: Colors.black,
                                backgroundColor: Colors.white,
                                decoration: TextDecoration.none,
                                decorationColor: Colors.black,
                                decorationStyle: TextDecorationStyle.solid,
                                decorationThickness: 1.0,
                                letterSpacing: 0.0,
                                wordSpacing: 0.0,
                                height: 1.0,
                                locale: Locale('en', 'US'),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                                color: Colors.black,
                                backgroundColor: Colors.white,
                                decoration: TextDecoration.none,
                                decorationColor: Colors.black,
                                decorationStyle: TextDecorationStyle.solid,
                                decorationThickness: 1.0,
                                letterSpacing: 0.0,
                                wordSpacing: 0.0,
                                height: 1.0,
                                locale: Locale('en', 'US'),
                              ),
                            ),
                          ],
                        ),
                      ));
                } else {
                  // Display a loading indicator
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Send the message
                    setState(() {
                      widget.questions.add(textController.text);
                      widget.message = ollama.generate(textController.text,
                          model: widget.models[widget.selectedModel]);
                    });

                    textController.clear();
                  },
                ),
              ),
              onSubmitted: (value) {
                // Send the message
                setState(() {
                  widget.questions.add(textController.text);
                  widget.message = ollama.generate(textController.text,
                      model: widget.models[widget.selectedModel]);
                });

                textController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}
