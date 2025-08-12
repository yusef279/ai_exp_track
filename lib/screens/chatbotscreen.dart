import 'dart:async';
import 'dart:convert';
import 'package:ai_exp_track/models/chatmessage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final String apiKey = 'AIzaSyBPYanfCOPpcBXrOmUYJf9RXLDHuBwaQ9w'; // Replace with safe backend key

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(role: "user", text: userMessage, sender: "You"));
      _isTyping = true;
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey',
    );

    final history = _messages
    .take(_messages.length) 
    .toList()
    .sublist(_messages.length > 10 ? _messages.length - 10 : 0)
    .map((msg) => {
          "role": msg.role,
          "parts": [
            {"text": msg.text}
          ]
        })
    .toList();


    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "systemInstruction": {
            "role": "system",
            "parts": [
              {"text": "You are CashCoach, a personal finance & budgeting assistant inside an expense-tracking app. Help everyday users understand spending, save money, reduce waste, and stick to a budget. Give specific, bite-sized actions users can take today. give practical, actionable advice. Keep responses concise and focused on the user's current question."}
            ]
          },
          "contents": history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";
        await _showStreamingReply(reply);
      } else {
        _addBotMessage("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      _addBotMessage("Network error: $e");
    }

    setState(() => _isTyping = false);
  }

  Future<void> _showStreamingReply(String fullText) async {
    String current = "";
    _messages.add(ChatMessage(role: "model", text: "", sender: "Assistant"));
    final botIndex = _messages.length - 1;

    for (var word in fullText.split(' ')) {
      current += (current.isEmpty ? "" : " ") + word;
      setState(() {
        _messages[botIndex] =
            ChatMessage(role: "model", text: current, sender: "Assistant");
      });
      await Future.delayed(const Duration(milliseconds: 40)); // typing speed
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(role: "model", text: text, sender: "Assistant"));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.indigo[100],
                child: const Icon(Icons.savings, color: Colors.indigo),
              ),
              const SizedBox(width: 10),
              const Text(
                "CashCoach",
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (_isTyping && index == _messages.length) {
                      return const _TypingIndicator();
                    }
                    final msg = _messages[index];
                    final isUser = msg.sender == "You";
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser)
                              CircleAvatar(
                                backgroundColor: Colors.indigo[100],
                                child: const Icon(Icons.savings, color: Colors.indigo),
                                radius: 18,
                              ),
                            if (!isUser) const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Colors.white
                                      : Colors.indigo.withOpacity(0.08),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: isUser ? Colors.black87 : Colors.indigo[900],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (isUser) const SizedBox(width: 8),
                            if (isUser)
                              CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person, color: Colors.black54),
                                radius: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (value) {
                            final v = value.trim();
                            if (v.isNotEmpty) {
                              sendMessage(v);
                              _controller.clear();
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          final v = _controller.text.trim();
                          if (v.isNotEmpty) {
                            sendMessage(v);
                            _controller.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1, _dot2, _dot3;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
          ..repeat();

    _dot1 = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );
    _dot2 = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8)),
    );
    _dot3 = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _dot1.value),
              child: const Text(
                ".",
                style: TextStyle(fontSize: 28, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 2),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _dot2.value),
              child: const Text(
                ".",
                style: TextStyle(fontSize: 28, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 2),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _dot3.value),
              child: const Text(
                ".",
                style: TextStyle(fontSize: 28, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      subtitle: const Text("CashCoach is typing..."),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
