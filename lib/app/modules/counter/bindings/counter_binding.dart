import 'package:get/get.dart';
import '../controllers/counter_controller.dart';
import '../controllers/users_controller.dart';
import '../controllers/auth_controller.dart';

class CounterBinding extends Bindings { // bindings GetX in soyut bir sınıfı
  @override
  void dependencies() {
    Get.lazyPut(() => CounterController());//get.lazyput sadece ihtiyaç duyulduğunda oluşturulur
    Get.lazyPut<UsersController>(() => UsersController());
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
