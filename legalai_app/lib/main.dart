import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // For using custom Google Fonts
import 'package:legalai/legal_chat_provider.dart'; // State management provider for chat logic
import 'package:legalai/homepage.dart'; // The main landing page UI
import 'package:provider/provider.dart'; // State management via Provider

void main() {
  runApp(const LegalAI());
}

// Root widget of the app
class LegalAI extends StatelessWidget {
  const LegalAI({super.key});

  @override
  Widget build(BuildContext context) {
    // Providing the LegalChatProvider to the entire widget tree
    return ChangeNotifierProvider<LegalChatProvider>(
      create: (_) => LegalChatProvider(),
      
      // Listening to changes in LegalChatProvider (especially for theme mode)
      child: Consumer<LegalChatProvider>(
        builder: (context, provider, child) {
          final isDark = provider.isDarkMode; 

          return MaterialApp(
            title: 'LegalAssist',
            debugShowCheckedModeBanner: false, 

            // Sets theme mode based on user preference (dark/light)
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

            // Light theme settings (Google Fonts applied)
            theme: ThemeData.light().copyWith(
              textTheme: GoogleFonts.robotoTextTheme(
                ThemeData.light().textTheme,
              ),
            ),

            // Dark theme settings customized using Material3
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: const ColorScheme.dark(
                primary: Colors.yellow, 
                secondary: Color(0xFFE0E0E0),
                surface: Color(0xFF121212),
              ),
              scaffoldBackgroundColor: const Color(0xFF121212), 

              // Custom text styling using Roboto font for dark mode
              textTheme: GoogleFonts.robotoTextTheme(
                ThemeData.dark().textTheme,
              ).copyWith(
                headlineLarge: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Colors.white,
                ),
                titleLarge: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
                titleMedium: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.white,
                ),
                bodyLarge: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              // Styling for card components (rounded and elevated)
              cardTheme: CardTheme(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFF1E1E1E),
              ),

              // Styling for bottom navigation bar in dark mode
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: const Color(0xFF1E1E1E),
                elevation: 8,
                indicatorColor: const Color.fromARGB(59, 243, 240, 96),
                labelTextStyle: WidgetStateProperty.all(
                  GoogleFonts.roboto(fontSize: 14, color: Colors.white70),
                ),
              ),
            ),

            // Home page of the app set as the default landing screen
            home: const HomePage(),
          );
        },
      ),
    );
  }
}