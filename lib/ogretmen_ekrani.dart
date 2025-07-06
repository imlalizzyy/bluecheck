import 'package:bluecheck/giris_ekrani.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ders_tanimlama_ekrani.dart';
import 'package:intl/intl.dart';
import 'drawer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ogretmen_bluetooth_yoklama.dart';

class OgretmenEkrani extends StatefulWidget {
  const OgretmenEkrani({super.key});

  @override
  State<OgretmenEkrani> createState() => _OgretmenEkraniState();
}

class _OgretmenEkraniState extends State<OgretmenEkrani> {
  List<String> bagliOgrenciler = [];
  bool scanning = false;

  Future<bool> izinleriKontrolEtVeIste() async {
    List<Permission> izinler = [];

    if (!await Permission.bluetoothScan.isGranted)
      izinler.add(Permission.bluetoothScan);
    if (!await Permission.bluetoothConnect.isGranted)
      izinler.add(Permission.bluetoothConnect);
    if (!await Permission.location.isGranted) izinler.add(Permission.location);

    if (izinler.isNotEmpty) {
      final sonuc = await izinler.request();
      return sonuc.values.every((status) => status.isGranted);
    }
    return true;
  }

  Future<void> yoklamaBaslat(
      BuildContext context, String dersId, String dersAdi) async {
    if (scanning) return;

    bool izinVar = await izinleriKontrolEtVeIste();
    if (!izinVar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bluetooth ve konum izinleri gerekli.")),
      );
      return;
    }

    scanning = true;
    bagliOgrenciler.clear();

    final yoklamaTarihi = DateTime.now();
    final yoklamaDocId = DateFormat('yyyyMMdd_HHmmss').format(yoklamaTarihi);

    // Ders bilgisini güncelle
    final dersDoc = await FirebaseFirestore.instance
        .collection('dersler')
        .doc(dersId)
        .get();
    final dersData = dersDoc.data() ?? {};
    final bolum = dersData['bolum'] ?? '-';
    final saat = dersData['saat'] ?? '-';

    String gun = '-';
    final tarihVal = dersData['tarih'];
    if (tarihVal is Timestamp) {
      gun = DateFormat('EEEE', 'tr_TR').format(tarihVal.toDate());
    }

    await FirebaseFirestore.instance.collection('aktifDers').doc('guncel').set({
      'dersAdi': dersAdi,
      'bolum': bolum,
      'gun': gun,
      'saat': saat,
      'baslatmaZamani': yoklamaTarihi,
      'dersId': dersId,
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 60));
      final results = await FlutterBluePlus.scanResults.first;

