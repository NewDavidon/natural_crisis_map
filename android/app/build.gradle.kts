plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir antes que el de Google Services
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin necesario para inyectar google-services.json
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.crisis_map_natural"
    compileSdk = flutter.compileSdkVersion

    // Fijamos la versión del NDK requerida por los plugins de Firebase y Geolocator
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.crisis_map_natural"

        // Aumentamos minSdk a 23 para que Firebase Auth y otros módulos funcionen
        minSdk = 23
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
