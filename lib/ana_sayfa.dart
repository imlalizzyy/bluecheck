import 'package:flutter/material.dart';
import 'drawer.dart';

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BlueCheck Ana Sayfa"),
      ),
      drawer: const MyDrawer(),
      body: const Center(
        child: Text(
          'Hoş geldiniz!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
