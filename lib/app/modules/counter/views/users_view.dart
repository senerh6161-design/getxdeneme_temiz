import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/users_controller.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı bu sayfaya enjekte ediyoruz
    final UsersController usersController = Get.put(UsersController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm Kullanıcılar'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (usersController.userList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: usersController.userList.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final user = usersController.userList[index];

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.email.isNotEmpty ? user.email[0].toUpperCase() : 'U',
                  ),
                ),
                title: Text(
                  user.email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('UID: ${user.uid.substring(0, 8)}...'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sayaç: ${user.count}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}