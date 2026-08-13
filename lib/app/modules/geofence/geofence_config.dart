import 'package:latlong2/latlong.dart';

/// Tek bir bölgeyi (isim + sınır köşeleri) temsil eder.
class GeofenceRegion {
  final String name;
  final List<LatLng> polygon;

  const GeofenceRegion({required this.name, required this.polygon});

  /// Bu bölgenin köşelerinin ortalaması (haritayı bu bölgeye odaklamak için).
  LatLng get center {
    double latSum = 0, lngSum = 0;
    for (final p in polygon) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / polygon.length, lngSum / polygon.length);
  }
}

/// Takip edilecek bölgelerin (iş yeri, ev, vs.) sabit tanımı.
///
/// Koordinatları nasıl alacaksın:
/// 1. Google Maps'i aç (telefon veya tarayıcı).
/// 2. Bölgenin her köşesine basılı tut → çıkan koordinatlara dokun, kopyala.
/// 3. En az 3 (tercihen 4-6) köşe noktasını sırayla (saat yönünde ya da
///    tersi, fark etmez) aşağıdaki listeye ekle.
class GeofenceConfig {
  static const List<GeofenceRegion> regions = [
    GeofenceRegion(
      name: 'İş Yeri',
      // Gerçek konum: (40.7560115, 29.8174867) merkez alınarak, etrafında
      // ~100m x 100m'lik bir kare bölge oluşturuldu (tek nokta verildiği
      // için köşeler otomatik hesaplandı).
      polygon: [
        LatLng(40.7564607, 29.8168938),
        LatLng(40.7564607, 29.8180797),
        LatLng(40.7555623, 29.8180797),
        LatLng(40.7555623, 29.8168938),
      ],
    ),
    GeofenceRegion(
      name: 'Ev',
      // Gerçek konum: (40.7239751, 29.9950665) merkez alınarak, aynı
      // şekilde ~100m x 100m'lik bir kare oluşturuldu.
      polygon: [
        LatLng(40.7244242, 29.9944738),
        LatLng(40.7244242, 29.9956591),
        LatLng(40.7235259, 29.9956591),
        LatLng(40.7235259, 29.9944738),
      ],
    ),
  ];

  /// Harita ilk açıldığında odaklanacağı nokta — ilk bölgenin merkezi.
  /// (Bölgeler birbirinden uzaksa hepsini aynı anda ekrana sığdırmak yerine
  /// birinden başlıyoruz; kullanıcı konumu alındığında harita zaten oraya
  /// otomatik kayıyor.)
  static LatLng get initialCenter => regions.first.center;
}
