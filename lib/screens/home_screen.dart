// home_screen.dart
// 메인 화면 - 얼굴 인식 로그인(face recognition), 얼굴 등록(new register)로 이동할 수 있음

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'face/recognition_screen.dart';
import 'face/register_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 120),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 160,
                      height: 160,
                    ),

                    const SizedBox(height: 60),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(240, 56),
                            elevation: 10,
                            shadowColor: Colors.black54,
                            backgroundColor: const Color(0xFF247BBE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text('Face Recognition', style: GoogleFonts.poppins(fontSize:17, fontWeight: FontWeight.w600, letterSpacing: 0.5,),),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RecognitionScreen()),
                          ),
                        ),
                        const SizedBox(height: 50),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(240, 56),
                            elevation: 10,
                            shadowColor: Colors.black54,
                            backgroundColor: const Color(0xFF247BBE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text('New Face Register', style: GoogleFonts.poppins(fontSize:17, fontWeight: FontWeight.w600, letterSpacing: 0.5,),),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                        ),
                      ],
                    ),
                    ),
                ),
                ],)
      )
    );

  }
}