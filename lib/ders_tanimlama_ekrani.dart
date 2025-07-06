import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DersTanimlamaEkrani extends StatefulWidget {
  const DersTanimlamaEkrani({super.key});

  @override
  State<DersTanimlamaEkrani> createState() => _DersTanimlamaEkraniState();
}

class _DersTanimlamaEkraniState extends State<DersTanimlamaEkrani> {
  final TextEditingController dersAdiController = TextEditingController();
  final TextEditingController bolumController = TextEditingController();
  final TextEditingController derslikController = TextEditingController();
  final TextEditingController saatController = TextEditingController();

  int? secilenYoklamaSayisi;
  DateTime? secilenTarih;
  String? secilenSure;

  final List<String> sureSecenekleri = [
    '5 dakika',
    '10 dakika',
    '15 dakika',
    '20 dakika'
  ];

  void dersiKaydet() {
    if (secilenTarih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarih seçmeden ders kaydedemezsiniz')),
      );
      return;
    }

    FirebaseFirestore.instance.collection('dersler').add({
      'dersAdi': dersAdiController.text.trim(),
      'bolum': bolumController.text.trim(),
      'derslik': derslikController.text.trim(),
      'saat': saatController.text.trim(),
      'yoklamaSayisi': secilenYoklamaSayisi,
      'tarih': secilenTarih,
      'sure': secilenSure,
      'olusturmaTarihi': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ders bilgisi kaydedildi.')),
    );

    dersAdiController.clear();
    bolumController.clear();
    derslikController.clear();
    saatController.clear();
    setState(() {
      secilenYoklamaSayisi = null;
      secilenTarih = null;
      secilenSure = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ders Tanımlama')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ders Tanımı',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: dersAdiController,
              decoration: const InputDecoration(labelText: 'Ders İsmi'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: bolumController,
                    decoration: const InputDecoration(labelText: 'Bölüm'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: derslikController,
                    decoration: const InputDecoration(labelText: 'Derslik'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: saatController,
              decoration: const InputDecoration(labelText: 'Saat'),
            ),
            const SizedBox(height: 30),
            const Text('Kaç yoklama almak istiyorsun?',
                style: TextStyle(fontSize: 16)),
            Column(
              children: [
                RadioListTile<int>(
                  title: const Text('1 Yoklama (blok)'),
                  value: 1,
                  groupValue: secilenYoklamaSayisi,
                  onChanged: (val) =>
                      setState(() => secilenYoklamaSayisi = val),
                ),
                RadioListTile<int>(
                  title: const Text('2 Yoklama (tek ara)'),
                  value: 2,
                  groupValue: secilenYoklamaSayisi,
                  onChanged: (val) =>
                      setState(() => secilenYoklamaSayisi = val),
                ),
                RadioListTile<int>(
                  title: const Text('3 Yoklama (2 ara)'),
                  value: 3,
                  groupValue: secilenYoklamaSayisi,
                  onChanged: (val) =>
                      setState(() => secilenYoklamaSayisi = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Hangi günün yoklamasını almak istiyorsunuz?'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          secilenTarih = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Tarih',
                      ),
                      child: Text(secilenTarih == null
                          ? 'Tarih Seç'
                          : DateFormat('dd/MM/yyyy').format(secilenTarih!)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Yoklamaya katılım süresini seçiniz:'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Süre',
              ),
              items: sureSecenekleri
                  .map((sure) =>
                      DropdownMenuItem(value: sure, child: Text(sure)))
                  .toList(),
              value: secilenSure,
              onChanged: (value) => setState(() => secilenSure = value),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: dersiKaydet,
                child: const Text('Dersi Kaydet'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
