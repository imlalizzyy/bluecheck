import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothEkrani extends StatefulWidget {
  const BluetoothEkrani({super.key});

  @override
  _BluetoothEkraniState createState() => _BluetoothEkraniState();
}

class _BluetoothEkraniState extends State<BluetoothEkrani> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  List<ScanResult> scanResults = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Tarama')),
      body: scanResults.isEmpty
          ? const Center(child: Text('Cihaz bulunamadı veya tarama yapılmadı.'))
          : ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final cihaz = scanResults[index].device;
                return ListTile(
                  title: Text(
                      cihaz.name.isEmpty ? 'Bilinmeyen Cihaz' : cihaz.name),
                  subtitle: Text(cihaz.id.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        tooltip: 'Tarama başlat',
        child: const Icon(Icons.search),
      ),
    );
  }
}
