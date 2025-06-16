plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.faceabsensiapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // --- PERUBAHAN DI SINI ---
        // Ganti 'coreLibraryDesugaringEnabled' menjadi 'isCoreLibraryDesugaringEnabled'
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString() // Pastikan ini juga disetel ke 1.8
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.faceabsensiapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // Sangat disarankan untuk diaktifkan jika menggunakan desugaring
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
    // Pastikan dependensi kotlin-stdlib-jdk8 ada atau sesuai dengan jvmTarget Anda
    implementation(kotlin("stdlib-jdk8"))

    // Tambahkan dependensi ini untuk core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.0")
}
