import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ApplyCertificateScreen extends StatefulWidget {
  const ApplyCertificateScreen({super.key});

  @override
  _ApplyCertificateScreenState createState() => _ApplyCertificateScreenState();
}

class _ApplyCertificateScreenState extends State<ApplyCertificateScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> messages = [];
  String? userId;
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;

  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadChatHistory();
    _speech = stt.SpeechToText();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  Future<void> _loadChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? chatHistory = prefs.getString('chat_history');
    if (chatHistory != null) {
      setState(() {
        messages = List<Map<String, String>>.from(json.decode(chatHistory));
      });
    }
    _scrollToBottom();
  }

  Future<void> _saveChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', json.encode(messages));
  }

  // Speech to text methods
  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) => print('Error: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _messageController.text = result.recognizedWords;
            });
          },
          localeId: 'en_US', // Set to English
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || userId == null) return;
    String messageText = _messageController.text.trim();
    setState(() {
      messages.add({"sender": "user", "message": messageText});
      isLoading = true;
    });
    _messageController.clear();
    _saveChatHistory();
    _scrollToBottom();

    var response = await http.post(
      Uri.parse('http://127.0.0.1:5500/sample_chat/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": userId, "message": messageText}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        messages.add({"sender": "bot", "message": data['response']});
        isLoading = false;
      });
      _saveChatHistory();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Application Chatbot'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                bool isUser = messages[index]['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.green[400],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft:
                            isUser ? const Radius.circular(12) : Radius.zero,
                        bottomRight:
                            isUser ? Radius.zero : const Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      messages[index]['message']!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isListening ? Colors.red : Colors.grey,
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white),
                    onPressed: _listen,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
