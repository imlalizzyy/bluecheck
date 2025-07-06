import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SifreDegistir extends StatefulWidget {
  const SifreDegistir({super.key});

  @override
  State<SifreDegistir> createState() => _SifreDegistirState();
}

class _SifreDegistirState extends State<SifreDegistir> {
  final _formKey = GlobalKey<FormState>();
  final _mevcutSifreController = TextEditingController();
  final _yeniSifreController = TextEditingController();
  final _yeniSifreTekrarController = TextEditingController();

  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sifreDegistir() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: _mevcutSifreController.text.trim(),
      );

      // Önce kullanıcıyı doğrula (reauthenticate)
      await user.reauthenticateWithCredential(cred);

      // Sonra şifreyi güncelle
      await user.updatePassword(_yeniSifreController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre başarıyla değiştirildi!')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mesaj = 'Bir hata oluştu.';
      if (e.code == 'wrong-password') {
        mesaj = 'Mevcut şifre yanlış.';
      } else if (e.code == 'weak-password') {
        mesaj = 'Yeni şifre çok zayıf.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre değiştirirken hata oluştu.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mevcutSifreController.dispose();
    _yeniSifreController.dispose();
    _yeniSifreTekrarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifre Değiştir')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _mevcutSifreController,
                decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
                obscureText: true,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Mevcut şifreyi girin';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _yeniSifreController,
                decoration: const InputDecoration(labelText: 'Yeni Şifre'),
                obscureText: true,
                validator: (val) {
                  if (val == null || val.length < 6) {
                    return 'Yeni şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _yeniSifreTekrarController,
                decoration:
                    const InputDecoration(labelText: 'Yeni Şifre Tekrar'),
                obscureText: true,
                validator: (val) {
                  if (val != _yeniSifreController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _sifreDegistir,
                      child: const Text('Şifreyi Değiştir'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
