import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/geofence_event_model.dart';

/// Son 7 gündeki giriş/çıkış olaylarını Firestore'dan çekip raporlayan
/// controller.
class ReportController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxList<GeofenceEventModel> events = <GeofenceEventModel>[].obs;
  RxBool isLoading = true.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLastWeek();
  }

  int get enterCount => events.where((e) => e.type == 'enter').length;
  int get exitCount => events.where((e) => e.type == 'exit').length;

  Future<void> loadLastWeek() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('geofence_events')
          .where('uid', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .orderBy('timestamp', descending: true)
          .get();

      events.value =
          snapshot.docs.map((d) => GeofenceEventModel.fromMap(d.data())).toList();
    } catch (e) {
      // NOT: Firestore bu sorgu için ilk çalıştırmada "composite index"
      // isteyebilir. Hata mesajında/konsolda çıkan linke tıklayıp
      // Firebase Console'da indexi bir kere oluşturman yeterli.
      errorMessage.value = 'Rapor yüklenirken hata oluştu: $e';
      events.value = [];
    } finally {
      isLoading.value = false;
    }
  }
}
