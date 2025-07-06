import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'kaydol_formu.dart';
import 'ogretmen_ekrani.dart';
import 'ogrenci_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  String? secilenRol;

  Future<void> girisYap(String email, String sifre, String rol) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: sifre);

      User? user = userCredential.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı bilgisi alınamadı')),
        );
        return;
      }

      String uid = user.uid;

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uid)
          .get();

      if (snapshot.exists && snapshot['role'] == rol) {
        if (rol == 'ogrenci') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OgrenciEkrani()),
          );
        } else if (rol == 'ogretmen') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OgretmenEkrani()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$rol kaydı bulunamadı!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mesaj = 'Bir hata oluştu';
      if (e.code == 'user-not-found') mesaj = 'Kullanıcı bulunamadı';
      if (e.code == 'wrong-password') mesaj = 'Şifre yanlış';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mesaj)));
    }
  }

  void girisDialog(String rol) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController sifreController = TextEditingController();
    bool beniHatirla = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('${rol == 'ogrenci' ? 'Öğrenci' : 'Öğretmen'} Girişi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: sifreController,
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    obscureText: true,
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
                      const Text('Beni Hatırla'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('İptal'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: const Text('Giriş Yap'),
                onPressed: () async {
                  Navigator.of(context).pop();

                  await FirebaseAuth.instance.setPersistence(
                    beniHatirla ? Persistence.LOCAL : Persistence.SESSION,
                  );

                  await girisYap(
                    emailController.text.trim(),
                    sifreController.text.trim(),
                    rol,
                  );
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlueCheck Giriş'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade50,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'BlueCheck\'e Hoş Geldiniz!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black12,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (secilenRol == null) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Öğrenci'),
                  onPressed: () {
                    setState(() {
                      secilenRol = 'ogrenci';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Öğretmen'),
                  onPressed: () {
                    setState(() {
                      secilenRol = 'ogretmen';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Seçilen Rol: ${secilenRol == 'ogrenci' ? 'Öğrenci' : 'Öğretmen'}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Giriş Yap'),
                  onPressed: () {
                    if (secilenRol != null) {
                      girisDialog(secilenRol!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Kayıt Ol'),
                  onPressed: () {
                    if (secilenRol != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KaydolEkrani(role: secilenRol!),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue.shade700),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      secilenRol = null;
                    });
                  },
                  child: Text(
                    '← Geri Dön',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
