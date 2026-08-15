# AGENT.md - Agent Configuration & Integration Guide

## Overview

This document provides guidelines for AI agents (like GitHub Copilot) working with the **Micro Front-Ends** project. It defines project conventions, architecture patterns, and best practices to ensure consistent, high-quality contributions.

---

## Table of Contents

1. [Project Context](#project-context)
2. [Codebase Conventions](#codebase-conventions)
3. [Architecture Patterns](#architecture-patterns)
4. [Code Style Guide](#code-style-guide)
5. [Testing Standards](#testing-standards)
6. [API Design Guidelines](#api-design-guidelines)
7. [Frontend Development](#frontend-development)
8. [Backend Development](#backend-development)
9. [Deployment Guidelines](#deployment-guidelines)
10. [Common Tasks & Workflows](#common-tasks--workflows)

---

## Project Context

### Technology Stack Summary
- **Backend**: Quarkus (Java 21) with Jakarta REST
- **Frontend**: Svelte + Tailwind CSS (Web Bundler)
- **Build System**: Gradle (Kotlin DSL)
- **Container**: Docker with multiple variants (JVM, Native)
- **Templating**: Qute for server-side rendering

### Project Goals
1. Demonstrate micro-frontend architecture with independent Svelte components
2. Provide high-performance RESTful API using Quarkus
3. Enable fast development with hot reload capabilities
4. Support multiple deployment strategies (JVM, Native)
5. Showcase modern Java and web development best practices

### Key Metrics
- **Java Version**: 21 (LTS)
- **App Version**: 1.0.0-SNAPSHOT
- **Default Port**: 8080
- **Package Root**: `com.tk.learn`

---

## Codebase Conventions

### Naming Conventions

#### Java Package Structure
```
com.tk.learn/
├── resource/      # REST endpoints (@Path resources)
├── service/       # Business logic
├── model/         # DTOs and domain models
├── exception/     # Custom exceptions
├── util/          # Utility classes
└── config/        # Configuration classes
```

**Examples:**
- REST Resource: `com.tk.learn.resource.GatewayResource`
- Service: `com.tk.learn.service.GatewayService`
- Model: `com.tk.learn.model.Gateway`
- Exception: `com.tk.learn.exception.GatewayNotFoundException`

#### Java Naming Rules
- **Classes**: PascalCase (e.g., `GatewayService`, `ConfigurationRequest`)
- **Methods**: camelCase (e.g., `getGatewayById()`, `createNewGateway()`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `DEFAULT_TIMEOUT`, `API_VERSION`)
- **Variables**: camelCase (e.g., `gatewayId`, `configList`)

#### Frontend (Svelte/JS)
- **Components**: PascalCase with `.svelte` extension (e.g., `GatewayAdmin.svelte`)
- **Functions**: camelCase (e.g., `getGateway()`, `validateConfig()`)
- **Stores**: camelCase suffix with `Store` (e.g., `toastStore`, `configStore`)
- **Variables**: camelCase (e.g., `isLoading`, `errorMessage`)

#### File Structure
```
src/main/resources/web/
├── components/
│   └── feature-name/
│       ├── FeatureName.svelte          # Main component
│       ├── subcomponent/SubName.svelte # Sub-components
│       └── FeatureName.module.css      # Scoped styles (if needed)
├── lib/
│   ├── apiClient.js                    # API endpoints
│   ├── stores.js                       # Svelte stores
│   └── utils.js                        # Helper functions
└── public/
    └── static/                         # Static assets
```

### Directory Organization

**Java Backend:**
```
src/main/java/com/tk/learn/
├── App.java                 # CDI Application bean (if needed)
├── model/                   # Data models, DTOs
├── resource/                # REST endpoints
├── service/                 # Business logic layer
├── exception/               # Custom exceptions
└── config/                  # Configuration classes
```

**Frontend Assets:**
```
src/main/resources/
├── web/                     # Web assets served by Quarkus
│   ├── index.html           # HTML entry point
│   ├── components/          # Svelte components
│   ├── lib/                 # JavaScript libraries/stores
│   ├── public/              # Static assets (images, etc.)
│   └── style.css            # Global styles
├── templates/               # Qute templates (pub/ for public)
└── application.properties   # Configuration
```

---

## Architecture Patterns

### Layered Architecture

The project follows a **three-tier architecture**:

```
┌─────────────────────────────────┐
│     PRESENTATION LAYER          │
│  (Svelte Components, HTML)      │
└──────────────┬──────────────────┘
               ↓ HTTP/REST
┌─────────────────────────────────┐
│      API/RESOURCE LAYER         │
│  (REST Endpoints via Quarkus)   │
├─────────────────────────────────┤
│    (@Path, @GET, @POST, etc.)   │
└──────────────┬──────────────────┘
               ↓ Method calls
┌─────────────────────────────────┐
│      BUSINESS LOGIC LAYER       │
│  (Service Classes with Logic)   │
└──────────────┬──────────────────┘
               ↓ Data operations
┌─────────────────────────────────┐
│       DATA ACCESS LAYER         │
│  (Repositories, DB, Cache)      │
└─────────────────────────────────┘
```

### Micro-Frontend Pattern

Each feature is a **self-contained Svelte component** with:
1. **Isolated State**: Uses local `let` or dedicated Svelte stores
2. **Clear API**: Exports specific props and events
3. **Minimal Dependencies**: Low coupling with other components
4. **Own Styling**: Component-level CSS or Tailwind utilities

**Example:**
```svelte
<!-- components/gateway-admin/GatewayAdmin.svelte -->
<script>
  import { onMount } from 'svelte';
  import { gatewayApi } from '../../lib/gatewayApi.js';
  
  let gateways = [];
  let loading = false;
  
  onMount(async () => {
    loading = true;
    gateways = await gatewayApi.getGateways();
    loading = false;
  });
</script>

<div class="gateway-admin">
  {#if loading}
    <p>Loading...</p>
  {:else}
    {#each gateways as gateway (gateway.id)}
      <GatewayCard {gateway} />
    {/each}
  {/if}
</div>
```

### REST API Pattern

All REST endpoints should follow this structure:

```java
@Path("/api/gateways")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class GatewayResource {
    
    @Inject
    GatewayService service;
    
    @GET
    public Response list() {
        return Response.ok(service.listAll()).build();
    }
    
    @GET
    @Path("{id}")
    public Response get(@PathParam("id") String id) {
        try {
            return Response.ok(service.getById(id)).build();
        } catch (NotFoundException e) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
    }
    
    @POST
    public Response create(GatewayRequest request) {
        Gateway created = service.create(request);
        return Response.status(Response.Status.CREATED).entity(created).build();
    }
}
```

---

## Code Style Guide

### Java Style

#### Imports
```java
// ✅ Good: Organized, specific imports
import jakarta.ws.rs.*;
import jakarta.json.Json;
import com.tk.learn.model.Gateway;

// ❌ Bad: Wildcard imports
import jakarta.ws.rs.*;
import jakarta.json.*;
import com.tk.learn.*;
```

#### Annotations & Formatting
```java
// ✅ Good: Clear annotation placement
@Path("/api/gateways")
@Produces(MediaType.APPLICATION_JSON)
public class GatewayResource {
    
    @Inject
    GatewayService service;
    
    @GET
    @Path("{id}")
    public Gateway get(@PathParam("id") String id) {
        return service.getById(id);
    }
}

// ❌ Bad: Cluttered formatting
@Path("/api/gateways") @Produces(MediaType.APPLICATION_JSON)
public class GatewayResource {
    @GET @Path("{id}") public Gateway get(@PathParam("id") String id) {
        return service.getById(id);
    }
}
```

#### Null Safety
```java
// ✅ Good: Explicit null handling
public Gateway getById(String id) {
    if (id == null || id.isBlank()) {
        throw new IllegalArgumentException("ID cannot be null or empty");
    }
    return repository.findById(id)
        .orElseThrow(() -> new NotFoundException("Gateway not found"));
}

// ❌ Bad: Implicit null assumptions
public Gateway getById(String id) {
    return repository.findById(id).get(); // Can throw NoSuchElementException
}
```

#### Method Length & Complexity
- Keep methods under **50 lines**
- Extract complex logic to separate methods
- Use **meaningful method names** that describe intent

#### Variable Naming
```java
// ✅ Good: Descriptive names
boolean isGatewayActive = gateway.getStatus().equals("ACTIVE");
List<Gateway> activeGateways = service.findByStatus("ACTIVE");

// ❌ Bad: Cryptic abbreviations
boolean gw_act = gateway.getStatus().equals("ACTIVE");
List<Gateway> res = service.findByStatus("ACTIVE");
```

### Svelte/JavaScript Style

#### Component Structure
```svelte
<script>
  // 1. Imports at top
  import { onMount } from 'svelte';
  import { toastStore } from '../../lib/toastStore.js';
  
  // 2. Reactive declarations
  let isLoading = false;
  let error = null;
  let data = [];
  
  // 3. Lifecycle methods
  onMount(async () => {
    await loadData();
  });
  
  // 4. Event handlers
  async function handleClick() {
    // Handler logic
  }
  
  // 5. Helper functions
  function formatDate(date) {
    return new Date(date).toLocaleDateString();
  }
</script>

<!-- Markup -->
<div class="container">
  {#if isLoading}
    <p>Loading...</p>
  {:else if error}
    <p class="error">{error}</p>
  {:else}
    <div>{data}</div>
  {/if}
</div>

<!-- Styles (optional scoped styles) -->
<style>
  .container {
    padding: 1rem;
  }
</style>
```

#### Template Logic
```svelte
<!-- ✅ Good: Clear reactive conditionals -->
{#if isLoading}
  <Spinner />
{:else if hasError}
  <ErrorMessage message={error} />
{:else if items.length > 0}
  {#each items as item (item.id)}
    <ItemCard {item} />
  {/each}
{:else}
  <EmptyState />
{/if}

<!-- ❌ Bad: Nested complexity, hard to follow -->
{#if items}
  {#if items.length > 0}
    {#if !isLoading}
      {#each items as item}
        {#if item.visible}
          <div>{item.name}</div>
        {/if}
      {/each}
    {/if}
  {/if}
{/if}
```

#### Tailwind CSS Usage
```svelte
<!-- ✅ Good: Use Tailwind utility classes -->
<div class="flex items-center justify-between px-4 py-2 bg-blue-50 rounded-lg border border-blue-200">
  <span class="text-lg font-semibold text-blue-900">Status</span>
  <button class="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors">
    Update
  </button>
</div>

<!-- ❌ Bad: Custom CSS when Tailwind applies -->
<style>
  .status-box {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background-color: #eff6ff;
    border: 1px solid #bfdbfe;
    border-radius: 0.5rem;
  }
</style>
<div class="status-box">Status</div>
```

---

## Testing Standards

### Java Unit Tests

#### Location
- **Path**: `src/test/java/com/tk/learn/`
- **Naming**: `*Test.java` (e.g., `GatewayServiceTest.java`)

#### Test Structure
```java
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

@QuarkusTest
class GatewayServiceTest {
    
    @Inject
    GatewayService service;
    
    @Test
    void testCreateGateway() {
        // Arrange
        GatewayRequest request = new GatewayRequest("Test Gateway", "localhost:8080");
        
        // Act
        Gateway result = service.create(request);
        
        // Assert
        assertNotNull(result.getId());
        assertEquals("Test Gateway", result.getName());
    }
    
    @Test
    void testGetNonExistentGateway() {
        // Act & Assert
        assertThrows(NotFoundException.class, () -> service.getById("non-existent"));
    }
}
```

#### REST Endpoint Tests
```java
import io.restassured.RestAssured;
import org.junit.jupiter.api.Test;

@QuarkusTest
class GatewayResourceTest {
    
    @Test
    void testListGateways() {
        RestAssured
            .given()
            .when()
            .get("/api/gateways")
            .then()
            .statusCode(200)
            .body("size()", greaterThan(0));
    }
}
```

### Running Tests
```bash
./gradlew test                  # Run all tests
./gradlew test --tests GatewayServiceTest  # Specific test class
./gradlew test --continue       # Run all, don't stop on failures
```

---

## API Design Guidelines

### RESTful Principles

#### Resource-Based URLs
```
✅ Good (Resource-based):
GET    /api/gateways              # List all gateways
POST   /api/gateways              # Create gateway
GET    /api/gateways/{id}         # Get specific gateway
PUT    /api/gateways/{id}         # Update gateway
DELETE /api/gateways/{id}         # Delete gateway

❌ Bad (Verb-based):
GET    /api/getGateways
GET    /api/getGateway/{id}
POST   /api/createGateway
PUT    /api/updateGateway/{id}
```

#### HTTP Status Codes
```
200 OK                  - Successful GET, PUT
201 Created             - Successful POST
204 No Content          - Successful DELETE, or PUT with no response
400 Bad Request         - Invalid request parameters
401 Unauthorized        - Authentication failed
403 Forbidden           - Insufficient permissions
404 Not Found           - Resource doesn't exist
409 Conflict            - Resource already exists or state conflict
500 Internal Server Error - Server-side error
```

#### Request/Response Format
```json
// ✅ Good: Consistent structure
{
  "id": "gw-001",
  "name": "Main Gateway",
  "host": "gateway.example.com",
  "port": 8080,
  "status": "ACTIVE",
  "createdAt": "2026-08-14T22:36:57Z",
  "updatedAt": "2026-08-14T22:36:57Z"
}

// Error response
{
  "error": "INVALID_REQUEST",
  "message": "Gateway name is required",
  "timestamp": "2026-08-14T22:36:57Z"
}
```

#### Pagination
```
GET /api/gateways?page=1&size=20&sort=name,asc

Response:
{
  "data": [...],
  "pagination": {
    "page": 1,
    "size": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

---

## Frontend Development

### Component Best Practices

#### Reactivity
```svelte
<!-- ✅ Good: Use reactive declarations -->
<script>
  let count = 0;
  $: doubled = count * 2;  // Reactive computed value
  $: if (count > 10) console.log('count exceeded 10');
</script>

<!-- ❌ Bad: Unnecessary computation -->
<script>
  let count = 0;
  let doubled = 0;
  
  $: doubled = count * 2;  // Works, but above is cleaner
</script>
```

#### Props & Events
```svelte
<!-- ✅ Good: Clear props with defaults -->
<script>
  export let title = 'Default Title';
  export let onSave = () => {};
</script>

<!-- Usage -->
<GatewayCard title="My Gateway" on:save={handleSave} />

<!-- ❌ Bad: Implicit props -->
<script>
  let title;  // Should be export let
</script>
```

#### API Integration
```javascript
// ✅ Good: Centralized API client
export const gatewayApi = {
  async getGateways() {
    const res = await fetch('/api/gateways');
    if (!res.ok) throw new Error('Failed to fetch gateways');
    return res.json();
  },
  
  async createGateway(data) {
    const res = await fetch('/api/gateways', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    if (!res.ok) throw new Error('Failed to create gateway');
    return res.json();
  }
};

// ❌ Bad: Inline API calls scattered throughout
// (hard to maintain, duplicate code)
async function loadGateways() {
  const res = await fetch('/api/gateways');
  // ...
}
```

### Store Management
```javascript
// lib/configStore.js
import { writable } from 'svelte/store';

export const configStore = writable({
  isLoaded: false,
  data: null,
  error: null
});

export async function loadConfig() {
  try {
    configStore.update(s => ({ ...s, isLoaded: false }));
    const data = await fetch('/api/config').then(r => r.json());
    configStore.set({ isLoaded: true, data, error: null });
  } catch (error) {
    configStore.update(s => ({ ...s, error: error.message }));
  }
}
```

---

## Backend Development

### Service Layer Pattern
```java
@ApplicationScoped
public class GatewayService {
    
    // Inject dependencies
    @Inject
    GatewayRepository repository;
    
    @Inject
    AuditService auditService;
    
    // Business logic methods
    public List<Gateway> listAll() {
        return repository.listAll();
    }
    
    public Gateway getById(String id) {
        return repository.findById(id)
            .orElseThrow(() -> new NotFoundException("Gateway not found"));
    }
    
    @Transactional
    public Gateway create(GatewayRequest request) {
        validateRequest(request);
        Gateway gateway = new Gateway(request);
        repository.persist(gateway);
        auditService.log("GATEWAY_CREATED", gateway.getId());
        return gateway;
    }
    
    private void validateRequest(GatewayRequest request) {
        if (request.getName() == null || request.getName().isBlank()) {
            throw new IllegalArgumentException("Gateway name is required");
        }
    }
}
```

### Exception Handling
```java
// ✅ Good: Custom exceptions with meaningful messages
@ApplicationException
public class NotFoundException extends RuntimeException {
    public NotFoundException(String message) {
        super(message);
    }
}

// In Resource
@ExceptionMapper
public class NotFoundExceptionMapper implements ExceptionMapper<NotFoundException> {
    @Override
    public Response toResponse(NotFoundException e) {
        return Response.status(Response.Status.NOT_FOUND)
            .entity(new ErrorResponse("NOT_FOUND", e.getMessage()))
            .build();
    }
}

// ❌ Bad: Generic Exception throws
public Gateway getById(String id) throws Exception {
    return repository.findById(id).orElseThrow(() -> new Exception("Not found"));
}
```

---

## Deployment Guidelines

### Pre-Deployment Checklist

```bash
# 1. Update version
# - Edit build.gradle.kts: version = "x.x.x"
# - Update Docker scripts version

# 2. Run complete test suite
./gradlew clean test

# 3. Build application
./gradlew clean build

# 4. Build Docker image
./scripts/build-docker-jvm.sh v1.0.0

# 5. Test Docker locally
docker run --rm -p 8080:8080 micro-front-ends:jvm-v1.0.0
# Verify: curl http://localhost:8080

# 6. Tag and push
docker tag micro-front-ends:jvm-v1.0.0 myregistry/micro-front-ends:v1.0.0
docker push myregistry/micro-front-ends:v1.0.0

# 7. Deploy to environment
# (Use your deployment process)
```

### Docker Best Practices

#### Image Tagging
```bash
# ✅ Good: Descriptive tags
docker tag app:latest myregistry/app:v1.0.0
docker tag app:latest myregistry/app:v1.0.0-jvm
docker tag app:latest myregistry/app:latest

# ❌ Bad: Ambiguous tags
docker tag app myregistry/app:1.0
docker tag app myregistry/app:prod
```

#### Runtime Configuration
```bash
# ✅ Good: Use environment variables
docker run \
  -e QUARKUS_LOG_LEVEL=INFO \
  -e QUARKUS_HTTP_PORT=8080 \
  -p 8080:8080 \
  app:latest

# ❌ Bad: Hardcoded configuration
# (Configuration should be external to image)
```

---

## Common Tasks & Workflows

### Adding a New API Endpoint

#### Step 1: Create Request/Response Models
```java
// model/ServiceRequest.java
public class ServiceRequest {
    public String name;
    public String description;
    
    // Getters, setters
}

// model/ServiceResponse.java
public class ServiceResponse {
    public String id;
    public String name;
    // ...
}
```

#### Step 2: Create Service Logic
```java
// service/ServiceService.java
@ApplicationScoped
public class ServiceService {
    
    @Inject
    ServiceRepository repository;
    
    @Transactional
    public ServiceResponse create(ServiceRequest request) {
        // Validation
        if (request.name == null) throw new IllegalArgumentException("Name required");
        
        // Create
        Service service = new Service(request.name, request.description);
        repository.persist(service);
        
        return mapToResponse(service);
    }
    
    private ServiceResponse mapToResponse(Service service) {
        return new ServiceResponse(service.id, service.name, service.description);
    }
}
```

#### Step 3: Create REST Resource
```java
// resource/ServiceResource.java
@Path("/api/services")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ServiceResource {
    
    @Inject
    ServiceService service;
    
    @POST
    public Response create(ServiceRequest request) {
        ServiceResponse response = service.create(request);
        return Response.status(Response.Status.CREATED).entity(response).build();
    }
}
```

#### Step 4: Create Frontend Component
```svelte
<!-- components/service-form/ServiceForm.svelte -->
<script>
  import { configApi } from '../../lib/configApi.js';
  
  let name = '';
  let description = '';
  let isLoading = false;
  
  async function handleSubmit() {
    isLoading = true;
    try {
      await configApi.createService({ name, description });
      // Success
    } finally {
      isLoading = false;
    }
  }
</script>

<form on:submit|preventDefault={handleSubmit}>
  <input bind:value={name} placeholder="Service name" />
  <textarea bind:value={description} placeholder="Description"></textarea>
  <button disabled={isLoading}>Create</button>
</form>
```

### Adding a New Svelte Component

1. **Create component file**: `src/main/resources/web/components/feature-name/FeatureName.svelte`
2. **Define props and exports**: Clear interface for parent components
3. **Use Tailwind CSS**: Avoid custom CSS where possible
4. **Add to main App**: Import and register in `App.svelte`
5. **Test locally**: Verify in dev mode with hot reload

### Debugging Common Issues

#### API Calls Return 404
```bash
# Check:
1. Verify endpoint path matches @Path annotation
2. Confirm @Produces and @Consumes match request
3. Check request method (GET, POST, PUT, DELETE)
4. Review server logs: ./gradlew quarkusDev (check console output)
```

#### Component Not Rendering
```bash
# Check:
1. Verify component is imported in App.svelte
2. Check browser console for JavaScript errors
3. Verify data binding: let vs. $store
4. Check Tailwind classes apply correctly
```

#### Build Failures
```bash
# Check:
1. Java version: java -version (should be 21+)
2. Gradle version: ./gradlew --version
3. Available disk space: df -h
4. Clean build: ./gradlew clean build
5. Check for compilation errors in output
```

---

## Git Workflow

### Commit Message Format
```
feat(component): Brief description of change

Detailed explanation of what changed and why.

Refs: #123
```

### Examples
```
feat(gateway-admin): Add ability to delete gateways
fix(api): Handle null values in gateway response
docs(readme): Update Docker build instructions
refactor(service): Extract validation logic to separate method
```

---

## Documentation Updates

Whenever you make changes, update relevant documentation:

- **API Changes**: Update API endpoint descriptions in PROJECT.md
- **New Components**: Document in FRONTEND Components section
- **Configuration**: Update Configuration section
- **Build Process**: Update build scripts if modified

---

## Questions for Agents

When unclear about approach, ask:

1. **Architecture**: Should this be a service, component, or utility?
2. **Scope**: Is this API endpoint needed, or can frontend handle it?
3. **Testing**: What test cases should be included?
4. **Performance**: Are there optimization opportunities?
5. **Compatibility**: Will this work with existing code?

---

## Resources for Agents

- **Quarkus Docs**: https://quarkus.io/guides/
- **Svelte Tutorial**: https://learn.svelte.dev/
- **Jakarta REST**: https://projects.eclipse.org/projects/ee4j.rest
- **Tailwind**: https://tailwindcss.com/docs/
- **Gradle**: https://docs.gradle.org/

---

**Version**: 1.0
**Last Updated**: August 2026
