import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complaint Chat System',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ComplaintScreen(),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigo.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
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
          message['text']!,
          style: TextStyle(
            fontSize: 16,
            color: isUser ? Colors.indigo.shade900 : Colors.black87,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  _ComplaintScreenState createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _userId;
  Map<String, dynamic> _sessionData = {};

  late stt.SpeechToText _speech;
  bool _isListening = false;
  final _translator = GoogleTranslator();
  bool _isTranslating = false;
  String _selectedLanguage = 'en_US';

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _initializeSpeech();
  }

  bool _isMalayalamText(String text) {
    final malayalamRegex = RegExp(r'[\u0D00-\u0D7F]');
    return malayalamRegex.hasMatch(text);
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => print('Error: $error'),
    );
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ??
          DateTime.now().millisecondsSinceEpoch.toString();
      prefs.setString('user_id', _userId!);
    });
  }

  Future<String?> _translateText(String text) async {
    setState(() => _isTranslating = true);
    try {
      final translation = await _translator.translate(
        text,
        from: 'ml',
        to: 'en',
      );
      setState(() => _isTranslating = false);
      return translation.text;
    } catch (e) {
      setState(() => _isTranslating = false);
      return null;
    }
  }

  Future<void> _sendMessage() async {
    if (_isLoading || _userId == null) return;

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    String messageToSend = message;

    if (_selectedLanguage == 'ml_IN' && _isMalayalamText(message)) {
      final translatedText = await _translateText(message);
      if (translatedText == null) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Translation failed. Please try again.',
            'timestamp': DateTime.now().toIso8601String(),
          });
        });
        return;
      }
      messageToSend = translatedText;
    }

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    await _sendToServer(messageToSend);
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendToServer(String message) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5500/complaint_bot/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'message': message,
          'session_data': _sessionData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['session_data'] != null) {
          _sessionData = Map<String, dynamic>.from(data['session_data']);
        }

        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': data['response'],
            'timestamp': DateTime.now().toIso8601String(),
          });
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Error: Failed to get response',
            'timestamp': DateTime.now().toIso8601String(),
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Connection error: $e',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool initialized = await _speech.initialize();
      if (initialized) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) async {
            if (result.finalResult) {
              final recognizedText = result.recognizedWords;
              setState(() {
                _messageController.text = recognizedText;
                _isListening = false;
              });
            }
          },
          localeId: _selectedLanguage,
          cancelOnError: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
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
              _messageController.clear();
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
          controller: _messageController,
          decoration: InputDecoration(
            hintText: _selectedLanguage == 'ml_IN'
                ? 'മലയാളത്തിൽ ടൈപ്പ് ചെയ്യുക...'
                : 'Type your message...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _sendMessage(),
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
          onPressed: _startListening,
        ),
        IconButton(
          icon: Icon(Icons.send, color: Colors.indigo.shade700),
          onPressed: _sendMessage,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Chat System'),
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
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageBubble(
                    message: message,
                    isUser: message['sender'] == 'user',
                  );
                },
              ),
            ),
            if (_isLoading || _isTranslating)
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
                      _isTranslating ? 'Translating...' : 'Bot is typing...',
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