      for (var r in results) {
        final deviceId = r.device.id
            .id; // burada .id.id kullandım, bazı versiyonlarda doğru olan bu

        final snapshot = await FirebaseFirestore.instance
            .collection("ogrenciler")
            .where("cihazId", isEqualTo: deviceId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final ogrenci = snapshot.docs.first.data();
          final adSoyad = ogrenci["adSoyad"] ?? "Bilinmiyor";
          final email = ogrenci["email"] ?? "";
          final uid = ogrenci["uid"] ?? "";

          final bilgi = "$adSoyad - $email";

          if (!bagliOgrenciler.contains(bilgi)) {
            setState(() {
              bagliOgrenciler.add(bilgi);
            });

            // Yoklama kaydı dersler koleksiyonunda
            await FirebaseFirestore.instance
                .collection("dersler")
                .doc(dersId)
                .collection("yoklamalar")
                .doc(yoklamaDocId)
                .set({
              'tarih': yoklamaTarihi,
              'dersAdi': dersAdi,
            });

            // Katılan öğrenci kaydı
            await FirebaseFirestore.instance
                .collection("dersler")
                .doc(dersId)
                .collection("yoklamalar")
                .doc(yoklamaDocId)
                .collection("katilanlar")
                .doc(uid)
                .set({
              'adSoyad': adSoyad,
              'email': email,
              'uid': uid,
            });

            // Öğrencinin yoklama geçmişi
            await FirebaseFirestore.instance
                .collection("ogrenciler")
                .doc(uid)
                .collection("yoklamaGecmisi")
                .doc('$dersId-$yoklamaDocId')
                .set({
              'dersAdi': dersAdi,
              'tarih': yoklamaTarihi,
              'durum': 'Katıldı',
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Yoklama başlatma hatası: $e");
    } finally {
      await FlutterBluePlus.stopScan();
      scanning = false;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$dersAdi Yoklaması",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Bağlı Öğrenciler:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: bagliOgrenciler.isEmpty
                      ? const Center(child: Text("Hiç öğrenci bulunamadı."))
                      : ListView.builder(
                          itemCount: bagliOgrenciler.length,
                          itemBuilder: (context, index) => ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(bagliOgrenciler[index]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void gecmisiAc(String dersId, String dersAdi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YoklamaGecmisiEkrani(dersId: dersId, dersAdi: dersAdi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Derslerim"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Ders Ekle",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DersTanimlamaEkrani()),
              );
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OgretmenBluetoothYoklama()),
              );
            },
            child: Text("Yeni Bluetooth Yoklamayı Başlat"),
          )
        ],
      ),
      drawer: const MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("dersler")
              .orderBy("olusturmaTarihi", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Henüz ders eklenmedi."));
            }

            final dersler = snapshot.data!.docs;

            return ListView.builder(
              itemCount: dersler.length,
              itemBuilder: (context, index) {
                final dersDoc = dersler[index];
                final ders = dersDoc.data() as Map<String, dynamic>;
                final dersId = dersDoc.id;

                final String bolum = ders['bolum'] ?? 'Bölüm bilgisi yok';
                final String derslik = ders['derslik'] ?? 'Derslik bilgisi yok';
                final String saat = ders['saat'] ?? 'Saat bilgisi yok';
                final String dersAdi = ders['dersAdi'] ?? 'Ders ismi';

                String gun = 'Gün bilgisi yok';
                try {
                  final tarihDegeri = ders['tarih'];
                  if (tarihDegeri is Timestamp) {
                    gun = DateFormat('EEEE', 'tr_TR')
                        .format(tarihDegeri.toDate());
                  } else if (tarihDegeri is String && tarihDegeri.isNotEmpty) {
                    gun = DateFormat('EEEE', 'tr_TR')
                        .format(DateTime.parse(tarihDegeri));
                  }
                } catch (e) {
                  debugPrint('Tarih hatası: $e');
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.black54),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              yoklamaBaslat(context, dersId, dersAdi),
                          icon: const Icon(Icons.bluetooth),
                          label: const Text("Yoklamayı Başlat"),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          dersAdi,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(gun),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("$bolum - $derslik"),
                            Text(saat),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => gecmisiAc(dersId, dersAdi),
                          child: const Text("Yoklama Geçmişi"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class YoklamaGecmisiEkrani extends StatelessWidget {
  final String dersId;
  final String dersAdi;

  const YoklamaGecmisiEkrani({
    required this.dersId,
    required this.dersAdi,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$dersAdi Yoklama Geçmişi")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('dersler')
            .doc(dersId)
            .collection('yoklamalar')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final yoklamalar = snapshot.data!.docs;

          if (yoklamalar.isEmpty) {
            return const Center(child: Text("Yoklama kaydı yok."));
          }

          return ListView.builder(
            itemCount: yoklamalar.length,
            itemBuilder: (context, index) {
              final yoklama = yoklamalar[index];
              final tarih = (yoklama['tarih'] as Timestamp).toDate();

              return ExpansionTile(
                title: Text(DateFormat('dd.MM.yyyy – HH:mm').format(tarih)),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        yoklama.reference.collection('katilanlar').snapshots(),
                    builder: (context, katilimSnapshot) {
                      if (!katilimSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final katilanlar = katilimSnapshot.data!.docs;

                      if (katilanlar.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Henüz kimse yoklama almadı.'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: katilanlar.length,
                        itemBuilder: (context, i) {
                          final kisi =
                              katilanlar[i].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(kisi['adSoyad'] ?? 'Bilinmiyor'),
                            subtitle: Text(kisi['email'] ?? ''),
                          );
                        },
                      );
                    },
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}
