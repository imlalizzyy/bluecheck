import 'package:flutter/material.dart';
import 'package:bluecheck/bilgilerimi_duzenle.dart';
import 'package:bluecheck/sifre_degistir.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme_provider.dart';

class AyarlarSayfasi extends StatelessWidget {
  const AyarlarSayfasi({super.key});

  Future<void> hesapSil(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // Firestore'dan kullanıcıyı sil
      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user.uid)
          .delete();

      // Firebase Authentication hesabını sil
      await user.delete();

      // Burada zaten login sayfasına yönlendirme yapabilirsin ama
      // biz kontrolü yukarıda tutuyoruz
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesabı silmek için lütfen tekrar giriş yapınız.'),
            backgroundColor: Colors.orange,
          ),
        );

        // Kullanıcıyı çıkış yaptır, login sayfasına gönder
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Bilgilerimi Düzenle"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BilgilerimiDuzenle()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Şifre Değiştir"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SifreDegistir()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Tema Değiştir'),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Hesabı Sil',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              bool? onay = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hesabı Sil'),
                  content: const Text(
                      'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sil',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (onay == true) {
                await hesapSil(context);
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
