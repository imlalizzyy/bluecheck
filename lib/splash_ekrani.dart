import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'giris_ekrani.dart';
import 'ogrenci_ekrani.dart';

class SplashEkrani extends StatefulWidget {
  const SplashEkrani({super.key});

  @override
  _SplashEkraniState createState() => _SplashEkraniState();
}

class _SplashEkraniState extends State<SplashEkrani> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () async {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OgrenciEkrani()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GirisEkrani()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Text(
          'BlueCheck',
          style: TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
