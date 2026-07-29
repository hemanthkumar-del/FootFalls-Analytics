allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("org.tensorflow:tensorflow-lite:2.16.1")
            force("org.tensorflow:tensorflow-lite-gpu:2.16.1")
            force("org.tensorflow:tensorflow-lite-api:2.16.1")
            force("org.tensorflow:tensorflow-lite-gpu-api:2.16.1")
            force("org.tensorflow:tensorflow-lite-support:0.4.4")
        }
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
    
    afterEvaluate {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
        if (android != null) {
            android.compileSdk = 36
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
