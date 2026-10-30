import 'package:flutter/services.dart';
import 'package:legalai/legal_chat_provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The main chat interface widget for the legal chatbot.
/// Allows file uploads, sends messages, and handles AI responses.
class LegalChatPage extends StatefulWidget {
  final String heading;      // Title shown in the AppBar
  final bool clear;          // Whether to clear previous messages
  final String baseUrl;      // API base URL
  final String direc;        // API endpoint
  final String ques;         // Optional: any preset prompt or query
  final String filetype;     // Used in content-type header

  const LegalChatPage({
    super.key,
    required this.heading,
    this.clear = false,
    this.baseUrl = "",
    this.direc = "",
    this.ques = "",
    this.filetype = 'json',
  });

  @override
  State<LegalChatPage> createState() => _LegalChatPageState();
}

/// A simple widget to animate three dots (...) during AI "typing"
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(); // Repeat forever

    _dotAnimation = IntTween(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        String dots = '.' * (_dotAnimation.value + 1);
        return Text(dots, style: const TextStyle(fontSize: 24));
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _LegalChatPageState extends State<LegalChatPage> {
  late final LegalChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<LegalChatProvider>(context, listen: false);
    if (widget.clear) {
      _chatProvider.messages.clear(); // Clear previous messages if flag is true
    }
  }

  /// Parses bold `**text**` and optional headers `* **text**` into styled spans
  TextSpan _headstyleText(String text) {
    final spans = <TextSpan>[];
    int start = 0;

    final regex = RegExp(r'(\*\s\s\s)?\*\*(.*?)\*\*');

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final isHeader = match.group(1) == null;
      final content = match.group(2)!;

      spans.add(
        TextSpan(
          text: content,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isHeader ? 20 : 15,
          ),
        ),
      );

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<LegalChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.heading),
        backgroundColor: Colors.yellow,
        centerTitle: true,
        titleTextStyle: const TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Stack(
        children: [
          // Custom animated wave background
          Positioned.fill(child: CustomPaint(painter: WaveBackground())),

          // Semi-transparent image overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/image.png',
              fit: BoxFit.cover,
              color: const Color.fromRGBO(255, 255, 255, 0.1),
              colorBlendMode: BlendMode.dstATop,
            ),
          ),

          // Main chat interface
          Column(
            children: [
              Expanded(
                child: DashChat(
                  currentUser: _chatProvider.currentUser,
                  messages: _chatProvider.messages,

                  // Customize user input area
                  inputOptions: InputOptions(
                    inputToolbarPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    inputToolbarStyle: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.yellow,
                          blurRadius: 15,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    inputDecoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 226, 224, 224),
                      hintText: "Type your message...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.grey),
                        onPressed: () {
                          _chatProvider.pickFile(
                              widget.baseUrl, widget.direc, widget.ques);
                        },
                      ),
                    ),
                    inputTextStyle: const TextStyle(color: Colors.black),
                  ),

                  // Customize message appearance
                  messageOptions: MessageOptions(
                    currentUserContainerColor: Colors.yellow,
                    currentUserTextColor: Colors.black,
                    containerColor: Colors.grey.shade200,
                    textColor: Colors.black,
                    messageRowBuilder: (
                      ChatMessage message,
                      ChatMessage? previousMessage,
                      ChatMessage? nextMessage,
                      bool isNextMessageUser,
                      bool isPreviousMessageUser,
                    ) {
                      bool isUser =
                          message.user.id == _chatProvider.currentUser.id;
                      bool isTypingMessage =
                          message.customProperties?["typing"] == true;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width *
                                  (isUser ? 0.75 : 0.95),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.yellow
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: isTypingMessage
                                  ? const TypingDots()
                                  : SelectableText.rich(
                                      _headstyleText(message.text),
                                      style:
                                          const TextStyle(color: Colors.black),
                                      onTap: () {
                                        Clipboard.setData(
                                                ClipboardData(text: message.text))
                                            .then((_) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Text copied to clipboard!'),
                                            ),
                                          );
                                        });
                                      },
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Handle message sending
                  onSend: (ChatMessage m) {
                    if (widget.heading == 'Draft Contract' ||
                        widget.heading == 'Clause Classification') {
                      _chatProvider.sendMessage_url(m, widget.baseUrl,
                          widget.direc, widget.ques, widget.filetype);
                    } else {
                      _chatProvider.sendMessage(m, widget.baseUrl, widget.direc,
                          widget.ques, widget.filetype);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
