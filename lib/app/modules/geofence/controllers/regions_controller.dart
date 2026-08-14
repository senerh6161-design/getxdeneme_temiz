import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/region_model.dart';

/// Kullanıcının kendi bölgelerini (İş Yeri, Ev, vs.) Firestore üzerinden
/// yönetmesini sağlayan controller. Artık bölgeler geofence_config.dart'a
/// sabit kodlanmış değil, 'users/{uid}/regions' alt-koleksiyonunda duruyor.
class RegionsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList<RegionModel> regions = <RegionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _bindRegions(user.uid);
      } else {
        regions.value = [];
      }
    });
  }

  void _bindRegions(String uid) {
    regions.bindStream(
      _firestore.collection('users').doc(uid).collection('regions').snapshots().map(
            (snap) => snap.docs.map((d) => RegionModel.fromMap(d.id, d.data())).toList(),
          ),
    );
  }

  Future<void> addRegion(String name, GeoPoint center, double radiusMeters) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('regions').add(
          RegionModel(id: '', name: name, center: center, radiusMeters: radiusMeters).toMap(),
        );
  }

  Future<void> deleteRegion(String regionId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('regions')
        .doc(regionId)
        .delete();
  }
}
