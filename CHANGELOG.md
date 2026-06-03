# Changelog

## [3.1.0] - 2026-06-03

### Added
- **Dashboard v4**: OpenTelemetry tracing visualization with E2E traceability
- **Skill Marketplace**: Publishing, rating, and review system for skills
- **Interactive Documentation**: Guided tutorials with progress tracking
- **Performance Optimizations**: Code splitting with lazy loading and manual chunks
- **React Router**: Navigation between Dashboard, Tracing, Marketplace, and Docs

### Enhanced
- **Web Dashboard**: Modular architecture with separate chunks for vendor, charts, icons
- **Build Process**: Optimized bundle sizes with dynamic imports
- **User Experience**: Navigation bar with seamless view switching

### Technical
- Added `TracingDashboard.tsx` for OpenTelemetry trace visualization
- Added `Marketplace.tsx` with skill listings, search, and reviews
- Added `InteractiveDocs.tsx` with tutorial system
- Implemented code splitting in `vite.config.ts`
- Integrated React Router with lazy loading and Suspense

## [3.0.0] - 2026-06-03

### Added
- **Fase 3 Implementation**: MCP Native, Web UI, Multi-repo orchestration
- **MCP Server v2.0.0**: 5 tools + 3 prompts with native SDK
- **Web Dashboard v1.0.0**: React SPA with WebSocket real-time metrics
- **Multi-repo Engine v2.0.0**: 7 actions with Pester tests
- **Test Suite**: 16 tests (Pester + Vitest)
- **Skill Registry Sync**: 385 skills synchronized
- **CI/CD**: GitHub Action for skill registry validation

### Enhanced
- **Observability**: OpenTelemetry tracer with span management
- **Benchmarking**: Automated skill benchmark suite
- **Auto-update**: Launcher with rollback capability
- **Docker**: Containerized test environment
- **S3 Distribution**: CloudFront integration

## [2.30.0] - Previous

See previous changelog entries...
