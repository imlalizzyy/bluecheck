import 'package:bluecheck/giris_ekrani.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bluecheck/bilgilerim.dart';
import 'package:bluecheck/ayarlar_sayfasi.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  Future<Map<String, dynamic>?> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(user.uid)
        .get();

    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                  child: Text("Kullanıcı bilgileri alınamadı."));
            }

            final data = snapshot.data!;
            final name = data['ad'] ?? 'İsim yok';
            final email = data['email'] ?? 'E-posta yok';

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 25, 112, 183),
                  ),
                  accountName: Text(name),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(name.isNotEmpty ? name[0] : '?'),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('Bilgilerim'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BilgilerimSayfasi()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Kişisel Verilerin Korunması (KVKK)'),
                        subtitle: const Text(
                            'Verileriniz güvende. Detaylar için tıklayın.'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const KvkkMetniSayfasi()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Ayarlar'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AyarlarSayfasi()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.bottomCenter,
                  child: ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Çıkış'),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const GirisEkrani()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Basit KVKK Metni Sayfası örneği, bunu ayrı dosyada oluşturabilirsin
class KvkkMetniSayfasi extends StatelessWidget {
  const KvkkMetniSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KVKK Metni')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kişisel Verileriniz Bizimle Güvende!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bu uygulama, kişisel verilerinizi yasalara uygun şekilde toplar, saklar ve korur.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 15),
            Text(
              'Verilerinizi sadece hizmetlerimizi sunmak ve geliştirmek için kullanıyoruz.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 15),
            Text(
              'Siz izin vermedikçe, verilerinizi üçüncü kişilerle paylaşmayız.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 15),
            Text(
              'Kişisel verilerinizin korunması bizim için önemli. İstediğiniz zaman verilerinize erişebilir, düzeltilmesini veya silinmesini talep edebilirsiniz.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 15),
            Text(
              'KVKK (Kişisel Verilerin Korunması Kanunu) kapsamında haklarınızı kullanmak için bizimle iletişime geçebilirsiniz.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 25),
            Text(
              'Güveniniz için teşekkürler!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '— Bluecheck Ekibi',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.blueGrey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
