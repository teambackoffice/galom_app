import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    throw GradleException("⚠️ key.properties file not found at ${keystorePropertiesFile.path}")
}

configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity:1.9.3")
        force("androidx.activity:activity-ktx:1.9.3")
    }
}

android {
    namespace = "com.location_tracker_app"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.location_tracker_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 6
        versionName = "1.0.4"
    }

    signingConfigs {
        create("release") {
            val keyAliasValue = keystoreProperties["keyAlias"] as? String
                ?: throw GradleException("keyAlias missing in key.properties")
            val keyPasswordValue = keystoreProperties["keyPassword"] as? String
                ?: throw GradleException("keyPassword missing in key.properties")
            val storeFileValue = keystoreProperties["storeFile"] as? String
                ?: throw GradleException("storeFile missing in key.properties")
            val storePasswordValue = keystoreProperties["storePassword"] as? String
                ?: throw GradleException("storePassword missing in key.properties")

            storeFile = file(storeFileValue)
            storePassword = storePasswordValue
            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // ✅ Required for modern Android & flutter_local_notifications
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.24")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.google.android.gms:play-services-location:21.0.1")
}
