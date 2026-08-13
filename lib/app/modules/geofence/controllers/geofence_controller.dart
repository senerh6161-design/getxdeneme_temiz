import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../geofence_config.dart';

/// Kullanıcının anlık konumunu okuyup bölgeye (polygon) göre
/// içeride/dışarıda olduğunu belirleyen ve durum değiştiğinde
/// Firestore'a giriş/çıkış olayı yazan controller.
class GeofenceController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Harita üzerinde programatik olarak zoom yapabilmek için
  // (özellikle emülatörde fare ile pinch-zoom yapmak zor olduğundan,
  // ekrandaki +/- butonları bunu kullanacak).
  final MapController mapController = MapController();

  // Haritada göstermek için kullanıcının son bilinen konumu
  Rx<LatLng?> currentPosition = Rx<LatLng?>(null);

  // Kullanıcı şu an bölgenin içinde mi?
  RxBool isInsideRegion = false.obs;

  RxBool isLoading = false.obs;
  RxString statusMessage = ''.obs;
  Rx<DateTime?> lastCheckedAt = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    // Spesifikasyon gereği: uygulama bu ekrana geldiğinde (pratikte
    // giriş yapıldıktan hemen sonra) otomatik olarak bir kez kontrol yapılır.
    checkLocation();
  }

  @override
  void onClose() {
    mapController.dispose();
    super.onClose();
  }

  Future<void> checkLocation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    statusMessage.value = '';

    try {
      final hasPermission = await _ensurePermission();
      if (!hasPermission) {
        statusMessage.value =
            'Konum izni verilmedi. Ayarlardan izin vermen gerekiyor.';
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final point = LatLng(position.latitude, position.longitude);
      currentPosition.value = point;

      // Harita, uygulamanın "senin yerin" olarak algıladığı noktaya
      // otomatik kaysın — böylece bölgeyle karşılaştırmayı gözle de
      // doğrulayabilirsin. Harita henüz tam hazır değilse (çok nadir,
      // ilk açılış anında) hata vermesin diye try/catch içine aldık.
      try {
        mapController.move(point, mapController.camera.zoom);
      } catch (_) {}

      final inside = _isPointInPolygon(point, GeofenceConfig.regionPolygon);
      await _handleStateChange(user.uid, user.email ?? '', inside);

      isInsideRegion.value = inside;
      lastCheckedAt.value = DateTime.now();
    } catch (e) {
      statusMessage.value = 'Konum alınırken hata oluştu: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /// Önceki bilinen durumu 'geofence_state/{uid}' dokümanından okur,
  /// değiştiyse 'geofence_events' koleksiyonuna yeni bir kayıt ekler.
  Future<void> _handleStateChange(
    String uid,
    String email,
    bool inside,
  ) async {
    final stateRef = _firestore.collection('geofence_state').doc(uid);
    final stateDoc = await stateRef.get();
    final wasInside = stateDoc.exists
        ? (stateDoc.data()?['inside'] ?? false) as bool
        : false;

    // İlk kontrolde (kayıt yoksa) ve durum değişmediyse olay yazma,
    // sadece mevcut durumu kaydet.
    final isFirstCheck = !stateDoc.exists;

    if (!isFirstCheck && wasInside == inside) return;
    if (isFirstCheck && !inside) {
      // İlk kontrolde zaten dışarıdaysa olay yazmaya gerek yok,
      // sadece başlangıç durumunu kaydet.
      await stateRef.set({
        'inside': inside,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await _firestore.collection('geofence_events').add({
      'uid': uid,
      'email': email,
      'type': inside ? 'enter' : 'exit',
      'regionName': GeofenceConfig.regionName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await stateRef.set({
      'inside': inside,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Ray casting algoritması: nokta poligonun içinde mi?
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].longitude, yi = polygon[i].latitude;
      final xj = polygon[j].longitude, yj = polygon[j].latitude;

      final intersects = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);
      if (intersects) isInside = !isInside;
      j = i;
    }
    return isInside;
  }
}
