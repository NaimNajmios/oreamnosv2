@file:Suppress("DEPRECATION")
import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    if (name != "app") {
        afterEvaluate {
            extensions.findByType(BaseExtension::class.java)?.apply {
                // Older Flutter plugins predate AGP 8 namespace support.
                // Derive it from their manifest package when absent.
                if (namespace == null) {
                    val manifest = file("src/main/AndroidManifest.xml")
                    if (manifest.exists()) {
                        val pkg = Regex("""package="([^"]+)"""")
                            .find(manifest.readText())
                            ?.groupValues
                            ?.get(1)
                        namespace = pkg ?: "com.oreamnos.${project.name}"
                    }
                }
                // Old plugins default to compileSdk 31; app compiles at 36
                // and newer AndroidX requires at least 33.
                val sdk = compileSdkVersion as? Int ?: 0
                if (sdk < 33) {
                    compileSdkVersion(36)
                }
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
    
    tasks.withType(KotlinCompile::class.java).configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
