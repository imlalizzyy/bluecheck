import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // provider paketi
import 'firebase_options.dart';

import 'theme_provider.dart'; // theme_provider.dart dosyanın kendisi
import 'splash_ekrani.dart';
import 'drawer.dart';
import 'giris_ekrani.dart';
import 'bilgilerim.dart';
import 'ayarlar_sayfasi.dart';
import 'bilgilerimi_duzenle.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'BlueCheck',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode, // Tema durumu dinleniyor
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
      ),

      // 🌍 Türkçe gün/tarih için locale ayarı
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🌟 Ana başlangıç sayfası (Splash sonrası yönlendirilecek)
      home: const SplashEkrani(),

      // 🌐 Sayfa yönlendirmeleri
      routes: {
        '/giris': (context) => const GirisEkrani(),
        '/anasayfa': (context) => const HomeScreen(),
        '/bilgilerim': (context) => const BilgilerimSayfasi(),
        '/ayarlar': (context) => const AyarlarSayfasi(),
        '/duzenle': (context) => const BilgilerimiDuzenle(),

        // '/login' rotası yok, bu yüzden kullanma veya aynı anlama gelen '/giris' var
      },
    );
  }
}

// 🔵 Ana sayfa (Drawer burada)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ana Sayfa")),
      drawer: const MyDrawer(),
      body: const Center(child: Text("Hoş geldiniz!")),
    );
  }
}
