import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

class OgrenciBluetoothYoklama extends StatefulWidget {
  const OgrenciBluetoothYoklama({super.key});

  @override
  State<OgrenciBluetoothYoklama> createState() => _OgrenciBluetoothYoklamaState();
}

class _OgrenciBluetoothYoklamaState extends State<OgrenciBluetoothYoklama> {
  final Strategy strategy = Strategy.P2P_STAR;
  bool katildi = false;

  Future<void> _katilYoklama() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Gerekli izinleri kontrol et
    if (!await Permission.location.isGranted) await Permission.location.request();
    if (!await Permission.bluetoothConnect.isGranted) await Permission.bluetoothConnect.request();
    if (!await Permission.bluetoothScan.isGranted) await Permission.bluetoothScan.request();

    // Firestore'dan aktif ders adı al
    final aktifDersDoc = await FirebaseFirestore.instance
        .collection('aktifDers')
        .doc('guncel')
        .get();

    if (!aktifDersDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktif ders bilgisi bulunamadı.")),
      );
      return;
    }

    final dersAdi = aktifDersDoc.data()?['dersAdi'] ?? 'Ders';

    // Discovery başlat
    await Nearby().startDiscovery(
      dersAdi,
      strategy,
      onEndpointFound: (id, name, serviceId) {
        debugPrint("Bulundu: $name ($id)");

        Nearby().requestConnection(
          user.displayName ?? "Ogrenci",
          id,
          onConnectionInitiated: (id, info) {
            Nearby().acceptConnection(
              id,
              onPayLoadRecieved: (_, __) {},
              onPayloadTransferUpdate: (_, __) {},
            );

            final data = "${user.displayName};${user.email};${user.uid}";
            final bytes = Uint8List.fromList(data.codeUnits);

            // Bağlantı başarılıysa payload gönder
            Future.delayed(const Duration(milliseconds: 500), () {
              Nearby().sendBytesPayload(id, bytes);
              setState(() => katildi = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Yoklamaya katıldınız!")),
              );
            });
          },
          onConnectionResult: (id, status) {
            debugPrint("Bağlantı sonucu: $status");
          },
          onDisconnected: (id) {
            debugPrint("Bağlantı kesildi: $id");
          },
        );
      },
      onEndpointLost: (id) => debugPrint("Bağlantı kayboldu: $id"),
    );
  }

  @override
  void dispose() {
    Nearby().stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Yoklaması")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              katildi ? "Katıldınız ✔" : "Yoklamaya katılmak için butona tıklayın",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth),
              label: const Text("Bluetooth ile Katıl"),
              onPressed: katildi ? null : _katilYoklama,
            ),
          ],
        ),
      ),
    );
  }
}
