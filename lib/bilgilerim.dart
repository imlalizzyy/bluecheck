import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BilgilerimSayfasi extends StatelessWidget {
  const BilgilerimSayfasi({super.key});

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(uid)
        .get();

    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bilgilerim")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Kullanıcı bilgileri bulunamadı."));
          }

          final data = snapshot.data!;
          final profilFotoUrl = data['profilFoto'] ??
              'https://i.pravatar.cc/150'; // Profil fotoğrafı yoksa placeholder

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(profilFotoUrl),
                  backgroundColor: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 20),
              InfoTile("Ad", data["ad"]),
              InfoTile("Soyad", data["soyad"]),
              InfoTile("E-posta", data["email"]),
              InfoTile("Öğrenci No", data["ogrenciNo"]),
              InfoTile("Rol", data["role"]),
              InfoTile("Doğum Tarihi",
                  data["dogumTarihi"]?.toString().split("T")[0] ?? ""),
              InfoTile("Cinsiyet", data["cinsiyet"]),
              InfoTile("Okul", data["okul"] ?? "Okul bilgisi yok"),
              InfoTile("Bölüm", data["bolum"] ?? "Bölüm bilgisi yok"),
            ],
          );
        },
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
