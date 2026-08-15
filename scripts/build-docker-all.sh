#!/bin/bash

##############################################################################
# Docker Build All Script
#
# Builds both JVM and Native Docker images in sequence.
#
# Usage:
#   ./scripts/build-docker-all.sh [IMAGE_TAG]
#
# Examples:
#   ./scripts/build-docker-all.sh                 # Uses 'latest'
#   ./scripts/build-docker-all.sh v1.0.0          # Builds both variants
#   ./scripts/build-docker-all.sh prod-v1.0.0     # With custom tag
#
# Output Images:
#   - micro-front-ends:jvm-<TAG>
#   - micro-front-ends:native-<TAG>
#   - micro-front-ends:jvm-latest
#   - micro-front-ends:native-latest
#
# Total Build Time: ~10-15 minutes (most time spent on native compilation)
#
##############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
IMAGE_TAG="${1:-latest}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPTS_DIR}/.." && pwd)"

echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║        Docker Build All Images Script${NC}"
echo -e "${MAGENTA}║        Building JVM and Native variants${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Image Tag: ${IMAGE_TAG}"
echo -e "  Project Root: ${PROJECT_ROOT}"
echo ""

# Step 1: Build JVM variant
echo -e "${MAGENTA}┌─ [1/2] Building JVM Variant ──────────────────────────────┐${NC}"
echo ""

"${SCRIPTS_DIR}/build-docker-jvm.sh" "${IMAGE_TAG}"
JVM_BUILD_EXIT=$?

if [ $JVM_BUILD_EXIT -ne 0 ]; then
    echo ""
    echo -e "${RED}✗ JVM build failed (exit code: ${JVM_BUILD_EXIT})${NC}"
    exit 1
fi

echo ""
echo -e "${MAGENTA}└───────────────────────────────────────────────────────────┘${NC}"
echo ""

# Wait a moment between builds
sleep 2

# Step 2: Build Native variant
echo -e "${MAGENTA}┌─ [2/2] Building Native Variant ───────────────────────────┐${NC}"
echo ""

"${SCRIPTS_DIR}/build-docker-native.sh" "${IMAGE_TAG}"
NATIVE_BUILD_EXIT=$?

if [ $NATIVE_BUILD_EXIT -ne 0 ]; then
    echo ""
    echo -e "${RED}✗ Native build failed (exit code: ${NATIVE_BUILD_EXIT})${NC}"
    exit 1
fi

echo ""
echo -e "${MAGENTA}└───────────────────────────────────────────────────────────┘${NC}"
echo ""

# Final summary
echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}✓ All builds completed successfully!${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Built Images:${NC}"
docker images "micro-front-ends:*" --no-trunc | grep -E "jvm-${IMAGE_TAG}|native-${IMAGE_TAG}" || echo "  (Use 'docker images' to view)"

echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo ""
echo -e "  ${YELLOW}# Test JVM variant${NC}"
echo -e "    docker run -p 8080:8080 micro-front-ends:jvm-${IMAGE_TAG}"
echo ""
echo -e "  ${YELLOW}# Test Native variant${NC}"
echo -e "    docker run -p 8080:8080 micro-front-ends:native-${IMAGE_TAG}"
echo ""
echo -e "  ${YELLOW}# Compare image sizes${NC}"
echo -e "    docker images micro-front-ends --no-trunc"
echo ""
echo -e "  ${YELLOW}# Push to registry${NC}"
echo -e "    docker push <registry>/micro-front-ends:jvm-${IMAGE_TAG}"
echo -e "    docker push <registry>/micro-front-ends:native-${IMAGE_TAG}"
echo ""

echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo ""
