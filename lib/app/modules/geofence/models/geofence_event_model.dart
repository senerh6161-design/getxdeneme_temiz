import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 'geofence_events' koleksiyonundaki tek bir giriş/çıkış kaydı.
class GeofenceEventModel {
  final String type; // 'enter' ya da 'exit'
  final String regionName;
  final DateTime timestamp;

  GeofenceEventModel({
    required this.type,
    required this.regionName,
    required this.timestamp,
  });

  factory GeofenceEventModel.fromMap(Map<String, dynamic> map) {
    final ts = map['timestamp'];
    return GeofenceEventModel(
      type: map['type'] ?? 'enter',
      regionName: map['regionName'] ?? '',
      // Yazıldıktan hemen sonra timestamp henüz sunucudan dönmemiş olabilir,
      // bu durumda geçici olarak "şimdi"yi kullanıyoruz.
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
