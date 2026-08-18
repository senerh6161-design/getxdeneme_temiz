import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/counter_controller.dart';
import '../controllers/auth_controller.dart';
import 'users_view.dart';
import '../../geofence/views/geofence_map_view.dart';
import '../../geofence/views/geofence_report_view.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _SayacEkraniBody(),
    const UsersView(),
    const GeofenceMapView(),
    const GeofenceReportView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Sayaç',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Kullanıcılar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Harita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Rapor',
          ),
        ],
      ),
    );
  }
}

class _SayacEkraniBody extends StatelessWidget {
  const _SayacEkraniBody();

  @override
  Widget build(BuildContext context) {
    final CounterController controller = Get.put(CounterController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayaç Uygulaması'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              authController.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Hangi kullanıcının giriş yaptığını gösteren küçük profil alanı.
            // authController.firebaseUser reaktif (Rx) olduğu için Obx
            // içine alıyoruz; kullanıcı değişirse (çıkış/giriş) otomatik
            // güncellenir.
            Obx(() {
              final email = authController.firebaseUser.value?.email ?? '';
              return Column(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }),
            const SizedBox(height: 28),
            const Icon(Icons.work_outline, size: 48, color: Colors.blueGrey),
            const SizedBox(height: 12),
            const Text(
              'İşe Gidilen Gün Sayısı',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            // Artık manuel buton yok: bu sayı, GeofenceController'ın
            // "İş Yeri" bölgesine giriş algıladığı her yeni günde
            // otomatik olarak +1 artırdığı değer (bkz. Bölüm 1 notları).
            Obx(
              () => Text(
                '${controller.count.value}',
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu değer, "Harita" sekmesinden iş yeri bölgesine\ngirdiğinde otomatik güncellenir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
