# Micro Front-Ends: Comprehensive Project Guide

## Project Overview

**Micro Front-Ends** is a full-stack web application built with:
- **Backend**: Quarkus (Java 21) - Supersonic Subatomic Java Framework
- **Frontend**: Svelte + Tailwind CSS (via Web Bundler)
- **Templating**: Qute (for server-side templating)
- **Architecture**: RESTful API with micro-frontend components
- **Version**: 1.0.0-SNAPSHOT

This project demonstrates a modern approach to building scalable web applications with independent, composable UI components (micro-frontends) backed by a high-performance Quarkus backend.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Tech Stack](#tech-stack)
3. [Setup & Prerequisites](#setup--prerequisites)
4. [Development Workflow](#development-workflow)
5. [Building & Deployment](#building--deployment)
6. [Docker Support](#docker-support)
7. [API Documentation](#api-documentation)
8. [Frontend Components](#frontend-components)
9. [Configuration](#configuration)
10. [Troubleshooting](#troubleshooting)

---

## Project Structure

```
micro-front-ends/
├── src/
│   ├── main/
│   │   ├── java/                          # Java backend code
│   │   │   └── com/tk/learn/             # Package root
│   │   │
│   │   ├── resources/
│   │   │   ├── web/                       # Web assets
│   │   │   │   ├── components/            # Svelte micro-frontend components
│   │   │   │   │   ├── app/               # Main app component
│   │   │   │   │   ├── gateway-admin/     # Gateway administration
│   │   │   │   │   ├── service-onboarding/# Service onboarding
│   │   │   │   │   ├── config-management/ # Configuration management
│   │   │   │   │   ├── config-audit-history/ # Audit history
│   │   │   │   │   ├── audit-logs-modal/  # Audit logs modal
│   │   │   │   │   ├── route-form-modal/  # Route form modal
│   │   │   │   │   ├── config-server/     # Server configuration
│   │   │   │   │   ├── side-menu/         # Navigation menu
│   │   │   │   │   └── toast/             # Toast notifications
│   │   │   │   ├── lib/                   # Shared utilities & stores
│   │   │   │   │   ├── toastStore.js      # Toast state management
│   │   │   │   │   ├── gatewayApi.js      # Gateway API client
│   │   │   │   │   └── configApi.js       # Config API client
│   │   │   │   ├── public/                # Static assets
│   │   │   │   │   └── static/
│   │   │   │   │       └── logo.svg
│   │   │   │   ├── style.css              # Global styles
│   │   │   │   └── index.html             # HTML entry point
│   │   │   │
│   │   │   ├── templates/                 # Qute templates
│   │   │   │   └── pub/                   # Public templates
│   │   │   │
│   │   │   └── application.properties     # Quarkus configuration
│   │   │
│   │   └── docker/                        # Docker configurations
│   │       ├── Dockerfile.jvm             # JVM-based image
│   │       ├── Dockerfile.native          # Native binary image
│   │       ├── Dockerfile.native-micro    # Minimal native image
│   │       └── Dockerfile.legacy-jar      # Legacy JAR image
│   │
│   ├── test/                              # Java unit tests
│   └── native-test/                       # Native compilation tests
│
├── gradle/                                # Gradle wrapper
├── build.gradle.kts                       # Gradle configuration (Kotlin DSL)
├── settings.gradle.kts                    # Gradle settings
├── gradle.properties                      # Gradle properties
├── gradlew & gradlew.bat                  # Gradle wrapper scripts
├── .dockerignore                          # Files to exclude from Docker build
├── .gitignore                             # Files to exclude from Git
├── README.md                              # Quick start guide
└── scripts/                               # Build and deployment scripts
    ├── build-docker-jvm.sh                # Build JVM Docker image
    ├── build-docker-native.sh             # Build native Docker image
    └── build-docker-all.sh                # Build all Docker variants
```

---

## Tech Stack

### Backend
| Technology | Purpose | Version |
|------------|---------|---------|
| **Quarkus** | Supersonic Subatomic Java Framework | Latest (via BOM) |
| **Jakarta REST** | RESTful API development | Latest |
| **Quarkus Arc** | Dependency Injection | Latest |
| **JSON-B** | JSON serialization | Latest |
| **Qute** | Server-side templating | Latest |
| **Java** | Programming Language | 21 |

### Frontend
| Technology | Purpose |
|------------|---------|
| **Svelte** | Reactive frontend components |
| **Web Bundler** | Zero-config bundling for scripts & styles |
| **Tailwind CSS 4+** | Utility-first CSS framework |
| **JavaScript** | Client-side scripting |

### Development & Build
| Tool | Purpose |
|------|---------|
| **Gradle (Kotlin DSL)** | Build automation |
| **Quarkus Gradle Plugin** | Gradle integration for Quarkus |
| **Docker** | Container orchestration & deployment |
| **GraalVM** | Native executable compilation (optional) |

---

## Setup & Prerequisites

### System Requirements
- **Java 21+** (OpenJDK or any compatible distribution)
- **Gradle 8.x+** (optional; Gradle wrapper included)
- **Node.js 18+** (for frontend dependencies)
- **Docker** (for containerization)
- **GraalVM CE/EE** (optional, for native builds)

### Installation

#### 1. Clone the Repository
```bash
git clone <repository-url>
cd micro-front-ends
```

#### 2. Verify Java Installation
```bash
java -version
# Should output Java 21 or higher
```

#### 3. Install Dependencies
The Gradle wrapper will download dependencies automatically:
```bash
./gradlew clean build
```

#### 4. (Optional) Install Node Dependencies
For direct frontend development:
```bash
npm install
```

---

## Development Workflow

### Running in Dev Mode

Start the application with hot reload enabled:
```bash
./gradlew quarkusDev
```

**Output:**
- Application starts on `http://localhost:8080`
- Dev UI available at `http://localhost:8080/q/dev/`
- Hot reload enabled for Java and web changes
- Browser automatically refreshes on changes

### Dev UI Features
The Quarkus Dev UI provides:
- Configuration editor
- Extension browser
- Continuous testing UI
- Application metrics
- Dependency tree visualization

### Frontend Development

While `quarkusDev` is running:

1. **Edit Svelte Components**
   - Modify files in `src/main/resources/web/components/`
   - Changes hot-reload automatically

2. **Update Styles**
   - Edit `src/main/resources/web/style.css` or component styles
   - Tailwind CSS classes compile automatically

3. **API Integration**
   - Use `lib/gatewayApi.js` and `lib/configApi.js` for backend calls
   - REST endpoints are typically on `http://localhost:8080/api/`

### Backend Development

1. **Create REST Endpoints**
   - Add new resource classes in `src/main/java/com/tk/learn/`
   - Use `@Path`, `@GET`, `@POST`, etc. annotations

2. **Hot Reload**
   - Modify Java code and save
   - Quarkus recompiles and reloads automatically

3. **Testing**
   - Write tests in `src/test/java/`
   - Run with `./gradlew test`

---

## Building & Deployment

### Build Variants

#### 1. Standard JVM Build
```bash
./gradlew build
```
**Output:** `build/quarkus-app/quarkus-run.jar` (fast startup, reasonable memory)

**Run:**
```bash
java -jar build/quarkus-app/quarkus-run.jar
```

#### 2. Über-JAR (Uber-JAR)
Single standalone JAR with all dependencies:
```bash
./gradlew build -Dquarkus.package.jar.type=uber-jar
```
**Output:** `build/*-runner.jar` (~300MB+)

**Run:**
```bash
java -jar build/micro-front-ends-1.0.0-SNAPSHOT-runner.jar
```

#### 3. Native Executable (GraalVM)

**Option A: With GraalVM installed locally**
```bash
./gradlew build -Dquarkus.native.enabled=true
```

**Option B: Container-based native build (no GraalVM required)**
```bash
./gradlew build -Dquarkus.native.enabled=true -Dquarkus.native.container-build=true
```

**Output:** `build/micro-front-ends-1.0.0-SNAPSHOT-runner` (executable binary)

**Run:**
```bash
./build/micro-front-ends-1.0.0-SNAPSHOT-runner
```

**Advantages of Native:**
- ✅ Extremely fast startup (~50ms)
- ✅ Lower memory footprint
- ✅ Smaller container size
- ❌ Longer build time (~5-10 minutes)
- ❌ Requires GraalVM or Docker

---

## Docker Support

### Available Dockerfile Variants

#### 1. **Dockerfile.jvm** (Recommended)
- **Use Case:** Standard deployments
- **Base Image:** `openjdk:21-slim` or similar
- **Size:** ~400-500MB
- **Startup:** ~2-5 seconds
- **Ideal For:** Most production scenarios

#### 2. **Dockerfile.native**
- **Use Case:** Serverless, performance-critical deployments
- **Base Image:** `ubi9/ubi-micro` or `distroless/base`
- **Size:** ~150-200MB
- **Startup:** <100ms
- **Ideal For:** AWS Lambda, Kubernetes, cost-sensitive environments

#### 3. **Dockerfile.native-micro**
- **Use Case:** Ultra-minimal deployments
- **Base Image:** `quay.io/quarkus/ubi-quarkus-native-image:latest`
- **Size:** ~50-100MB
- **Ideal For:** Edge computing, resource-constrained environments

#### 4. **Dockerfile.legacy-jar**
- **Use Case:** Legacy systems, specific requirements
- **Use:** For compatibility with older deployment pipelines

### Building Docker Images

See the **[Docker Scripts](#docker-scripts)** section below for automated build scripts.

#### Manual Build: JVM Image
```bash
# Build application
./gradlew build

# Build Docker image
docker build -f src/main/docker/Dockerfile.jvm \
  -t micro-front-ends:latest \
  -t micro-front-ends:1.0.0 .
```

#### Manual Build: Native Image
```bash
# Build native binary
./gradlew build -Dquarkus.native.enabled=true -Dquarkus.native.container-build=true

# Build Docker image
docker build -f src/main/docker/Dockerfile.native \
  -t micro-front-ends:native-latest \
  -t micro-front-ends:native-1.0.0 .
```

#### Running Docker Container
```bash
# JVM variant
docker run -p 8080:8080 micro-front-ends:latest

# Native variant (faster startup)
docker run -p 8080:8080 micro-front-ends:native-latest
```

---

## Docker Scripts

### Available Scripts

Located in `scripts/` directory:

#### `build-docker-jvm.sh`
Builds a JVM-based Docker image with full optimization.

```bash
./scripts/build-docker-jvm.sh [IMAGE_TAG]
```

**Parameters:**
- `IMAGE_TAG` (optional): Tag for the image (default: `latest`)

**Example:**
```bash
./scripts/build-docker-jvm.sh prod-v1.0.0
```

#### `build-docker-native.sh`
Builds a native (GraalVM) Docker image with minimal footprint.

```bash
./scripts/build-docker-native.sh [IMAGE_TAG]
```

**Parameters:**
- `IMAGE_TAG` (optional): Tag for the image (default: `latest`)

**Example:**
```bash
./scripts/build-docker-native.sh native-v1.0.0
```

#### `build-docker-all.sh`
Builds both JVM and native Docker images in sequence.

```bash
./scripts/build-docker-all.sh [IMAGE_TAG]
```

**Example:**
```bash
./scripts/build-docker-all.sh v1.0.0
```

**Output:**
- `micro-front-ends:jvm-<TAG>`
- `micro-front-ends:native-<TAG>`

### Creating Build Scripts

Run this from the project root to create the scripts:

```bash
mkdir -p scripts

# Make scripts executable
chmod +x scripts/*.sh
```

---

## API Documentation

### REST Endpoints

The application follows RESTful conventions. Common endpoints include:

#### Gateway Management
- `GET /api/gateway` - List all gateways
- `POST /api/gateway` - Create new gateway
- `GET /api/gateway/{id}` - Get gateway details
- `PUT /api/gateway/{id}` - Update gateway
- `DELETE /api/gateway/{id}` - Delete gateway

#### Service Onboarding
- `POST /api/services/onboard` - Onboard new service
- `GET /api/services` - List all services
- `GET /api/services/{id}` - Get service details

#### Configuration Management
- `GET /api/config` - Get current configuration
- `PUT /api/config` - Update configuration
- `GET /api/config/audit` - Get configuration audit trail
- `POST /api/config/server` - Configure server settings

#### Audit Logs
- `GET /api/audit/logs` - Get audit logs
- `GET /api/audit/logs?filter=...` - Query audit logs

### API Clients

**Frontend API integration** (`src/main/resources/web/lib/`):
- **`gatewayApi.js`**: Gateway-related API calls
- **`configApi.js`**: Configuration-related API calls
- **`toastStore.js`**: Toast notification management

#### Example API Usage (JavaScript)

```javascript
import { gatewayApi } from './lib/gatewayApi.js';

// Fetch gateways
const gateways = await gatewayApi.getGateways();

// Create gateway
const newGateway = await gatewayApi.createGateway({
  name: 'My Gateway',
  host: 'localhost:8080'
});
```

---

## Frontend Components

### Component Architecture

The frontend is built with **Svelte** components, organized by feature:

#### Core Components
| Component | Location | Purpose |
|-----------|----------|---------|
| **App** | `components/app/App.svelte` | Main application root |
| **SideMenu** | `components/side-menu/SideMenu.svelte` | Navigation sidebar |
| **Toast** | `components/toast/Toast.svelte` | Toast notification system |

#### Feature Components
| Component | Location | Purpose |
|-----------|----------|---------|
| **GatewayAdmin** | `components/gateway-admin/GatewayAdmin.svelte` | Gateway configuration UI |
| **ServiceOnboarding** | `components/service-onboarding/ServiceOnboarding.svelte` | Service registration |
| **ConfigManagement** | `components/config-management/ConfigManagement.svelte` | Configuration editor |
| **ConfigServer** | `components/config-server/ConfigServer.svelte` | Server settings |
| **ConfigAuditHistory** | `components/config-audit-history/ConfigAuditHistory.svelte` | Audit trail viewer |
| **RouteFormModal** | `components/route-form-modal/RouteFormModal.svelte` | Route configuration modal |
| **AuditLogsModal** | `components/audit-logs-modal/AuditLogsModal.svelte` | Detailed audit logs modal |

### Styling

- **Framework**: Tailwind CSS 4+
- **Entry Point**: `src/main/resources/web/style.css`
- **Configuration**: Web Bundler handles Tailwind compilation
- **Utilities**: Extensive Tailwind utility classes available in components

### State Management

Using **Svelte Stores** (simpler alternative to Redux):

```javascript
// toastStore.js
import { writable } from 'svelte/store';

export const toastStore = writable([]);

export function addToast(message, type = 'info') {
  toastStore.update(items => [...items, { id: Date.now(), message, type }]);
}
```

Usage in components:
```svelte
<script>
  import { toastStore } from '../lib/toastStore.js';
</script>

{#each $toastStore as toast (toast.id)}
  <div class="toast toast-{toast.type}">
    {toast.message}
  </div>
{/each}
```

---

## Configuration

### Application Properties

**File**: `src/main/resources/application.properties`

#### Common Settings

```properties
# Server
quarkus.http.port=8080
quarkus.http.cors=true
quarkus.http.cors.origins=*

# Database (if applicable)
quarkus.datasource.db-kind=postgresql
quarkus.datasource.username=postgres
quarkus.datasource.password=postgres
quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/app_db

# Logging
quarkus.log.level=INFO
quarkus.log.category."com.tk.learn".level=DEBUG

# Development
%dev.quarkus.http.cors.origins=http://localhost:3000,http://localhost:8080
```

### Build Properties

**File**: `gradle.properties`

```properties
quarkusPlatformGroupId=io.quarkus
quarkusPlatformArtifactId=quarkus-bom
quarkusPlatformVersion=<version>
```

### Docker Environment Variables

```bash
docker run -e QUARKUS_HTTP_PORT=8080 \
           -e QUARKUS_LOG_LEVEL=INFO \
           -p 8080:8080 \
           micro-front-ends:latest
```

---

## Troubleshooting

### Common Issues

#### 1. **Port 8080 Already in Use**
```bash
# Find process using port 8080
lsof -i :8080

# Kill process (replace <PID>)
kill -9 <PID>

# Or use different port
./gradlew quarkusDev -Dquarkus.http.port=8081
```

#### 2. **OutOfMemoryError During Build**
```bash
# Increase Gradle memory
export GRADLE_OPTS="-Xmx2g"
./gradlew build
```

#### 3. **Native Build Fails**
- Ensure GraalVM is installed: `java -version`
- Or use container-based build: `-Dquarkus.native.container-build=true`
- Check available disk space (native builds need ~10GB temporary)

#### 4. **Hot Reload Not Working**
```bash
# Restart dev mode
./gradlew quarkusDev --stop
./gradlew quarkusDev
```

#### 5. **Docker Build Context Too Large**
- Check `.dockerignore` includes unnecessary files
- Default ignores `node_modules`, `.git`, etc.

### Debug Mode

Enable debug logging:
```bash
./gradlew quarkusDev -Dquarkus.log.level=DEBUG
```

Access debugger (port 5005):
```bash
./gradlew quarkusDev --debug
```

---

## Deployment Checklist

- [ ] Update version in `build.gradle.kts`
- [ ] Update version in Docker build scripts
- [ ] Run full test suite: `./gradlew clean test`
- [ ] Build application: `./gradlew clean build`
- [ ] Build Docker image: `./scripts/build-docker-jvm.sh v1.0.0`
- [ ] Test Docker image locally
- [ ] Tag and push to registry
- [ ] Deploy to staging
- [ ] Run smoke tests
- [ ] Deploy to production

---

## Useful Commands

```bash
# Development
./gradlew quarkusDev              # Start dev mode with hot reload
./gradlew test                    # Run unit tests
./gradlew test --continue         # Run all tests even if some fail

# Building
./gradlew clean build             # Standard build
./gradlew build -Dquarkus.package.jar.type=uber-jar  # Über-JAR
./gradlew build -Dquarkus.native.enabled=true        # Native build

# Docker
docker build -f src/main/docker/Dockerfile.jvm -t app:latest .
docker run -p 8080:8080 app:latest
docker logs -f <container-id>

# Cleanup
./gradlew clean                   # Remove build artifacts
rm -rf build node_modules         # Full cleanup
```

---

## Resources

- **Quarkus Documentation**: https://quarkus.io/guides/
- **Svelte Documentation**: https://svelte.dev/docs
- **Tailwind CSS**: https://tailwindcss.com/docs
- **Jakarta REST (JAX-RS)**: https://projects.eclipse.org/projects/ee4j.rest
- **Web Bundler**: https://docs.quarkiverse.io/quarkus-web-bundler/dev/

---

## Contributing

When contributing to this project:

1. Follow the existing code structure and naming conventions
2. Add tests for new features
3. Update documentation for API changes
4. Use meaningful commit messages
5. Test both dev and production builds

---

## License

See LICENSE file for details.

---

**Last Updated**: August 2026
**Project Version**: 1.0.0-SNAPSHOT
