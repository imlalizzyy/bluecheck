import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'giris_ekrani.dart';
import 'drawer.dart';
import 'ogrenci_bluetooth_yoklama.dart';

class OgrenciEkrani extends StatefulWidget {
  const OgrenciEkrani({super.key});

  @override
  State<OgrenciEkrani> createState() => _OgrenciAnaEkranState();
}

class _OgrenciAnaEkranState extends State<OgrenciEkrani> {
  bool bluetoothAcik = false;

  String guncelDers = 'Yükleniyor...';
  String dersGunu = '-';
  String bolumDerslik = '-';
  String dersSaati = '-';
  String dersId = '';

  String? sonKatildigiDers;
  String? sonKatilmadigiDers;

  @override
  void initState() {
    super.initState();
    dersBilgileriniGetir();
  }

  Future<void> dersBilgileriniGetir() async {
    final doc = await FirebaseFirestore.instance
        .collection('aktifDers')
        .doc('guncel')
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        guncelDers = data['dersAdi'] ?? 'Bilinmeyen Ders';
        dersGunu = data['gun'] ?? '-';
        bolumDerslik = data['bolum'] ?? '-';
        dersSaati = data['saat'] ?? '-';
        dersId = data['dersId'] ??
            ''; // bunu aktifDers guncel dokümanına eklemen lazım
      });
    } else {
      setState(() {
        guncelDers = 'Ders bilgisi yok';
      });
    }
  }

  Future<bool> izinKontrolVeIzinIstegi() async {
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

  void bluetoothuAc() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;

      if (adapterState == BluetoothAdapterState.on) {
        debugPrint('Bluetooth açık, tarama başlatılıyor.');

        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

        final results = await FlutterBluePlus.scanResults.first;

        bool cihazBulundu = false;
        for (ScanResult r in results) {
          final cihazId = r.device.id.id;
          debugPrint("Cihaz ID: $cihazId");

          await kendiniKaydet(cihazId);
          await yoklamaKaydet(guncelDers);

          cihazBulundu = true;
          break;
        }

        if (!cihazBulundu) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cihazınız taramada bulunamadı.")),
          );
        }

        await FlutterBluePlus.stopScan();

        setState(() {
          bluetoothAcik = true;
          sonKatildigiDers = guncelDers;
          sonKatilmadigiDers = null;
        });
      } else {
        debugPrint('Bluetooth kapalı. Kullanıcı ayarlara yönlendiriliyor...');
        const url = 'app-settings:';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          debugPrint('Ayar ekranı açılamadı.');
        }
      }
    } catch (e) {
      debugPrint('Bluetooth kontrolü sırasında hata: $e');
    }
  }

  Future<void> kendiniKaydet(String cihazId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && cihazId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("ogrenciler")
            .doc(user.uid)
            .set({
          'adSoyad': user.displayName ?? "Bilinmiyor",
          'email': user.email,
          'uid': user.uid,
          'cihazId': cihazId,
          'zaman': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("Öğrenci bilgisi kaydedildi");
      }
    } catch (e) {
      debugPrint("Kayıt hatası: $e");
    }
  }

  Future<void> yoklamaKaydet(String dersAdi) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final tarih = DateTime.now();

      // Aktif ders dokümanından dersId al
      final aktifDersDoc = await FirebaseFirestore.instance
          .collection('aktifDers')
          .doc('guncel')
          .get();
      if (!aktifDersDoc.exists) return;

      final dersId = aktifDersDoc.data()?['dersId'];
      if (dersId == null || dersId.isEmpty) return;

      final yoklamaDocId = DateFormat('yyyyMMdd_HHmmss').format(tarih);

      // Öğrenci yoklama geçmişi
      await FirebaseFirestore.instance
          .collection("ogrenciler")
          .doc(user.uid)
          .collection("yoklamaGecmisi")
          .doc(yoklamaDocId)
          .set({
        'dersAdi': dersAdi,
        'tarih': tarih,
        'durum': 'Katıldı',
      });

      // Öğrenciyi öğretmenin yoklama katılımcılar koleksiyonuna ekle
      await FirebaseFirestore.instance
          .collection('dersler')
          .doc(dersId)
          .collection('yoklamalar')
          .doc(yoklamaDocId)
          .set({
        'tarih': tarih,
        'dersAdi': dersAdi,
      });

      await FirebaseFirestore.instance
          .collection('dersler')
          .doc(dersId)
          .collection('yoklamalar')
          .doc(yoklamaDocId)
          .collection('katilanlar')
          .doc(user.uid)
          .set({
        'adSoyad': user.displayName ?? 'Bilinmiyor',
        'email': user.email ?? '',
        'uid': user.uid,
      });

      debugPrint("Yoklama bilgisi ve katılım öğretmene kaydedildi");
    } catch (e) {
      debugPrint("Yoklama kaydetme hatası: $e");
    }
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Öğrenci Paneli"),
          automaticallyImplyLeading: true,
        ),
        drawer: const MyDrawer(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guncelDers,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(dersGunu),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(bolumDerslik),
                          Text(dersSaati),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OgrenciBluetoothYoklama()),
                  );
                },
                child: Text("Bluetooth ile Katıl"),
              ),
              const SizedBox(height: 40),
              const Text("Geçmiş Dersler",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (sonKatildigiDers != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(sonKatildigiDers!), const Text("Katıldı")],
                  ),
                ),
              if (sonKatilmadigiDers != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sonKatilmadigiDers!),
                      const Text("Katılmadı")
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("ogrenciler")
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection("yoklamaGecmisi")
                      .orderBy("tarih", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text("Henüz yoklama geçmişiniz yok."));
                    }

                    final yoklamalar = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: yoklamalar.length,
                      itemBuilder: (context, index) {
                        final yoklama =
                            yoklamalar[index].data() as Map<String, dynamic>;
                        final dersAdi =
                            yoklama['dersAdi'] ?? "Ders bilgisi yok";
                        final tarih = (yoklama['tarih'] as Timestamp).toDate();
                        final durum = yoklama['durum'] ?? "Bilinmiyor";

                        return ListTile(
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(dersAdi),
                          subtitle: Text(
                              "${DateFormat('dd.MM.yyyy – HH:mm').format(tarih)} - Durum: $durum"),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
