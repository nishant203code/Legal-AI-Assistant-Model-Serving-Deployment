// Import Dart core libraries
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

// Flutter and third-party packages
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

// Provider class to manage chat state and interaction logic
class LegalChatProvider extends ChangeNotifier {
  final ChatUser currentUser = ChatUser(id: "1", firstName: "You");
  final ChatUser gptUser = ChatUser(id: "2", firstName: "AI Counsellor");

  // Theme management
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  List<ChatMessage> messages = [];  // List to store chat messages

  /// Picks a PDF file, extracts text, and sends it to the API.
  Future<void> pickFile(String baseUrl, String dir, String ques) async {
    try {
      // Open file picker and allow only PDF files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path!;
        final fileName = file.name;

        // Extract text from the PDF using Syncfusion
        final pdfBytes = File(filePath).readAsBytesSync();
        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        final String pdfText = PdfTextExtractor(document).extractText();
        document.dispose();

        print("📄 Extracted PDF Text:\n$pdfText");

        // Send extracted text to the backend API
        final uri = Uri.parse("$baseUrl/set-judgment");
        final response = await http.post(
          uri,
          headers: {
            "Content-Type": "application/json",
            "skip_zrok_interstitial": "1",
          },
          body: jsonEncode({'judgment_text': pdfText}),
        );

        if (response.statusCode == 200) {
          // Show file upload message in chat
          messages.insert(
            0,
            ChatMessage(
              user: currentUser,
              createdAt: DateTime.now(),
              text: "📎 Uploaded file: **$fileName**",
            ),
          );
          notifyListeners();
          print("✅ File text uploaded successfully");
        } else {
          print("❌ Upload failed: ${response.statusCode}");
        }
      }
    } catch (e) {
      print("File pick error: $e");
    }
  }

  /// Sends a message to a backend URL using form-urlencoded body (used with query-like requests)
  Future<void> sendMessage_url(ChatMessage m, String baseUrl, String dir,
      String ques, String filetype) async {
    messages.insert(0, m);
    notifyListeners();

    // Add a typing indicator from AI
    final typing = ChatMessage(
      user: gptUser,
      createdAt: DateTime.now(),
      text: "",
      customProperties: {"typing": true},
    );
    messages.insert(0, typing);
    notifyListeners();

    try {
      final uri = Uri.parse('$baseUrl/$dir');
      print('📨 Sending to: $uri');
      print('📝 Prompt: ${m.text}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'prompt': m.text,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get response: ${response.statusCode}');
      } else {
        print("✅ Request successful");
      }

      final responseBody = jsonDecode(response.body);
      print("📥 Response Body: $responseBody");

      final reply = responseBody['answer'] ??
          responseBody['response'] ??
          responseBody['result'] ??
          'No response received';

      // Remove typing indicator and show the reply
      messages.removeWhere((msg) => msg.customProperties?["typing"] == true);
      messages.insert(
        0,
        ChatMessage(user: gptUser, createdAt: DateTime.now(), text: reply),
      );
      notifyListeners();
    } catch (e) {
      print("❌ Error: $e");
      messages.removeWhere((msg) => msg.customProperties?["typing"] == true);
      messages.insert(
        0,
        ChatMessage(
          user: gptUser,
          createdAt: DateTime.now(),
          text: "Sorry, I couldn't process your request.",
        ),
      );
      notifyListeners();
    }
  }

  /// Sends a message to a backend URL using JSON body (used for legal text summary)
  Future<void> sendMessage(ChatMessage m, String baseUrl, String dir,
      String ques, String filetype) async {
    messages.insert(0, m);
    notifyListeners();

    print("hooray\n");

    // Add a typing indicator from AI
    final typing = ChatMessage(
      user: gptUser,
      createdAt: DateTime.now(),
      text: "",
      customProperties: {"typing": true},
    );
    messages.insert(0, typing);
    notifyListeners();

    try {
      final uri = Uri.parse('$baseUrl/$dir');
      print('📨 Sending to: $uri');
      print('📝 Prompt: ${m.text}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          "skip_zrok_interstitial": "1"
        },
        body: jsonEncode({'judgment_text': m.text}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get response: ${response.statusCode}');
      } else {
        print("✅ Request successful");
      }

      final responseBody = jsonDecode(response.body);
      print("📥 Response Body: $responseBody");

      final reply = responseBody['answer'] ??
          responseBody['response'] ??
          responseBody['result'] ??
          'No response received';

      // Remove typing indicator and show the reply
      messages.removeWhere((msg) => msg.customProperties?["typing"] == true);
      messages.insert(
        0,
        ChatMessage(user: gptUser, createdAt: DateTime.now(), text: reply),
      );
      notifyListeners();
    } catch (e) {
      print("❌ Error: $e");
      messages.removeWhere((msg) => msg.customProperties?["typing"] == true);
      messages.insert(
        0,
        ChatMessage(
          user: gptUser,
          createdAt: DateTime.now(),
          text: "Sorry, I couldn't process your request.",
        ),
      );
      notifyListeners();
    }
  }
}

/// Custom painter for drawing subtle animated wave background (used for visual aesthetics)
class WaveBackground extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05) // Faint white color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // Draw sinusoidal wave lines across the screen vertically
    for (var i = 0; i < height; i += 50) {
      path.reset();
      path.moveTo(0, i.toDouble());
      for (var x = 0; x < width; x += 20) {
        path.lineTo(
          x.toDouble(),
          i + math.sin(x * 0.03) * 20,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
