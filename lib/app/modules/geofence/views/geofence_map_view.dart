import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/geofence_controller.dart';
import '../controllers/regions_controller.dart';

class GeofenceMapView extends StatelessWidget {
  const GeofenceMapView({super.key});

  // Çok uzaklaşınca (dünya/ülke görünümü) OpenStreetMap'in ücretsiz
  // katmanı İngilizce etiketlere düşüyor; bizim ihtiyacımız zaten sadece
  // bölge çevresini görmek olduğu için o kadar uzaklaşmayı engelliyoruz.
  static const double _minZoom = 12;
  static const double _maxZoom = 19;

  // Kullanıcı henüz hiç bölge eklememişse ve konumu da gelmemişse
  // haritanın odaklanacağı varsayılan nokta (İstanbul).
  static const LatLng _fallbackCenter = LatLng(41.0082, 28.9784);

  // Birden fazla bölgeyi haritada birbirinden ayırt etmek için renk sırası.
  static const List<Color> _regionColors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.deepOrange,
  ];

  @override
  Widget build(BuildContext context) {
    // RegionsController zaten CounterBinding'te lazyPut ile kayıtlı;
    // burada Get.find ile o tek örneği buluyoruz.
    final RegionsController regionsController = Get.find<RegionsController>();
    final GeofenceController controller = Get.put(GeofenceController());

    void zoomBy(double delta) {
      // Harita widget'ı henüz attach olmadan (ör. ilk açılışta çok hızlı
      // dokunulursa) mapController.camera erişimi istisna fırlatabilir;
      // checkLocation()'daki gibi burada da sessizce yutuyoruz.
      try {
        final camera = controller.mapController.camera;
        final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
        controller.mapController.move(camera.center, newZoom);
      } catch (_) {}
    }

    void goToMyLocation() {
      final position = controller.currentPosition.value;
      if (position == null) return;
      try {
        controller.mapController.move(position, 16);
      } catch (_) {}
    }

    LatLng initialCenter() {
      if (regionsController.regions.isNotEmpty) {
        final c = regionsController.regions.first.center;
        return LatLng(c.latitude, c.longitude);
      }
      return _fallbackCenter;
    }

    Future<void> showAddRegionDialog(LatLng point) async {
      final nameController = TextEditingController();
      final radiusController = TextEditingController(text: '100');

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Yeni Bölge Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Konum: ${point.latitude.toStringAsFixed(6)}, '
                '${point.longitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Bölge adı (ör. İş Yeri)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Yarıçap (metre)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final radius = double.tryParse(radiusController.text.trim()) ?? 100;
                if (name.isEmpty) return;
                await regionsController.addRegion(
                  name,
                  GeoPoint(point.latitude, point.longitude),
                  radius,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bölgelerim'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Obx(
                  () => FlutterMap(
                    mapController: controller.mapController,
                    options: MapOptions(
                      initialCenter: initialCenter(),
                      initialZoom: 16,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      // Fare tekerleği ile de zoom yapılabilsin (masaüstünde/
                      // emülatörde pinch-zoom yapmak zor olduğu için).
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      // Haritaya uzun basarak yeni bölge ekleme.
                      onLongPress: (tapPosition, point) => showAddRegionDialog(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.hayrunnisa.getxdeneme',
                      ),
                      CircleLayer(
                        circles: [
                          for (var i = 0; i < regionsController.regions.length; i++)
                            CircleMarker(
                              point: LatLng(
                                regionsController.regions[i].center.latitude,
                                regionsController.regions[i].center.longitude,
                              ),
                              radius: regionsController.regions[i].radiusMeters,
                              useRadiusInMeter: true,
                              color: _regionColors[i % _regionColors.length]
                                  .withValues(alpha: 0.25),
                              borderColor: _regionColors[i % _regionColors.length],
                              borderStrokeWidth: 2,
                            ),
                        ],
                      ),
                      if (controller.currentPosition.value != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: controller.currentPosition.value!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.red,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      const _OsmAttribution(),
                    ],
                  ),
                ),
                // Büyüt / küçült butonları — pinch-zoom (iki parmakla)
                // özellikle emülatörde fare ile zor olduğundan ekledik.
                Positioned(
                  right: 12,
                  bottom: 90,
                  child: Column(
                    children: [
                      _ZoomButton(icon: Icons.add, onPressed: () => zoomBy(1)),
                      const SizedBox(height: 8),
                      _ZoomButton(icon: Icons.remove, onPressed: () => zoomBy(-1)),
                      const SizedBox(height: 8),
                      Obx(
                        () => _ZoomButton(
                          icon: Icons.my_location,
                          onPressed: controller.currentPosition.value == null
                              ? () {}
                              : goToMyLocation,
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 12,
                  top: 12,
                  right: 12,
                  child: _LongPressHint(),
                ),
              ],
            ),
          ),
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Büyük, göze çarpan "İş Yerindesin / Değilsin" şeridi.
                  // Sadece kullanıcı "İş Yeri" adında bir bölge eklediyse
                  // gösteriliyor — henüz eklemediyse boş yer kaplamasın.
                  if (regionsController.regions.any((r) => r.name == 'İş Yeri'))
                    Builder(
                      builder: (context) {
                        final atWork = controller.insideByRegion['İş Yeri'] ?? false;
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: atWork ? Colors.green.shade50 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: atWork ? Colors.green : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                atWork ? Icons.work : Icons.work_off,
                                color: atWork ? Colors.green.shade700 : Colors.grey.shade600,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  atWork ? 'Şu an İş Yerindesin' : 'Şu an İş Yerinde Değilsin',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: atWork ? Colors.green.shade800 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (regionsController.regions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Henüz bölge eklemedin. Haritaya uzun bas ve ilk '
                        'bölgeni (ör. İş Yeri) oluştur.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  // Her bölge için ayrı bir durum satırı + silme butonu.
                  for (final region in regionsController.regions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            (controller.insideByRegion[region.name] ?? false)
                                ? Icons.check_circle
                                : Icons.location_off,
                            color: (controller.insideByRegion[region.name] ?? false)
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (controller.insideByRegion[region.name] ?? false)
                                  ? '${region.name}: içindesin'
                                  : '${region.name}: dışındasın',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            tooltip: 'Bölgeyi sil',
                            onPressed: () => regionsController.deleteRegion(region.id),
                          ),
                        ],
                      ),
                    ),
                  if (controller.statusMessage.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        controller.statusMessage.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          controller.isLoading.value ? null : controller.checkLocation,
                      icon: controller.isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        controller.isLoading.value
                            ? 'Kontrol ediliyor...'
                            : 'Konumu Kontrol Et',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: Colors.blue.shade700),
        ),
      ),
    );
  }
}

/// Kullanıcıya haritaya uzun basarak bölge ekleyebileceğini hatırlatan
/// küçük bir ipucu şeridi.
class _LongPressHint extends StatelessWidget {
  const _LongPressHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Yeni bölge eklemek için haritaya uzun bas',
        style: TextStyle(fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// OpenStreetMap kullanım şartları gereği harita üzerinde küçük bir
/// kaynak belirtimi (attribution) gösteriyoruz.
class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: ColoredBox(
          color: Color(0xB3FFFFFF),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text('© OpenStreetMap', style: TextStyle(fontSize: 10)),
          ),
        ),
      ),
    );
  }
}
