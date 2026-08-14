import 'package:get/get.dart';
import '../controllers/counter_controller.dart';
import '../controllers/users_controller.dart';
import '../controllers/auth_controller.dart';
import '../../geofence/controllers/regions_controller.dart';

class CounterBinding extends Bindings { // bindings GetX in soyut bir sınıfı
  @override
  void dependencies() {
    Get.lazyPut(() => CounterController());//get.lazyput sadece ihtiyaç duyulduğunda oluşturulur
    Get.lazyPut<UsersController>(() => UsersController());
    Get.lazyPut<AuthController>(() => AuthController());
    // lazyPut sayesinde nerede/ne zaman Get.find<RegionsController>()
    // çağrılırsa çağrılsın (GeofenceController içinden dahi), her zaman
    // aynı tek örnek (singleton) döner — sıralamayla uğraşmamıza gerek kalmaz.
    Get.lazyPut<RegionsController>(() => RegionsController());
  }
}
