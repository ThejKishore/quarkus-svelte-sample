# Docker Build Scripts

This directory contains automated scripts for building Docker images of the Micro Front-Ends application in different variants.

## Quick Start

```bash
# Build JVM image (recommended for most deployments)
./scripts/build-docker-jvm.sh v1.0.0

# Build Native image (ultra-lightweight, fastest startup)
./scripts/build-docker-native.sh v1.0.0

# Build both variants
./scripts/build-docker-all.sh v1.0.0
```

## Scripts Overview

### `build-docker-jvm.sh`

**Purpose**: Build a standard JVM-based Docker image

**Characteristics**:
- Base Image: `openjdk:21-slim`
- Image Size: 400-500MB
- Startup Time: 2-5 seconds
- Build Time: ~2-3 minutes
- Memory Usage: 300-500MB

**Usage**:
```bash
./scripts/build-docker-jvm.sh [TAG]
```

**Examples**:
```bash
./scripts/build-docker-jvm.sh latest        # Tag: jvm-latest
./scripts/build-docker-jvm.sh v1.0.0        # Tag: jvm-v1.0.0
./scripts/build-docker-jvm.sh prod-2024     # Tag: jvm-prod-2024
```

**Best For**:
- ✅ Standard production deployments
- ✅ When maximum compatibility is needed
- ✅ Traditional infrastructure
- ✅ Debugging and development

---

### `build-docker-native.sh`

**Purpose**: Build a native (GraalVM-compiled) Docker image

**Characteristics**:
- Base Image: `ubi9/ubi-micro` or `distroless/base`
- Image Size: 150-200MB
- Startup Time: <100ms
- Build Time: 5-10 minutes
- Memory Usage: 50-100MB

**Usage**:
```bash
./scripts/build-docker-native.sh [TAG]
```

**Examples**:
```bash
./scripts/build-docker-native.sh latest       # Tag: native-latest
./scripts/build-docker-native.sh v1.0.0       # Tag: native-v1.0.0
```

**Important Notes**:
- Uses container-based compilation (`-Dquarkus.native.container-build=true`)
- Does NOT require GraalVM installed locally
- Requires Docker to be running
- First build takes longest; subsequent builds are faster
- Cannot use certain Java features (reflection, serialization) without configuration

**Best For**:
- ✅ AWS Lambda and serverless deployments
- ✅ Kubernetes clusters (minimal resource usage)
- ✅ Cost-sensitive environments
- ✅ Performance-critical applications
- ✅ Edge computing

---

### `build-docker-all.sh`

**Purpose**: Build both JVM and Native variants in sequence

**Characteristics**:
- Builds `jvm-<TAG>` image
- Builds `native-<TAG>` image
- Creates `jvm-latest` and `native-latest` tags
- Total build time: 10-15 minutes

**Usage**:
```bash
./scripts/build-docker-all.sh [TAG]
```

**Examples**:
```bash
./scripts/build-docker-all.sh latest        # Builds both variants with 'latest' tag
./scripts/build-docker-all.sh v1.0.0        # Builds jvm-v1.0.0 and native-v1.0.0
```

**Output Images**:
```
micro-front-ends:jvm-v1.0.0
micro-front-ends:jvm-latest
micro-front-ends:native-v1.0.0
micro-front-ends:native-latest
```

**Best For**:
- ✅ CI/CD pipelines
- ✅ Building multiple deployment variants at once
- ✅ Creating Docker image registry with both options

---

## Detailed Usage Guide

### Building a JVM Image

```bash
# Build with specific version tag
./scripts/build-docker-jvm.sh v1.0.0

# The script will:
# 1. Verify Dockerfile exists
# 2. Build the Quarkus application with Gradle
# 3. Verify build artifacts
# 4. Create Docker image tagged as 'micro-front-ends:jvm-v1.0.0'
# 5. Create alias 'micro-front-ends:jvm-latest'
# 6. Display image information
```

### Building a Native Image

```bash
# Build with specific version tag
./scripts/build-docker-native.sh v1.0.0

# The script will:
# 1. Verify Dockerfile exists
# 2. Check Docker availability
# 3. Clean build directory
# 4. Build native executable using container compilation
#    (takes 5-10 minutes)
# 5. Verify build artifacts
# 6. Create Docker image
# 7. Display image information and performance notes
```

### Building Both Variants

```bash
# Build both in sequence
./scripts/build-docker-all.sh v1.0.0

# Equivalent to running:
# ./scripts/build-docker-jvm.sh v1.0.0
# ./scripts/build-docker-native.sh v1.0.0
# With nice progress display
```

---

## Running Images Locally

### Test JVM Image
```bash
docker run -p 8080:8080 micro-front-ends:jvm-v1.0.0

# Application available at http://localhost:8080
```

### Test Native Image
```bash
docker run -p 8080:8080 micro-front-ends:native-v1.0.0

# Application available at http://localhost:8080
# Note: Startup is near-instant
```

### View Container Logs
```bash
docker logs -f <container-id>
```

### Stop Container
```bash
docker stop <container-id>
```

---

## Pushing to Docker Registry

### Docker Hub Example
```bash
# Tag image for Docker Hub
docker tag micro-front-ends:jvm-v1.0.0 yourusername/micro-front-ends:jvm-v1.0.0

# Login to Docker Hub
docker login

# Push image
docker push yourusername/micro-front-ends:jvm-v1.0.0
```

