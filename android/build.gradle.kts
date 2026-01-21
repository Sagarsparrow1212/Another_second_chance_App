import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

buildscript {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    dependencies {
        // Android Gradle Plugin (Stable & Recommended)
        classpath("com.android.tools.build:gradle:8.5.2")

        // Kotlin Gradle Plugin (matches AGP)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}

/**
 * Repositories for all modules
 */
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/**
 * Configure a single shared build directory
 * (Recommended for Flutter + multi-module projects)
 */
val sharedBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(sharedBuildDir)

/**
 * Configure build directories for subprojects
 */
subprojects {
    val moduleBuildDir = sharedBuildDir.dir(project.name)
    layout.buildDirectory.value(moduleBuildDir)

    // Ensure :app is evaluated first (Flutter requirement)
    evaluationDependsOn(":app")
}

/**
 * Clean task (modern API)
 */
tasks.register<Delete>("clean") {
    delete(sharedBuildDir)
}
