plugins {
    java
    id("io.quarkus")
    id("io.mvnpm.gradle.plugin.native-java-plugin") version "1.0.0"
}

repositories {
    mavenCentral()
    mavenLocal()
    maven {
        name = "Mvnpm"
        url = uri("https://repo.mvnpm.org/maven2")
    }
}

val quarkusPlatformGroupId: String by project
val quarkusPlatformArtifactId: String by project
val quarkusPlatformVersion: String by project

dependencies {
    implementation(enforcedPlatform("${quarkusPlatformGroupId}:${quarkusPlatformArtifactId}:${quarkusPlatformVersion}"))
    implementation("io.quarkus:quarkus-rest")
    implementation("io.quarkiverse.web-bundler:quarkus-web-bundler-svelte:2.3.3")
    compileOnly("org.mvnpm:svelte:5.28.1")
    implementation("io.quarkus:quarkus-rest-jsonb")
    implementation("io.quarkiverse.qute.web:quarkus-qute-web")
    implementation("io.quarkiverse.web-bundler:quarkus-web-bundler-tailwindcss:2.3.3")
    implementation("io.quarkiverse.web-bundler:quarkus-web-bundler:2.3.3")
    implementation("io.quarkus:quarkus-arc")
    testImplementation("io.quarkus:quarkus-junit")
    testImplementation("io.rest-assured:rest-assured")
}

group = "com.tk.learn"
version = "1.0.0-SNAPSHOT"

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
    options.compilerArgs.add("-parameters")
}
