plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.getx_sayac"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // flutter_local_notifications paketi, Android'in eski (Java 8 öncesi)
        // API'lerini yeni Java syntax'ıyla kullanabilmek için "core library
        // desugaring" adı verilen bir dönüştürme adımına ihtiyaç duyuyor.
        // Aşağıdaki satır bunu derleme sırasında aktif ediyor.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.getx_sayac"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Yukarıdaki isCoreLibraryDesugaringEnabled ayarının çalışması için
    // gereken kütüphane. Sürüm numarası flutter_local_notifications'ın
    // istediği minimum sürümle uyumlu.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}