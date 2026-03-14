import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

android {
    namespace = "com.example.coffix_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.coffix.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flavorDimensions += "app"
    productFlavors {
        create("dev") {
            dimension = "app"
            applicationId = "com.coffix.dev.app"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Coffix Dev")
        }
        create("prod") {
            dimension = "app"
            applicationId = "com.coffix.app"
            resValue("string", "app_name", "Coffix")
        }
    }
}

flutter {
    source = "../.."
}
