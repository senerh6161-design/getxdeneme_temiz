import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/report_controller.dart';

class GeofenceReportView extends StatelessWidget {
  const GeofenceReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportController controller = Get.put(ReportController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş / Çıkış Raporu'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadLastWeek,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadLastWeek,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Giriş',
                      count: controller.enterCount,
                      color: Colors.green,
                      icon: Icons.login,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Çıkış',
                      count: controller.exitCount,
                      color: Colors.orange,
                      icon: Icons.logout,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Son 7 günde toplam ${controller.events.length} hareket kaydedildi.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (controller.errorMessage.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              if (controller.events.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('Henüz kayıtlı bir giriş/çıkış yok.')),
                )
              else
                ...controller.events.map(
                  (e) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        e.type == 'enter' ? Icons.login : Icons.logout,
                        color: e.type == 'enter' ? Colors.green : Colors.orange,
                      ),
                      title: Text(e.type == 'enter' ? 'Bölgeye giriş' : 'Bölgeden çıkış'),
                      subtitle: Text('${e.regionName} • ${_formatDate(e.timestamp)}'),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          Text(title, style: TextStyle(color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

/// intl paketine ihtiyaç duymadan basit bir tarih/saat biçimlendirme.
String _formatDate(DateTime dt) {
  const months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dt.day)} ${months[dt.month - 1]} ${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
}
