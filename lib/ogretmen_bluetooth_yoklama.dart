import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class OgretmenBluetoothYoklama extends StatefulWidget {
  const OgretmenBluetoothYoklama({super.key});

  @override
  State<OgretmenBluetoothYoklama> createState() => _OgretmenBluetoothYoklamaState();
}

class _OgretmenBluetoothYoklamaState extends State<OgretmenBluetoothYoklama> {
  final Strategy strategy = Strategy.P2P_STAR;
  final List<Map<String, String>> katilanOgrenciler = [];
  String dersAdi = '';
  String dersId = '';
  String yoklamaDocId = '';

  @override
  void initState() {
    super.initState();
    _initializeYoklama();
  }

  Future<void> _initializeYoklama() async {
    final aktifDers = await FirebaseFirestore.instance
        .collection('aktifDers')
        .doc('guncel')
        .get();

    if (!aktifDers.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktif ders bilgisi bulunamadı.")),
      );
      Navigator.pop(context);
      return;
    }

    final data = aktifDers.data()!;
    dersAdi = data['dersAdi'] ?? 'Bilinmeyen Ders';
    dersId = data['dersId'] ?? '';

    yoklamaDocId = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    await _izinleriKontrolEt();

    await Nearby().startAdvertising(
      dersAdi,
      strategy,
      onConnectionInitiated: _onConnectionInit,
      onConnectionResult: _onConnectionResult,
      onDisconnected: (id) => debugPrint('Bağlantı koptu: $id'),
    );
  }

  Future<void> _izinleriKontrolEt() async {
    if (!await Permission.location.isGranted) {
      await Permission.location.request();
    }
    if (!await Permission.bluetoothConnect.isGranted) {
      await Permission.bluetoothConnect.request();
    }
    if (!await Permission.bluetoothScan.isGranted) {
      await Permission.bluetoothScan.request();
    }
  }

  void _onConnectionInit(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) {
        if (payload.bytes != null) {
          final data = String.fromCharCodes(payload.bytes!);
          final ogrenci = data.split(';');
          if (ogrenci.length >= 3) {
            final adSoyad = ogrenci[0];
            final email = ogrenci[1];
            final uid = ogrenci[2];

            if (!katilanOgrenciler.any((e) => e['uid'] == uid)) {
              setState(() {
                katilanOgrenciler.add({
                  'adSoyad': adSoyad,
                  'email': email,
                  'uid': uid,
                });
              });

              final tarih = DateTime.now();

              FirebaseFirestore.instance
                  .collection('dersler')
                  .doc(dersId)
                  .collection('yoklamalar')
                  .doc(yoklamaDocId)
                  .set({'tarih': tarih, 'dersAdi': dersAdi});

              FirebaseFirestore.instance
                  .collection('dersler')
                  .doc(dersId)
                  .collection('yoklamalar')
                  .doc(yoklamaDocId)
                  .collection('katilanlar')
                  .doc(uid)
                  .set({'adSoyad': adSoyad, 'email': email, 'uid': uid});

              FirebaseFirestore.instance
                  .collection('ogrenciler')
                  .doc(uid)
                  .collection('yoklamaGecmisi')
                  .doc('$dersId-$yoklamaDocId')
                  .set({
                'dersAdi': dersAdi,
                'tarih': tarih,
                'durum': 'Katıldı',
              });
            }
          }
        }
      },
      onPayloadTransferUpdate: (endid, update) {},
    );
  }

  void _onConnectionResult(String id, Status status) {
    debugPrint("Bağlantı sonucu: $status");
  }

  @override
  void dispose() {
    Nearby().stopAdvertising();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Yoklaması")),
      body: katilanOgrenciler.isEmpty
          ? const Center(child: Text("Henüz öğrenci katılmadı."))
          : ListView.builder(
        itemCount: katilanOgrenciler.length,
        itemBuilder: (context, index) {
          final ogrenci = katilanOgrenciler[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(ogrenci['adSoyad'] ?? 'Ad'),
            subtitle: Text(ogrenci['email'] ?? ''),
            trailing: const Icon(Icons.check, color: Colors.green),
          );
        },
      ),
    );
  }
}
