// Drop-in Gradle Kotlin DSL (build.gradle.kts) Signing Configuration
// 1. Reuses a single consistent debug keystore across all debug builds and git worktrees
// 2. Reads production release signing credentials strictly from environment variables

import java.io.File

android {
    signingConfigs {
        getByName("debug") {
            // Optional custom debug keystore via env var; otherwise falls back to standard shared ~/.android/debug.keystore
            val sharedDebugPath = System.getenv("ANDROID_DEBUG_KEYSTORE_PATH")
                ?: "${System.getProperty("user.home")}/.android/debug.keystore"
            val sharedDebugFile = File(sharedDebugPath)
            if (sharedDebugFile.exists()) {
                storeFile = sharedDebugFile
                storePassword = System.getenv("ANDROID_DEBUG_KEYSTORE_PASSWORD") ?: "android"
                keyAlias = System.getenv("ANDROID_DEBUG_KEY_ALIAS") ?: "androiddebugkey"
                keyPassword = System.getenv("ANDROID_DEBUG_KEY_PASSWORD") ?: "android"
            }
        }

        create("release") {
            val releaseKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
            val releaseKeystoreFile = releaseKeystorePath?.let { File(it) }
            if (releaseKeystoreFile != null && releaseKeystoreFile.exists()) {
                storeFile = releaseKeystoreFile
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            isMinifyEnabled = true
            val releaseSigning = signingConfigs.getByName("release")
            if (releaseSigning.storeFile != null) {
                signingConfig = releaseSigning
            }
        }
    }
}
