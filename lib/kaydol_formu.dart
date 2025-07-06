import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KaydolEkrani extends StatefulWidget {
  final String role; // "ogrenci" veya "ogretmen"
  const KaydolEkrani({required this.role, Key? key}) : super(key: key);

  @override
  _KaydolEkraniState createState() => _KaydolEkraniState();
}

enum Cinsiyet { kadin, erkek, belirtilmedi }

class _KaydolEkraniState extends State<KaydolEkrani> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController ogrenciNoController = TextEditingController();
  final TextEditingController adController = TextEditingController();
  final TextEditingController soyadController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();
  final TextEditingController tekrarsifreController = TextEditingController();

  DateTime? dogumTarihi;
  Cinsiyet? secilenCinsiyet = Cinsiyet.belirtilmedi;
  bool kvkkOnaylandi = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _dogumTarihiSec(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dogumTarihi ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dogumTarihi = picked;
      });
    }
  }

  Future<void> kaydol() async {
    if (!_formKey.currentState!.validate()) return;

    if (sifreController.text.trim() != tekrarsifreController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreler uyuşmuyor')),
      );
      return;
    }

    if (dogumTarihi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen doğum tarihinizi seçin')),
      );
      return;
    }

    if (secilenCinsiyet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen cinsiyet seçin')),
      );
      return;
    }

    if (!kvkkOnaylandi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KVKK onayı gereklidir')),
      );
      return;
    }

    final email = emailController.text.trim();
    final isOgrenci = widget.role == 'ogrenci';
    final isOgretmen = widget.role == 'ogretmen';

    // 🔒 E-posta uzantı kontrolü
    if (isOgrenci && !email.endsWith('@ogrenci.ege.edu.tr')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Öğrenciler sadece @ogrenci.ege.edu.tr ile kayıt olabilir')),
      );
      return;
    }

    if (isOgretmen && !email.endsWith('@ege.edu.tr')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Öğretmenler sadece @ege.edu.tr ile kayıt olabilir')),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: sifreController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'ogrenciNo': isOgrenci ? ogrenciNoController.text.trim() : null,
          'ad': adController.text.trim(),
          'soyad': soyadController.text.trim(),
          'email': email,
          'profilFotoUrl': '', // bu satırı diğer koddan ekledim
          'dogumTarihi': dogumTarihi?.toIso8601String(),
          'cinsiyet': secilenCinsiyet.toString().split('.').last,
          'kvkkOnaylandi': kvkkOnaylandi,
          'kayitTarihi': FieldValue.serverTimestamp(),
          'role': widget.role,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı!')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String hataMesaji = 'Bir hata oluştu.';
      if (e.code == 'email-already-in-use') {
        hataMesaji = 'Bu email zaten kullanılıyor.';
      } else if (e.code == 'invalid-email') {
        hataMesaji = 'Geçersiz email adresi.';
      } else if (e.code == 'weak-password') {
        hataMesaji = 'Şifre çok zayıf.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hataMesaji)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beklenmeyen bir hata oluştu.')),
      );
    }
  }

  @override
  void dispose() {
    ogrenciNoController.dispose();
    adController.dispose();
    soyadController.dispose();
    emailController.dispose();
    sifreController.dispose();
    tekrarsifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOgrenci = widget.role == 'ogrenci';

    return Scaffold(
      appBar: AppBar(
        title: Text('${isOgrenci ? 'Öğrenci' : 'Öğretmen'} Kaydı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isOgrenci)
                TextFormField(
                  controller: ogrenciNoController,
                  decoration:
                      const InputDecoration(labelText: 'Öğrenci Numarası'),
                  validator: (value) =>
                      value!.isEmpty ? 'Lütfen öğrenci numarası girin' : null,
                ),
              TextFormField(
                controller: adController,
                decoration: const InputDecoration(labelText: 'Ad'),
                validator: (value) =>
                    value!.isEmpty ? 'Lütfen adınızı girin' : null,
              ),
              TextFormField(
                controller: soyadController,
                decoration: const InputDecoration(labelText: 'Soyad'),
                validator: (value) =>
                    value!.isEmpty ? 'Lütfen soyadınızı girin' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: (value) =>
                    value!.isEmpty ? 'Lütfen e-posta girin' : null,
              ),
              TextFormField(
                controller: sifreController,
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null,
              ),
              TextFormField(
                controller: tekrarsifreController,
                decoration: const InputDecoration(labelText: 'Şifre (Tekrar)'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Lütfen şifreyi tekrar girin';
                  if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _dogumTarihiSec(context),
                child: Text(dogumTarihi == null
                    ? 'Doğum Tarihi Seç'
                    : 'Doğum Tarihi: ${dogumTarihi!.toLocal().toString().split(' ')[0]}'),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<Cinsiyet>(
                    title: const Text('Kadın'),
                    value: Cinsiyet.kadin,
                    groupValue: secilenCinsiyet,
                    onChanged: (value) =>
                        setState(() => secilenCinsiyet = value),
                  ),
                  RadioListTile<Cinsiyet>(
                    title: const Text('Erkek'),
                    value: Cinsiyet.erkek,
                    groupValue: secilenCinsiyet,
                    onChanged: (value) =>
                        setState(() => secilenCinsiyet = value),
                  ),
                  RadioListTile<Cinsiyet>(
                    title: const Text('Belirtilmedi'),
                    value: Cinsiyet.belirtilmedi,
                    groupValue: secilenCinsiyet,
                    onChanged: (value) =>
                        setState(() => secilenCinsiyet = value),
                  ),
                ],
              ),
              CheckboxListTile(
                title: const Text('KVKK metnini okudum ve onaylıyorum'),
                value: kvkkOnaylandi,
                onChanged: (value) =>
                    setState(() => kvkkOnaylandi = value ?? false),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: kaydol,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Kayıt Ol', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
