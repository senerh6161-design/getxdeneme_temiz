import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/notification_service.dart';
import 'regions_controller.dart';

/// Kullanıcının anlık konumunu okuyup, RegionsController'dan gelen (artık
/// Firestore'da saklanan, kullanıcının kendi eklediği) TÜM dairesel
/// bölgelere göre içeride/dışarıda olduğunu belirleyen ve her bölge için
/// ayrı ayrı, durum değiştiğinde Firestore'a giriş/çıkış olayı yazan
/// controller. Ayrıca "İş Yeri" bölgesine girişte sayaç artırma ve
/// bildirim gösterme işlerini de tetikler.
class GeofenceController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // RegionsController zaten CounterBinding'te lazyPut ile kayıtlı;
  // burada Get.find ile o TEK örneği buluyoruz (yenisini oluşturmuyoruz).
  final RegionsController _regionsController = Get.find<RegionsController>();

  // Harita üzerinde programatik olarak zoom yapabilmek için
  // (özellikle emülatörde fare ile pinch-zoom yapmak zor olduğundan,
  // ekrandaki +/- butonları bunu kullanacak).
  final MapController mapController = MapController();

  // Haritada göstermek için kullanıcının son bilinen konumu
  Rx<LatLng?> currentPosition = Rx<LatLng?>(null);

  // Her bölge adı için "içeride mi" bilgisi (ör. {'İş Yeri': true, 'Ev': false})
  RxMap<String, bool> insideByRegion = <String, bool>{}.obs;

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

      // Tanımlı her bölge için ayrı ayrı içeride/dışarıda kontrolü yap.
      // Artık poligon değil, "merkeze olan mesafe <= yarıçap" mantığıyla.
      final Map<String, bool> newStatus = {};
      for (final region in _regionsController.regions) {
        final distanceMeters = Geolocator.distanceBetween(
          point.latitude,
          point.longitude,
          region.center.latitude,
          region.center.longitude,
        );
        final inside = distanceMeters <= region.radiusMeters;
        newStatus[region.name] = inside;
        await _handleStateChange(user.uid, user.email ?? '', region.name, inside);
      }
      insideByRegion.value = newStatus;

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

  /// Önceki bilinen durumu 'geofence_state/{uid}' dokümanının
  /// [regionName] alanından okur, değiştiyse 'geofence_events'
  /// koleksiyonuna yeni bir kayıt ekler. Tek dokümanda, bölge adı başına
  /// bir alt-alan (map) tutuyoruz — böylece kaç bölge eklersen ekle
  /// kullanıcı başına hâlâ tek doküman yeterli oluyor.
  Future<void> _handleStateChange(
    String uid,
    String email,
    String regionName,
    bool inside,
  ) async {
    final stateRef = _firestore.collection('geofence_state').doc(uid);
    final stateDoc = await stateRef.get();
    final regionData = stateDoc.data()?[regionName] as Map<String, dynamic>?;
    final wasInside = regionData?['inside'] as bool? ?? false;

    // Bu bölge için ilk kontrolse (kayıt yoksa) ve durum değişmediyse
    // olay yazma, sadece mevcut durumu kaydet.
    final isFirstCheck = regionData == null;

    if (!isFirstCheck && wasInside == inside) return;
    if (isFirstCheck && !inside) {
      // İlk kontrolde zaten dışarıdaysa olay yazmaya gerek yok,
      // sadece başlangıç durumunu kaydet.
      await stateRef.set({
        regionName: {'inside': inside, 'updatedAt': FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));
      return;
    }

    // Buradan sonrasına SADECE gerçek bir durum değişikliği olduğunda
    // ulaşılıyor (early return'lerin altı) — bildirim ve sayaç artırma
    // bu yüzden tam burada tetikleniyor, "ilk kontrol zaten dışarıdaydın"
    // gibi durumlarda çalışmıyor.
    await _firestore.collection('geofence_events').add({
      'uid': uid,
      'email': email,
      'type': inside ? 'enter' : 'exit',
      'regionName': regionName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await NotificationService.instance.showRegionNotification(
      regionName: regionName,
      isEnter: inside,
    );

    if (inside && regionName == 'İş Yeri') {
      await _incrementAttendanceIfNewDay(uid);
    }

    await stateRef.set({
      regionName: {'inside': inside, 'updatedAt': FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
  }

  /// "Kaç gün işe gittin" sayacını günde en fazla bir kez artırır.
  /// Aynı gün içinde birden fazla giriş/çıkış olsa (ör. öğle arası) bile
  /// tekrar sayılmaması için kullanıcı dokümanına 'lastCountedDate'
  /// (ör. "2026-08-14") yazıp bugünle karşılaştırıyoruz.
  Future<void> _incrementAttendanceIfNewDay(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);

    final snap = await userRef.get();
    final lastDate = snap.data()?['lastCountedDate'] as String?;

    if (lastDate == todayKey) return; // bugün zaten sayılmış, tekrar sayma

    // FieldValue.increment(1): "önce oku, sonra +1 yap, sonra yaz" yerine
    // sunucuya atomik bir "+1 yap" komutu gönderiyoruz — iki olay aynı
    // anda tetiklenirse bile sayaç kaybolmaz (race condition riski yok).
    await userRef.set({
      'count': FieldValue.increment(1),
      'lastCountedDate': todayKey,
    }, SetOptions(merge: true));
  }
}
