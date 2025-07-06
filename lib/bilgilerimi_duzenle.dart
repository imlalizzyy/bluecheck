import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BilgilerimiDuzenle extends StatefulWidget {
  const BilgilerimiDuzenle({super.key});

  @override
  State<BilgilerimiDuzenle> createState() => _BilgilerimiDuzenleState();
}

class _BilgilerimiDuzenleState extends State<BilgilerimiDuzenle> {
  final TextEditingController adController = TextEditingController();
  final TextEditingController soyadController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final TextEditingController ogrenciNoController = TextEditingController();
  final TextEditingController dogumTarihiController = TextEditingController();

  final TextEditingController okulController = TextEditingController();
  final TextEditingController bolumController = TextEditingController();

  String? seciliCinsiyet;
  String? seciliRol;

  final user = FirebaseAuth.instance.currentUser;

  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(user!.uid)
        .get();

    final data = doc.data();

    if (data != null) {
      adController.text = data['ad'] ?? '';
      soyadController.text = data['soyad'] ?? '';
      emailController.text = data['email'] ?? '';

      ogrenciNoController.text = data['ogrenciNo']?.toString() ?? '';
      dogumTarihiController.text = data['dogumTarihi'] ?? '';

      okulController.text = data['okul'] ?? '';
      bolumController.text = data['bolum'] ?? '';

      seciliCinsiyet = data['cinsiyet'];
      seciliRol = data['rol'];
    }

    setState(() {
      _yukleniyor = false;
    });
  }

  Future<void> _guncelle() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user!.uid)
          .update({
        'ad': adController.text.trim(),
        'soyad': soyadController.text.trim(),
        'email': emailController.text.trim(),
        'ogrenciNo': ogrenciNoController.text.trim(),
        'dogumTarihi': dogumTarihiController.text.trim(),
        'okul': okulController.text.trim(),
        'bolum': bolumController.text.trim(),
        'cinsiyet': seciliCinsiyet,
        'rol': seciliRol,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bilgiler başarıyla güncellendi!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Güncelleme sırasında hata oluştu.")),
      );
    }
  }

  Future<void> _tarihSec() async {
    DateTime initialDate =
        DateTime.tryParse(dogumTarihiController.text) ?? DateTime(2000);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dogumTarihiController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  @override
  void dispose() {
    adController.dispose();
    soyadController.dispose();
    emailController.dispose();
    ogrenciNoController.dispose();
    dogumTarihiController.dispose();
    okulController.dispose();
    bolumController.dispose();
    super.dispose();
  }

  Widget _profilFotoGoster() {
    String basHarf = (adController.text.trim().isNotEmpty)
        ? adController.text.trim()[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.blueAccent,
      child: Text(
        basHarf,
        style: const TextStyle(fontSize: 40, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bilgilerimi Düzenle")),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _profilFotoGoster(),
                    const SizedBox(height: 20),
                    TextField(
                      controller: adController,
                      decoration: const InputDecoration(labelText: 'Ad'),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    TextField(
                      controller: soyadController,
                      decoration: const InputDecoration(labelText: 'Soyad'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-posta'),
                    ),
                    TextField(
                      controller: ogrenciNoController,
                      decoration:
                          const InputDecoration(labelText: 'Öğrenci No'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: dogumTarihiController,
                      decoration:
                          const InputDecoration(labelText: 'Doğum Tarihi'),
                      readOnly: true,
                      onTap: _tarihSec,
                    ),
                    TextField(
                      controller: okulController,
                      decoration: const InputDecoration(labelText: 'Okul'),
                    ),
                    TextField(
                      controller: bolumController,
                      decoration: const InputDecoration(labelText: 'Bölüm'),
                    ),
                    DropdownButtonFormField<String>(
                      value: (seciliCinsiyet != null &&
                              ['Erkek', 'Kadın', 'Diğer']
                                  .contains(seciliCinsiyet))
                          ? seciliCinsiyet
                          : null,
                      decoration: const InputDecoration(labelText: 'Cinsiyet'),
                      items: const [
                        DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                        DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                        DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          seciliCinsiyet = val;
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: seciliRol,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Öğrenci', child: Text('Öğrenci')),
                        DropdownMenuItem(
                            value: 'Öğretmen', child: Text('Öğretmen')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          seciliRol = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _guncelle,
                      child: const Text("Güncelle"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