### Private Registry Example
```bash
# Tag image for private registry
docker tag micro-front-ends:jvm-v1.0.0 myregistry.com/micro-front-ends:jvm-v1.0.0

# Push to registry
docker push myregistry.com/micro-front-ends:jvm-v1.0.0
```

---

## Image Comparison

### Size Comparison
```bash
docker images micro-front-ends

# Output example:
# REPOSITORY            TAG              SIZE
# micro-front-ends      jvm-v1.0.0       450MB
# micro-front-ends      native-v1.0.0    180MB
```

**Size Reduction**: Native is typically **60-70% smaller**

### Performance Comparison
```bash
# Time startup of JVM version
time docker run --rm micro-front-ends:jvm-v1.0.0 --help
# Typical: ~2-3 seconds

# Time startup of Native version  
time docker run --rm micro-front-ends:native-v1.0.0 --help
# Typical: <100ms (nearly instant)
```

---

## Troubleshooting

### Script Won't Execute
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Verify permissions
ls -la scripts/
# Should show 'x' in permissions: rwxr-xr-x
```

### Build Fails With "Java 21 Not Found"
```bash
# Verify Java version
java -version

# Should output Java 21 or later
# If not available, install appropriate JDK
```

### Docker Build Fails: "Permission Denied"
```bash
# Check Docker daemon is running
docker ps

# If error, restart Docker daemon
# macOS: Click Docker icon in menu, restart
# Linux: sudo systemctl restart docker
```

### Native Build Takes Too Long
```bash
# Normal: First native build takes 5-10 minutes
# This includes:
# - GraalVM native-image compilation
# - Static linking
# - Optimization for minimal size

# Subsequent builds are faster (~2-3 minutes)
```

### "Out of Disk Space" Error
```bash
# Native builds require ~10GB temporary space
# Check available space:
df -h

# If insufficient, clean Docker resources:
docker system prune -a --volumes
```

### Docker Image Has Wrong Version
```bash
# Verify build succeeded and check image:
docker images micro-front-ends

# Retag if needed:
docker tag micro-front-ends:jvm-wrong micro-front-ends:jvm-v1.0.0
```

---

## Environment Variables

### During Build
Scripts use these Gradle properties (in `gradle.properties`):
- `quarkusPlatformGroupId`
- `quarkusPlatformArtifactId`
- `quarkusPlatformVersion`

### During Runtime
```bash
docker run \
  -e QUARKUS_LOG_LEVEL=INFO \
  -e QUARKUS_HTTP_PORT=8080 \
  -p 8080:8080 \
  micro-front-ends:jvm-v1.0.0
```

Common environment variables:
- `QUARKUS_LOG_LEVEL`: INFO, DEBUG, WARN, ERROR
- `QUARKUS_HTTP_PORT`: HTTP port (default: 8080)
- `QUARKUS_HTTP_CORS_ORIGINS`: CORS allowed origins

---

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Build Docker Images

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Java
        uses: actions/setup-java@v3
        with:
          java-version: '21'
      
      - name: Build JVM Image
        run: ./scripts/build-docker-jvm.sh ${{ github.ref_name }}
      
      - name: Build Native Image
        run: ./scripts/build-docker-native.sh ${{ github.ref_name }}
      
      - name: Push to Registry
        run: |
          docker push myregistry/micro-front-ends:jvm-${{ github.ref_name }}
          docker push myregistry/micro-front-ends:native-${{ github.ref_name }}
```

### GitLab CI Example
```yaml
build-docker:
  image: docker:latest
  services:
    - docker:dind
  script:
    - ./scripts/build-docker-all.sh ${CI_COMMIT_TAG}
    - docker push registry.gitlab.com/myorg/micro-front-ends:jvm-${CI_COMMIT_TAG}
    - docker push registry.gitlab.com/myorg/micro-front-ends:native-${CI_COMMIT_TAG}
```

---

## Dockerfile Variants

The project includes multiple Dockerfile variants:

| Variant | Location | Best For |
|---------|----------|----------|
| `Dockerfile.jvm` | `src/main/docker/Dockerfile.jvm` | Standard deployments |
| `Dockerfile.native` | `src/main/docker/Dockerfile.native` | Performance-critical apps |
| `Dockerfile.native-micro` | `src/main/docker/Dockerfile.native-micro` | Ultra-minimal deployments |
| `Dockerfile.legacy-jar` | `src/main/docker/Dockerfile.legacy-jar` | Legacy systems |

Scripts use `.jvm` and `.native` by default. To use other variants, edit the script's `DOCKERFILE` variable.

---

## Image Labels

Generated images include metadata labels:
```bash
docker inspect micro-front-ends:jvm-v1.0.0 | grep -A 5 Labels

# Output:
# "Labels": {
#   "com.example.app.build-date": "2026-08-14T22:36:57Z",
#   "com.example.app.build-type": "jvm",
#   "com.example.app.version": "v1.0.0"
# }
```

---

## Performance Checklist

- [ ] JVM image tested locally
- [ ] Native image tested locally  
- [ ] Performance metrics recorded
- [ ] Image sizes verified
- [ ] Registry credentials configured
- [ ] Images pushed to registry
- [ ] Deployment manifests updated with new image tags
- [ ] Smoke tests run against deployed images

---

## Additional Resources

- **Quarkus Docker Guide**: https://quarkus.io/guides/building-native-image
- **Docker Best Practices**: https://docs.docker.com/develop/dev-best-practices/
- **Container Security**: https://docs.docker.com/engine/security/
- **Docker Registry**: https://docs.docker.com/registry/

---

**Last Updated**: August 2026
**Script Version**: 1.0
