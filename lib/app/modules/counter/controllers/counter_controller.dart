import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Artık sayaç manuel butonla değil, GeofenceController'ın işe girişte
/// yazdığı 'count' alanını CANLI (realtime) dinleyerek çalışıyor.
/// Bu controller'ın tek işi: Firestore'daki count'u okuyup ekrana yansıtmak.
/// Yazma işini artık GeofenceController yapıyor
/// (bkz. GeofenceController._incrementAttendanceIfNewDay).
class CounterController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var count = 0.obs;

  // Kullanıcının son işe gittiği günler (arayüzde "Son Gidilen Günler"
  // listesi olarak gösteriliyor). Her eleman sadece yıl/ay/gün taşıyor,
  // saat bilgisi yok — aynı günü sadece bir kere göstermek istiyoruz.
  RxList<DateTime> attendanceDays = <DateTime>[].obs;

  @override
  void onInit() {
    super.onInit();

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _bindCount(user.uid);
        _bindAttendanceDays(user.uid);
      } else {
        count.value = 0;
        attendanceDays.clear();
      }
    });
  }

  void _bindCount(String uid) {
    count.bindStream(
      _firestore.collection('users').doc(uid).snapshots().map((doc) {
        final data = doc.data();
        if (data == null || !data.containsKey('count')) return 0;
        // Firestore'dan dynamic geliyor; beklenmedik bir tip gelirse
        // (null, String vs.) çökmemesi için num'a güvenli şekilde çeviriyoruz.
        return (data['count'] as num?)?.toInt() ?? 0;
      }),
    );
  }

  // Bu sorgu, Rapor ekranının (ReportController) kullandığı aynı
  // 'geofence_events' koleksiyonunu okuyor. Ama burada Firestore'a sadece
  // "uid'si bana ait olan son 30 olay" diye soruyoruz — "İş Yeri" ve
  // "enter" filtresini Firestore'a değil, gelen veri üzerinde Dart
  // tarafında uyguluyoruz. Böylece ReportController zaten oluşturduğumuz
  // index'i tekrar kullanabiliyoruz, ayrı bir Firestore index'i
  // oluşturmamıza gerek kalmıyor.
  void _bindAttendanceDays(String uid) {
    attendanceDays.bindStream(
      _firestore
          .collection('geofence_events')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots()
          .map((snapshot) {
        final days = <DateTime>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data['type'] != 'enter') continue;
          if (data['regionName'] != 'İş Yeri') continue;
          final ts = data['timestamp'] as Timestamp?;
          if (ts == null) continue;
          final d = ts.toDate();
          days.add(DateTime(d.year, d.month, d.day));
        }
        return days;
      }),
    );
  }
}
