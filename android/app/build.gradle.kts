import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release imzolash (signing) sozlamalari — android/key.properties fayldan o'qiladi.
// Fayl android/ ichida bo'lishi kerak (android/app/ ICHIDA EMAS).
// Fayl topilmasa, build buzilib qolmasligi uchun release ham debug kalit bilan
// yig'iladi — lekin bunday holatda Play Store'ga chiqarib bo'lmaydi.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

gradle.taskGraph.whenReady {
    if (!hasReleaseKeystore && allTasks.any { it.name.contains("Release", ignoreCase = true) }) {
        throw GradleException("Release signing requires android/key.properties")
    }
}

android {
    namespace = "com.tajvid_yoli"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.tajvid_yoli"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                null
            }

            // Kichikroq va optimallashtirilgan APK uchun. AGAR biror funksiya
            // FAQAT release build'da ishlamay qolsa — avval shu ikkalasini
            // false qilib tekshiring, muammo odatda proguard-rules.pro'da
            // yetishmayotgan "keep" qoidasi bo'ladi.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        debug {
            isMinifyEnabled = false
        }
    }

    // Firebase va boshqa kutubxonalar bir xil META-INF fayllarni qo'shishi
    // sabab bo'ladigan "Duplicate class" / "More than one file was found"
    // build xatolarining oldini oladi.
    packaging {
        resources {
            excludes += setOf(
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

// Kotlin kompilyatsiya sozlamalari — eski "kotlinOptions" Kotlin 2.x'da endi
// ishlamaydi, shuning uchun "compilerOptions" DSL'ga o'tkazildi.
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}

// Ba'zi kutubxonalar turli xil androidx versiyalarini talab qilib, versiya
// to'qnashuviga sabab bo'lgani uchun quyidagi versiyalar qat'iy belgilangan.
// Yangi plagin qo'shganda versiya konflikti chiqsa — shu ro'yxatni yangilang.
configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity:1.9.3")
        force("androidx.activity:activity-ktx:1.9.3")
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.lifecycle:lifecycle-viewmodel:2.8.7")
        force("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
        force("androidx.lifecycle:lifecycle-runtime:2.8.7")
        force("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    }
}