---
name: parallel-execution-limits
description:
  Advanced parallel execution management with dependency graphs, resource pooling, and token budget
  circuit breaker
metadata:
  source: GV-native
---

# Skill: parallel-execution-limits

**versión**: 1.0.0 **Created**: 2026-04-23 **Status**: ACTIVE **Priority**: CRITICAL

---

## Overview

The `parallel-execution-limits` skill provides enterprise-grade parallel execution management with
explicit dependency graphs, custom parallelism rules, resource pooling with GPU/CPU awareness, and
token budget circuit breaker protection.

### Key Capabilities

- **Explicit Dependency Graphs**: DAG visualization and validation
- **Custom Parallelism Rules**: Define execution patterns per task type
- **Resource Pooling**: GPU/CPU awareness with dynamic allocation
- **Circuit Breaker**: Token budget protection and graceful degradation
- **Real-time Monitoring**: Execution metrics and resource utilization
- **Adaptive Scheduling**: Dynamic task prioritization based on resources

---

## When to Use This Skill

### Activation Triggers

- User mentions "parallel execution", "ejecucin paralela", or "execution limits"
- Complex workflows with >10 tasks requiring optimization
- GPU/CPU resource constraints need management
- Token budget protection required
- Custom parallelism strategies needed

### Use Cases

1. **Multi-Agent Orchestration**: "Ejecutar 5 agentes en paralelo con lmites de recursos"
2. **Token Budget Protection**: "Proteger presupuesto de tokens con circuit breaker"
3. **Resource-Aware Scheduling**: "Asignar tareas segn disponibilidad de GPU/CPU"
4. **Dependency Optimization**: "Optimizar ejecucin paralela respetando dependencias"

---

## References

See `references/patterns.md` for detailed patterns, code examples, and execution strategies.
