import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının kendi eklediği, dairesel (merkez + yarıçap) bir bölge.
/// Firestore'da 'users/{uid}/regions/{regionId}' alt-koleksiyonunda saklanır.
class RegionModel {
  final String id;
  final String name;
  final GeoPoint center; // Firestore'un native konum tipi
  final double radiusMeters;

  RegionModel({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
  });

  factory RegionModel.fromMap(String id, Map<String, dynamic> map) {
    return RegionModel(
      id: id,
      name: map['name'] ?? '',
      center: map['center'] as GeoPoint,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 100,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'center': center,
        'radiusMeters': radiusMeters,
      };
}
