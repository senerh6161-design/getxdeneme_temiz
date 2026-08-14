import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxdeneme/app/modules/geofence/models/region_model.dart';

void main() {
  group('RegionModel', () {
    test('fromMap doğru şekilde parse ediyor', () {
      final region = RegionModel.fromMap('region1', {
        'name': 'İş Yeri',
        'center': const GeoPoint(40.756, 29.817),
        'radiusMeters': 150,
      });

      expect(region.id, 'region1');
      expect(region.name, 'İş Yeri');
      expect(region.center.latitude, 40.756);
      expect(region.radiusMeters, 150);
    });

    test('radiusMeters eksikse varsayılan 100 kullanılıyor', () {
      final region = RegionModel.fromMap('region2', {
        'name': 'Ev',
        'center': const GeoPoint(40.724, 29.995),
      });

      expect(region.radiusMeters, 100);
    });

    test('toMap → fromMap round-trip veri kaybetmiyor', () {
      final original = RegionModel(
        id: 'x',
        name: 'Test',
        center: const GeoPoint(1, 2),
        radiusMeters: 75,
      );
      final restored = RegionModel.fromMap('x', original.toMap());

      expect(restored.name, original.name);
      expect(restored.radiusMeters, original.radiusMeters);
    });
  });
}
