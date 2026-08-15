#!/bin/bash

##############################################################################
# Docker JVM Build Script
# 
# Builds a JVM-based Docker image optimized for standard deployments.
# 
# Usage:
#   ./scripts/build-docker-jvm.sh [IMAGE_TAG]
#
# Examples:
#   ./scripts/build-docker-jvm.sh                 # Uses 'latest'
#   ./scripts/build-docker-jvm.sh v1.0.0          # Tags as 'jvm-v1.0.0'
#   ./scripts/build-docker-jvm.sh prod-v1.0.0     # Tags as 'jvm-prod-v1.0.0'
#
# Docker Image:
#   - Base: openjdk:21-slim (Java 21)
#   - Size: ~400-500MB
#   - Startup: ~2-5 seconds
#   - Best for: Standard production deployments
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
DOCKERFILE="src/main/docker/Dockerfile.jvm"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Final image names
IMAGE_JVM="${IMAGE_NAME}:jvm-${IMAGE_TAG}"
IMAGE_LATEST="${IMAGE_NAME}:jvm-latest"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Docker JVM Image Builder${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Verify Dockerfile exists
echo -e "${YELLOW}[1/5]${NC} Verifying Dockerfile..."
if [ ! -f "${PROJECT_ROOT}/${DOCKERFILE}" ]; then
    echo -e "${RED}✗ Dockerfile not found: ${DOCKERFILE}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dockerfile found${NC}"
echo ""

# Step 2: Verify application is built
echo -e "${YELLOW}[2/5]${NC} Building Quarkus application (JVM)..."
cd "${PROJECT_ROOT}"

if [ ! -d "build/quarkus-app" ]; then
    echo -e "${YELLOW}   Application not built, building now...${NC}"
    ./gradlew clean build -q
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Gradle build failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}   Existing build found, updating...${NC}"
    ./gradlew build -q
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Gradle build failed${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Application built successfully${NC}"
echo ""

# Step 3: Verify build artifacts exist
echo -e "${YELLOW}[3/5]${NC} Verifying build artifacts..."
if [ ! -f "build/quarkus-app/quarkus-run.jar" ]; then
    echo -e "${RED}✗ Quarkus JAR not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Build artifacts verified${NC}"
echo ""

# Step 4: Build Docker image
echo -e "${YELLOW}[4/5]${NC} Building Docker image..."
echo -e "   Image: ${IMAGE_JVM}"
echo -e "   Dockerfile: ${DOCKERFILE}"
echo ""

docker build \
    --file "${DOCKERFILE}" \
    --tag "${IMAGE_JVM}" \
    --tag "${IMAGE_LATEST}" \
    --label "com.example.app.version=${IMAGE_TAG}" \
    --label "com.example.app.build-type=jvm" \
    --label "com.example.app.build-date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    "${PROJECT_ROOT}"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Docker build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo ""

# Step 5: Display image information
echo -e "${YELLOW}[5/5]${NC} Image Information..."
docker images "${IMAGE_NAME}:jvm-${IMAGE_TAG}" --no-trunc

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Build Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Test the image:"
echo -e "     ${YELLOW}docker run -p 8080:8080 ${IMAGE_JVM}${NC}"
echo ""
echo -e "  2. Push to registry:"
echo -e "     ${YELLOW}docker tag ${IMAGE_JVM} <registry>/${IMAGE_JVM}${NC}"
echo -e "     ${YELLOW}docker push <registry>/${IMAGE_JVM}${NC}"
echo ""
echo -e "  3. Inspect image:"
echo -e "     ${YELLOW}docker inspect ${IMAGE_JVM}${NC}"
echo ""
