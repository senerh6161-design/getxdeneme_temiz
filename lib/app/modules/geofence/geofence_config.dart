import 'package:latlong2/latlong.dart';

/// Takip edilecek bölgenin (iş yeri / ev vs.) sabit tanımı.
///
/// Koordinatları nasıl alacaksın:
/// 1. Google Maps'i aç (telefon veya tarayıcı).
/// 2. Bölgenin her köşesine basılı tut → çıkan koordinatlara dokun, kopyala.
/// 3. En az 3 (tercihen 4-6) köşe noktasını sırayla (saat yönünde ya da
///    tersi, fark etmez) aşağıdaki listeye ekle.
///
/// AŞAĞIDAKİ DEĞERLER SADECE ÖRNEKTİR (İstanbul, Kadıköy civarı) —
/// mutlaka kendi bölgenin gerçek koordinatlarıyla değiştir.
class GeofenceConfig {
  static const String regionName = 'İş Yeri';

  static const List<LatLng> regionPolygon = [
    LatLng(40.9905, 29.0280),
    LatLng(40.9905, 29.0310),
    LatLng(40.9880, 29.0310),
    LatLng(40.9880, 29.0280),
  ];

  /// Harita ilk açıldığında odaklanacağı merkez nokta (poligonun ortalaması).
  static LatLng get regionCenter {
    double latSum = 0, lngSum = 0;
    for (final p in regionPolygon) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / regionPolygon.length, lngSum / regionPolygon.length);
  }
}
