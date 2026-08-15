#!/bin/bash

##############################################################################
# Docker Native Build Script
#
# Builds a native (GraalVM) Docker image optimized for minimal resources.
# 
# Usage:
#   ./scripts/build-docker-native.sh [IMAGE_TAG]
#
# Examples:
#   ./scripts/build-docker-native.sh                 # Uses 'latest'
#   ./scripts/build-docker-native.sh v1.0.0          # Tags as 'native-v1.0.0'
#   ./scripts/build-docker-native.sh prod-v1.0.0     # Tags as 'native-prod-v1.0.0'
#
# Docker Image:
#   - Base: ubi9/ubi-micro or distroless/base
#   - Size: ~150-200MB
#   - Startup: <100ms
#   - Build Time: ~5-10 minutes (includes compilation)
#   - Best for: Serverless, Kubernetes, performance-critical deployments
#
# Note: This script uses container-based native compilation (-Dquarkus.native.container-build=true)
#       which doesn't require GraalVM to be installed locally.
#
##############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="micro-front-ends"
IMAGE_TAG="${1:-latest}"
DOCKERFILE="src/main/docker/Dockerfile.native"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Final image names
IMAGE_NATIVE="${IMAGE_NAME}:native-${IMAGE_TAG}"
IMAGE_LATEST="${IMAGE_NAME}:native-latest"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Docker Native Image Builder${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Verify Dockerfile exists
echo -e "${YELLOW}[1/6]${NC} Verifying Dockerfile..."
if [ ! -f "${PROJECT_ROOT}/${DOCKERFILE}" ]; then
    echo -e "${RED}✗ Dockerfile not found: ${DOCKERFILE}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dockerfile found${NC}"
echo ""

# Step 2: Verify Docker is available
echo -e "${YELLOW}[2/6]${NC} Checking Docker availability..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed or not in PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is available${NC}"
echo ""

# Step 3: Clean build directory and Gradle cache
echo -e "${YELLOW}[3/6]${NC} Cleaning previous build artifacts..."
cd "${PROJECT_ROOT}"
if [ -d "build" ]; then
    rm -rf build/
fi
if [ -d ".gradle" ]; then
    rm -rf .gradle/
fi
echo -e "${GREEN}✓ Build directory cleaned${NC}"
echo ""

# Step 4: Build native executable using container
echo -e "${YELLOW}[4/6]${NC} Building native executable (container-based)..."
echo -e "   This may take 5-10 minutes..."
echo ""

./gradlew clean \
    -Dquarkus.native.enabled=true \
    -Dquarkus.native.container-build=true \
    -Dquarkus.package.jar.enabled=false \
    -q && \
./gradlew build \
    -Dquarkus.native.enabled=true \
    -Dquarkus.native.container-build=true \
    -Dquarkus.package.jar.enabled=false \
    -q

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Native build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Native executable built successfully${NC}"
echo ""

# Step 5: Verify build artifacts exist
echo -e "${YELLOW}[5/6]${NC} Verifying build artifacts..."
RUNNER_JAR=$(find build -name "*-runner" -type f | head -1)
if [ -z "$RUNNER_JAR" ]; then
    echo -e "${RED}✗ Native executable not found${NC}"
    exit 1
fi
echo -e "   Executable: ${RUNNER_JAR}"
echo -e "${GREEN}✓ Build artifacts verified${NC}"
echo ""

# Step 6: Build Docker image
echo -e "${YELLOW}[6/6]${NC} Building Docker image..."
echo -e "   Image: ${IMAGE_NATIVE}"
echo -e "   Dockerfile: ${DOCKERFILE}"
echo ""

docker build \
    --file "${DOCKERFILE}" \
    --tag "${IMAGE_NATIVE}" \
    --tag "${IMAGE_LATEST}" \
    --label "com.example.app.version=${IMAGE_TAG}" \
    --label "com.example.app.build-type=native" \
    --label "com.example.app.build-date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    "${PROJECT_ROOT}"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Docker build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo ""

# Display image information
echo -e "${YELLOW}Image Information:${NC}"
docker images "${IMAGE_NAME}:native-${IMAGE_TAG}" --no-trunc

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Build Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Performance Notes:${NC}"
echo -e "  • Image Size: Typically 150-200MB (vs 400-500MB for JVM)"
echo -e "  • Startup Time: <100ms (vs 2-5s for JVM)"
echo -e "  • Memory Usage: 50-100MB (vs 300-500MB for JVM)"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Test the image:"
echo -e "     ${YELLOW}docker run -p 8080:8080 ${IMAGE_NATIVE}${NC}"
echo ""
echo -e "  2. Compare with JVM:"
echo -e "     ${YELLOW}docker images | grep micro-front-ends${NC}"
echo ""
echo -e "  3. Push to registry:"
echo -e "     ${YELLOW}docker tag ${IMAGE_NATIVE} <registry>/${IMAGE_NATIVE}${NC}"
echo -e "     ${YELLOW}docker push <registry>/${IMAGE_NATIVE}${NC}"
echo ""
