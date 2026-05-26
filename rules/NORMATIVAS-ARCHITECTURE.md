# Architecture Normatives

**Version:** 1.0.0 **Last updated:** 2026-05-23

---

## Architecture Normatives

### 1. Layered Architecture Principles

#### 1.1 Mandatory Layers

Gentle-Vanguard projects MUST implement the following architectural layers:

```
┌─────────────────────────────────────┐
│     Presentation Layer              │
│  (UI, API, CLI, External Interfaces)│
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│     Application Layer               │
│  (Business Logic, Orchestration)    │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│     Domain Layer                    │
│  (Core Entities, Value Objects)     │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│     Infrastructure Layer            │
│  (Data Access, External Services)   │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│     Cross-Cutting Concerns          │
│  (Logging, Security, Caching)       │
└─────────────────────────────────────┘
```

#### 1.2 Layer Responsibilities

**Presentation Layer**:

- Handle user input/output
- Format responses
- Validate user requests
- Route requests to application layer
- NO business logic allowed

**Application Layer**:

- Orchestrate business processes
- Coordinate between layers
- Handle transactions
- Manage workflows
- NO direct data access

**Domain Layer**:

- Define core entities
- Implement business rules
- Define value objects
- NO infrastructure dependencies

**Infrastructure Layer**:

- Data persistence
- External service integration
- Resource management
- NO business logic

**Cross-Cutting Concerns**:

- Logging and monitoring
- Security and authentication
- Caching strategies
- Error handling

#### 1.3 Dependency Rules

- Layers MUST only depend on layers below them
- NO circular dependencies allowed
- NO skipping layers (e.g., Presentation → Infrastructure)
- Dependencies MUST be injected
- Interfaces MUST be used for abstraction

### 2. Component Specialization

#### 2.1 Component Types

Each component MUST have a single, well-defined responsibility:

**Controllers**: Handle HTTP requests/responses **Services**: Implement business logic
**Repositories**: Manage data access **Entities**: Represent domain objects **DTOs**: Transfer data
between layers **Validators**: Validate input/output **Mappers**: Transform between types
**Factories**: Create complex objects **Strategies**: Implement algorithms **Decorators**: Add
behavior to objects

#### 2.2 Single Responsibility Principle

Each component MUST:

- Have ONE reason to change
- Implement ONE responsibility
- Be testable in isolation
- Have clear naming

### 3. Encapsulation Requirements

#### 3.1 Access Control

- Public methods MUST be minimal
- Private/protected methods for internal logic
- NO direct property access (use getters/setters)
- NO exposing internal state
- Immutable objects where possible

#### 3.2 Information Hiding

- Hide implementation details
- Expose only necessary interfaces
- Use abstraction layers
- Minimize coupling
- Maximize cohesion

### 4. Interface Design Standards

#### 4.1 Interface Contracts

All interfaces MUST:

- Have clear, descriptive names
- Define complete contracts
- Include documentation
- Specify error conditions
- Define performance expectations

#### 4.2 API Design

APIs MUST:

- Be RESTful (for HTTP APIs)
- Use consistent naming
- Version appropriately
- Document all endpoints
- Include error handling

### 5. Dependency Management Rules

#### 5.1 Dependency Injection

- MUST use dependency injection
- NO service locators
- NO static dependencies
- Constructor injection preferred
- Circular dependencies MUST be avoided

#### 5.2 Dependency Graphs

- MUST be acyclic
- MUST be documented
- MUST be validated at build time
- MUST be visualized
- MUST be tested

---

_Version: 1.0.0 — 2026-05-23 — Status: ACTIVE_
