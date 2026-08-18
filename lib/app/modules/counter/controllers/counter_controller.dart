import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';

/// Sayaç iki ayrı sistemin bir arada çalıştığı ekran:
/// - GeofenceController hâlâ konum tabanlı giriş/çıkışı 'geofence_events'e
///   kaydediyor, Rapor ekranı bunu gösteriyor (bkz. GeofenceController).
/// - Ama "İşe Gidilen Gün Sayısı" artık OTOMATİK artmıyor — kullanıcı
///   Sayaç ekranındaki butona basarak kendisi bildiriyor (increment()).
/// Bu controller'ın işi: Firestore'daki count'u CANLI okuyup ekrana
/// yansıtmak, ve butona basılınca +1 yazmak.
class CounterController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var count = 0.obs;
  var isIncrementing = false.obs;

  @override
  void onInit() {
    super.onInit();

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _bindCount(user.uid);
      } else {
        count.value = 0;
      }
    });

    // count her değiştiğinde (Firestore'dan yeni bir değer geldiğinde)
    // bunu ana ekran widget'ına da yansıt. `ever`, GetX'in "bu Rx değer
    // her değiştiğinde şu fonksiyonu çalıştır" yardımcı fonksiyonu.
    ever(count, _updateHomeWidget);
  }

  Future<void> _updateHomeWidget(int value) async {
    // 1) Veriyi native (Android) tarafın okuyabileceği ortak bir yere kaydet.
    await HomeWidget.saveWidgetData<String>('count', value.toString());
    // 2) Android'e "widget'ı yeniden çiz" sinyali gönder — bu, native
    // tarafta yazdığımız HomeWidgetProvider.onUpdate()'i tetikliyor.
    await HomeWidget.updateWidget(androidName: 'HomeWidgetProvider');
  }

  /// Kullanıcı "İşe Gittim" butonuna basınca çağrılıyor. Firestore'a
  /// atomik bir "+1 yap" komutu gönderiyoruz (FieldValue.increment) —
  /// önce okuyup sonra +1 yazmak yerine bunu tercih ediyoruz, çünkü
  /// aradaki kısa sürede başka bir yazma olsa bile değer kaybolmuyor.
  Future<void> increment() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isIncrementing.value = true;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'count': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } finally {
      isIncrementing.value = false;
    }
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
}
