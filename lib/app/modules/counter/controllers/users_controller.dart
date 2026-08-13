import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../user_model.dart'; // Yapına göre user_model tam bir üst klasörde (counter altında)

class UsersController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reaktif Kullanıcı Listesi
  RxList<UserModel> userList = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    bindUserStream();
  }

  void bindUserStream() {
    // Firestore 'users' koleksiyonundaki anlık verileri dinler
    userList.bindStream(
      _firestore.collection('users').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserModel.fromMap(doc.data(), doc.id);
        }).toList();
      }),
    );
  }
}