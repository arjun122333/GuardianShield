allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // 1. Programmatically patch the Manifest to remove 'package' attribute
            // This is required because AGP 8.0+ forbids 'package' in Manifest when 'namespace' is used
            val manifestFile = project.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                try {
                    val content = manifestFile.readText()
                    if (content.contains("package=")) {
                        // Extract original package for namespace if not set
                        if (android.namespace == null) {
                            val match = Regex("""package="([^"]*)"""").find(content)
                            if (match != null) {
                                android.namespace = match.groupValues[1]
                            }
                        }
                        // Remove the package attribute
                        val newContent = content.replace(Regex("""\s+package="[^"]*""""), "")
                        manifestFile.writeText(newContent)
                        logger.lifecycle("Patched manifest for ${project.name}: Removed package attribute")
                    }
                } catch (e: Exception) {
                    logger.warn("Failed to patch manifest for ${project.name}: ${e.message}")
                }
            }

            // 2. Ensure a namespace exists for AGP 8+
            if (android.namespace == null) {
                android.namespace = "com.guardianshield.app.plugin.${project.name.replace("-", "_")}"
            }

            // 3. Align compileSdk and other versions across all plugins
            android.compileSdkVersion(35)
            android.defaultConfig {
                minSdkVersion(23)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
