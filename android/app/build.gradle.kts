import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadProperties = Properties()
val uploadPropertiesFile = rootProject.file("key.properties")
if (uploadPropertiesFile.exists()) {
    uploadPropertiesFile.inputStream().use { uploadProperties.load(it) }
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword").forEach {
        require(!uploadProperties.getProperty(it).isNullOrBlank()) { "Missing $it in android/key.properties" }
    }
}

android {
    namespace = "es.jvrlabs.surtio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "es.jvrlabs.surtio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadPropertiesFile.exists()) {
            create("release") {
                storeFile = rootProject.file(uploadProperties.getProperty("storeFile"))
                storePassword = uploadProperties.getProperty("storePassword")
                keyAlias = uploadProperties.getProperty("keyAlias")
                keyPassword = uploadProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Without key.properties this produces an unsigned verification build.
            // A Play upload always requires the private upload key.
            signingConfig = if (uploadPropertiesFile.exists()) signingConfigs.getByName("release") else null
        }
    }
}

flutter {
    source = "../.."
}
