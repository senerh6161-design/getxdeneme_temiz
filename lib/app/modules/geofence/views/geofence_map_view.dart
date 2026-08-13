import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../controllers/geofence_controller.dart';
import '../geofence_config.dart';

class GeofenceMapView extends StatelessWidget {
  const GeofenceMapView({super.key});

  // Çok uzaklaşınca (dünya/ülke görünümü) OpenStreetMap'in ücretsiz
  // katmanı İngilizce etiketlere düşüyor; bizim ihtiyacımız zaten sadece
  // bölge çevresini görmek olduğu için o kadar uzaklaşmayı engelliyoruz.
  static const double _minZoom = 12;
  static const double _maxZoom = 19;

  // Birden fazla bölgeyi haritada birbirinden ayırt etmek için renk sırası.
  static const List<Color> _regionColors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.deepOrange,
  ];

  @override
  Widget build(BuildContext context) {
    final GeofenceController controller = Get.put(GeofenceController());

    void zoomBy(double delta) {
      final camera = controller.mapController.camera;
      final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
      controller.mapController.move(camera.center, newZoom);
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
                      initialCenter: GeofenceConfig.initialCenter,
                      initialZoom: 16,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      // Fare tekerleği ile de zoom yapılabilsin (masaüstünde/
                      // emülatörde pinch-zoom yapmak zor olduğu için).
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.hayrunnisa.getxdeneme',
                      ),
                      PolygonLayer(
                        polygons: [
                          for (var i = 0; i < GeofenceConfig.regions.length; i++)
                            Polygon(
                              points: GeofenceConfig.regions[i].polygon,
                              color: _regionColors[i % _regionColors.length]
                                  .withOpacity(0.25),
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
                              : () => controller.mapController.move(
                                    controller.currentPosition.value!,
                                    16,
                                  ),
                        ),
                      ),
                    ],
                  ),
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
                  // Her bölge için ayrı bir durum satırı.
                  for (final region in GeofenceConfig.regions)
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
                          Text(
                            (controller.insideByRegion[region.name] ?? false)
                                ? '${region.name}: içindesin'
                                : '${region.name}: dışındasın',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
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
