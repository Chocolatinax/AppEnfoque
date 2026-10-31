import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firmas de Android (Firebase solo deja iniciar sesión con Google a apps con firma registrada):
// - flutter run: llave de prueba compartida en el repo (floria-debug.jks), así funciona
//   en cualquier computadora sin pasar archivos.
// - APK final: llave privada de Floria si existe android/key.properties (no se sube a git).
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) load(FileInputStream(file))
}
val hasFloriaKey = keyProperties.getProperty("storeFile") != null

android {
    namespace = "sv.esen.floria"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requerido por flutter_local_notifications (notificaciones programadas)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "sv.esen.floria"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("floriaDebug") {
            storeFile = file("floria-debug.jks")
            storePassword = "floria-debug"
            keyAlias = "floria-debug"
            keyPassword = "floria-debug"
        }
        if (hasFloriaKey) {
            create("floria") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("floriaDebug")
        }
        release {
            signingConfig = if (hasFloriaKey) signingConfigs.getByName("floria")
                            else signingConfigs.getByName("floriaDebug")
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

dependencies {
    // Requerido por flutter_local_notifications (notificaciones programadas)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
