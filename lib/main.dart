import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/modules/counter/bindings/counter_binding.dart';
import 'app/modules/counter/controllers/auth_controller.dart';
import 'app/modules/counter/views/counter_view.dart';
import 'app/modules/counter/views/login_view.dart';
import 'app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase başlatma uyarısı: $e");
  }

  await NotificationService.instance.init();

  runApp(
    GetMaterialApp(
      title: "GetX Uygulaması",
      debugShowCheckedModeBanner: false,
      initialBinding: CounterBinding(),
      // Açık ve koyu tema tanımlı; themeMode: ThemeMode.system sayesinde
      // kullanıcının telefon ayarına göre otomatik geçiş yapılıyor.
      // NOT: login_view.dart gibi bazı ekranlarda hâlâ sabit (hardcoded)
      // renkler var (ör. Colors.blue.shade50) — bunlar dark mode'da da
      // aynı kalır. Tüm ekranları tema-duyarlı hale getirmek ayrı,
      // daha kapsamlı bir iş; bilerek bu bölümün dışında bıraktık.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    ),
  );
}

// Kullanıcı giriş yapmış mı yapmamış mı kontrol eden "kapı" widget'ı
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.put(AuthController());

    return Obx(() {
      if (authController.firebaseUser.value == null) {
        // Giriş yapılmamış
        return const LoginView();
      } else {
        // Giriş yapılmış
        return const CounterView();
      }
    });
  }
}