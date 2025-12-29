import 'package:assemblex/admin_page/edit_admin.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assemblex/user_page/homepage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,


      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

   
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF4A90E2),      // Soft Blue
          onPrimary: Colors.white,
          secondary: Color(0xFFF5A623),    // Warm Orange
          onSecondary: Colors.white,
          error: Color(0xFFEF4444),
          onError: Colors.white,
          background: Color(0xFFFFFFFF),
          onBackground: Color(0xFF1F2937),
          surface: Color(0xFFF9FAFB),       // Cards
          onSurface: Color(0xFF1F2937),
        ),

        
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),

  
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF4A90E2),
          elevation: 1,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF4A90E2)),
        ),

     
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          titleLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B5563),
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A90E2),
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A90E2),
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A90E2),
          ),
        ),

     
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

     


        iconTheme: const IconThemeData(
          color: Color(0xFF4A90E2),
          size: 22,
        ),

    
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE5E7EB),
          thickness: 1,
        ),
      ),

    
      home:  EditAdmin()    //AssembleX_home(),
    );
  }
}
