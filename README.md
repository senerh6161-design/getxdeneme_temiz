# getxdeneme

GetX ve Firebase (Authentication + Cloud Firestore) kullanılarak yapılmış bir
Flutter öğrenme projesi. Giriş yapan kullanıcının kendi sayaç değerini
Firestore'da tutan bir sayaç uygulamasıyla başladı, üzerine OpenStreetMap
tabanlı harita ve bölge (geofence) takip özelliği eklendi: sabit bir bölge
(iş yeri/ev) tanımlanıyor, kullanıcının konumu bu bölgeyle karşılaştırılıp
giriş/çıkış olayları Firestore'a kaydediliyor, son 7 günün raporu ayrı bir
ekranda gösteriliyor.

## Özellikler

- E-posta/şifre ile kayıt ol - giriş yap (Firebase Authentication)
- Kullanıcıya özel, buluta senkron sayaç (Cloud Firestore)
- Tüm kullanıcıların canlı listesi
- Harita üzerinde sabit bir bölge (polygon) gösterimi (flutter_map / OpenStreetMap)
- Konum tabanlı giriş/çıkış tespiti (ray casting algoritması) ve Firestore'a kayıt
- Son 7 günün giriş/çıkış raporu

## Kullanılan teknolojiler

- Flutter / Dart, GetX (state management)
- Firebase Authentication, Cloud Firestore
- flutter_map, latlong2, geolocator

## Notlarım

Bu projeyi yaparken tuttuğum öğrenme notları: [`notlar/Getx_Uygulama_Notlarim.pdf`](notlar/Getx_Uygulama_Notlarim.pdf)

## Başlarken

Bu bir Flutter projesidir:

```
flutter pub get
flutter run
```

Flutter ile ilgili genel kaynaklar için:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter dokümantasyonu](https://docs.flutter.dev/)
