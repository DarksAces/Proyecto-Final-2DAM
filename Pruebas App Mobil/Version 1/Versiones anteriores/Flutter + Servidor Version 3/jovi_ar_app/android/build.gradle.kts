// android/build.gradle.kts

plugins {
    // Definimos el plugin aquí para que esté disponible para el módulo :app
    id("com.google.gms.google-services") version "4.4.0" apply false 
    
    // NOTA: Si usas Kotlin en el proyecto, el plugin de Kotlin también debería definirse aquí.
    // id("org.jetbrains.kotlin.android") version "1.8.0" apply false 
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}