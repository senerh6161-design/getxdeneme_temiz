import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CounterController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var count = 0.obs; // .obs ile yazdığımızda bu değişkenin reaktif olduğunu belirtiyoruz.

  // Firestore'dan veri yüklenirken otomatik yazmayı engellemek için
  bool _isLoadingData = false;

  @override
  void onInit() {
    super.onInit();

    // count değeri her değiştiğinde otomatik olarak Firestore'a yazılsın
    ever(count, (_) {
      if (!_isLoadingData) {
        _updateFirestore();
      }
    });

    // Kim giriş/çıkış yaptıysa ona göre sayaç değerini yükle/sıfırla
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserCount(user.uid);
      } else {
        _isLoadingData = true;
        count.value = 0;
        _isLoadingData = false;
      }
    });
  }

  Future<void> _loadUserCount(String uid) async {
    _isLoadingData = true;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('count')) {
        count.value = doc.data()!['count'];
      } else {
        count.value = 0;
      }
    } catch (e) {
      count.value = 0;
    } finally {
      _isLoadingData = false;
    }
  }

  void increment() {
    count++;
  }

  void decrement() {
    if (count.value > 0) count--;
  }

  Future<void> _updateFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return; // Giriş yapılmamışsa bir şey yapma

    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'count': count.value,
    }, SetOptions(merge: true));
  }
}