import 'package:desktest/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollama/ollama.dart';
import 'package:ollama/src/models/chat_message.dart';

final messageProvider = StateProvider<List<ChatMessage>>((ref) => [
      ChatMessage(role: 'assistant', content: 'Hello!'),
      ChatMessage(role: 'user', content: 'Hi!')
    ]);

final streamProvider = StreamProvider((ref) => Ollama()
    .chat(ref.watch(messageProvider), model: 'gemma:2b', chunked: false));

class ChatPage extends ConsumerStatefulWidget {
  final Ollama ollama;
  ChatPage({super.key, required this.ollama});

  List<ChatMessage> messages = [
    ChatMessage(role: 'assistant', content: 'Hello!'),
    ChatMessage(role: 'user', content: 'Hi!')
  ];
  Stream chat = Ollama().chat([], model: 'gemma:2b', chunked: false);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  Widget build(BuildContext context) {
    TextEditingController textController = TextEditingController();
    Ollama ollama = widget.ollama;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: TextButton(
          child: const Text('Back'),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(ollama: ollama),
              ),
            );
          },
        ),
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
              child: ref.watch(streamProvider).when(data: (data) {
            print('CusData: ${data.toString()}');
            if (data.toString() != '') {
              ref.read(messageProvider.notifier).state.add(
                  ChatMessage(role: 'assistant', content: data.toString()));
            }

            //print(ref.watch(messageProvider));
            return ListView.builder(
              itemCount: ref.watch(messageProvider).length,
              itemBuilder: (context, index) {
                return MessageBubble(
                  role: ref.watch(messageProvider)[index].role,
                  content: ref.watch(messageProvider)[index].content,
                );
              },
            );
          }, error: (error, stackTrace) {
            return Center(
              child: Text(error.toString()),
            );
          }, loading: () {
            return Center(child: const LinearProgressIndicator());
          })),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ),
              onSubmitted: (value) {
                // Send the message
                ref
                    .read(messageProvider.notifier)
                    .state
                    .add(ChatMessage(role: 'user', content: value));
                setState(() {});
                textController.clear();
                print(ref.read(messageProvider));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String role;
  final String content;
  MessageBubble({required this.role, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment:
            role == 'user' ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          role == 'assistant'
              ? CircleAvatar(
                  child: const Text('A'),
                )
              : Container(),
          const SizedBox(width: 8.0),
          Column(
            crossAxisAlignment: role == 'user'
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: BoxDecoration(
                  color: role == 'assistant' ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
