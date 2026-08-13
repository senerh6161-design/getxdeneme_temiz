import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Aktif kullanıcıyı reaktif olarak tutuyoruz
  Rx<User?> firebaseUser = Rx<User?>(null);

  // Giriş/Kayıt ekranındaki hata mesajını göstermek için
  RxString errorMessage = ''.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Firebase'deki oturum durumunu anlık dinliyoruz
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  // Kayıt Ol
  Future<void> register(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'da kullanıcı dokümanını oluşturuyoruz (sayaç 0'dan başlar)
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'count': 0,
      });
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Kayıt sırasında bir hata oluştu.';
    } finally {
      isLoading.value = false;
    }
  }

  // Giriş Yap
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Giriş sırasında bir hata oluştu.';
    } finally {
      isLoading.value = false;
    }
  }

  // Çıkış Yap
  Future<void> logout() async {
    await _auth.signOut();
  }
}