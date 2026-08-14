import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Bildirim gösterme işini tek yerde toplayan servis.
/// GeofenceController bu sınıfın detaylarını bilmek zorunda değil,
/// sadece "bir giriş/çıkış oldu" der, gerisini bu sınıf halleder
/// (Single Responsibility Principle).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'geofence_channel', // kanal id'si
    'Bölge Bildirimleri', // kullanıcıya görünen kanal adı
    channelDescription: 'İş yeri / ev bölgesine giriş-çıkış bildirimleri',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Uygulama açılırken bir kere çağrılır (main.dart'tan).
  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Android 13+ (API 33) ve iOS'ta bildirim göstermek için runtime izni
    // istenmesi zorunlu — konum izniyle aynı mantık.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showRegionNotification({
    required String regionName,
    required bool isEnter,
  }) async {
    final title = isEnter ? 'Bölgeye girdin' : 'Bölgeden çıktın';
    final body = isEnter
        ? '$regionName bölgesine giriş yaptın.'
        : '$regionName bölgesinden çıktın.';

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // benzersiz bildirim id'si
      title,
      body,
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
