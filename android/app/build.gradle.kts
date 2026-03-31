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
        isCoreLibraryDesugaringEnabled = true
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
            isShrinkResources = false
            isMinifyEnabled = false
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


// Source - https://stackoverflow.com/a/79571537
// Posted by Jhaymes
// Retrieved 2026-03-27, License - CC BY-SA 4.0

dependencies{
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
