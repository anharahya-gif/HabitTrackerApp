plugins {
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (project.name == "file_picker" || project.name == "home_widget") {
        project.plugins.apply("org.jetbrains.kotlin.android")
    }
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val javaVersion = project.extensions.findByName("android")
            ?.let { it as? com.android.build.gradle.BaseExtension }
            ?.compileOptions
            ?.targetCompatibility

        val targetJvm = when (javaVersion) {
            JavaVersion.VERSION_17 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            JavaVersion.VERSION_11 -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
            else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
        }
        compilerOptions {
            jvmTarget.set(targetJvm)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
