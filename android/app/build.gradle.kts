plugins {
    id("com.android.application")
    // El plugin de Flutter debe ir después del de Android (añade Kotlin automáticamente)
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin necesario para inyectar google-services.json
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.crisis_map_natural"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.crisis_map_natural"
        // Firebase necesita como mínimo la API 23; Flutter ya usa una superior.
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

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
