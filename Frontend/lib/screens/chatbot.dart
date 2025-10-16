import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _queryController = TextEditingController();
  List<dynamic> _chatHistory = [];
  String? _sessionId;
  final ScrollController _scrollController = ScrollController();

  // Speech-to-Text variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _selectedLanguage = 'en_US'; // Default language is English
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _initializeSpeechRecognition();
  }

  Future<void> _initializeSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('session_id');

    if (sessionId == null) {
      sessionId = const Uuid().v4();
      await prefs.setString('session_id', sessionId);
    }

    setState(() {
      _sessionId = sessionId;
    });

    await fetchChatHistory();
  }

  Future<void> _initializeSpeechRecognition() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  Future<void> _startListening(String languageCode) async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);

      try {
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _queryController.text = result.recognizedWords;
            });
          },
          localeId: languageCode,
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
        );
      } catch (e) {
        print('Speech recognition error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isListening = false);
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> sendQuery() async {
    if (_queryController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('http://127.0.0.1:5500/sample/ask_pdf');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': _queryController.text,
          'session_id': _sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _chatHistory.addAll([
            {'role': 'human', 'content': _queryController.text},
            {'role': 'ai', 'content': data['answer']},
          ]);
          _queryController.clear();
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({
          'role': 'error',
          'content': 'Failed to fetch response. Please try again.',
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchChatHistory() async {
    if (_sessionId == null) return;

    final url = Uri.parse('http://127.0.0.1:5500/get_chat_history');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': _sessionId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _chatHistory = data['history'];
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error fetching chat history: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatBubble(String content, bool isHuman) {
    return Align(
      alignment: isHuman ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isHuman ? Colors.indigo.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isHuman ? const Radius.circular(20) : Radius.zero,
            bottomRight: isHuman ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: isHuman ? Colors.indigo.shade900 : Colors.black87,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          icon: Icon(Icons.language, color: Colors.indigo.shade700, size: 20),
          elevation: 4,
          style: TextStyle(
            color: Colors.indigo.shade900,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLanguage = newValue!;
              _queryController.clear();
            });
          },
          items: [
            DropdownMenuItem(
              value: 'en_US',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇺🇸'),
                  const SizedBox(width: 8),
                  Text('English',
                      style: TextStyle(color: Colors.indigo.shade900)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'ml_IN',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇮🇳'),
                  const SizedBox(width: 8),
                  Text('Malayalam',
                      style: TextStyle(color: Colors.indigo.shade900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.indigo.shade200),
        ),
        child: TextField(
          controller: _queryController,
          decoration: InputDecoration(
            hintText: _selectedLanguage == 'ml_IN'
                ? 'മലയാളത്തിൽ ടൈപ്പ് ചെയ്യുക...'
                : 'Type your message...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: InputBorder.none,
          ),
          onSubmitted: (_) => sendQuery(),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.red : Colors.indigo.shade700,
          ),
          onPressed: () => _startListening(_selectedLanguage),
        ),
        IconButton(
          icon: Icon(Icons.send, color: Colors.indigo.shade700),
          onPressed: sendQuery,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sankalp Chatbot'),
        backgroundColor: Colors.indigo.shade700,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          image: DecorationImage(
            image: const NetworkImage(
              'https://example.com/chat-background.png', // Add your background image URL
            ),
            opacity: 0.1,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final message = _chatHistory[index];
                  final isHuman = message['role'] == 'human';
                  return _buildChatBubble(message['content'], isHuman);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.indigo.shade700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bot is typing...',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    _buildLanguageSelector(),
                    _buildInputField(),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _speech.stop();
    _scrollController.dispose();
    super.dispose();
  }
}
