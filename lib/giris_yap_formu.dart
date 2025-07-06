import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ogrenci_ekrani.dart';

class GirisYapFormu extends StatefulWidget {
  const GirisYapFormu({super.key});

  @override
  _GirisYapFormuState createState() => _GirisYapFormuState();
}

class _GirisYapFormuState extends State<GirisYapFormu> {
  final emailController = TextEditingController();
  final sifreController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool beniHatirla = false;

  Future<void> girisYap() async {
    String email = emailController.text.trim();
    String sifre = sifreController.text.trim();

    try {
      await _auth.setPersistence(
        beniHatirla ? Persistence.LOCAL : Persistence.SESSION,
      );

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: sifre,
      );
      if (userCredential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarılı')),
        );

        Future.microtask(() {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OgrenciEkrani()),
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      String mesaj = 'Bir hata oluştu.';
      if (e.code == 'user-not-found') {
        mesaj = 'Kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password') {
        mesaj = 'Şifre yanlış.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: beniHatirla,
                  onChanged: (value) {
                    setState(() {
                      beniHatirla = value ?? false;
                    });
                  },
                ),
                const Text("Beni Hatırla"),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: girisYap,
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
