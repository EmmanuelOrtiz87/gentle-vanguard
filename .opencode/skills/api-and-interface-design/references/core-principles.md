# Core Principles

## Hyrum's Law

> With a sufficient number of users of an API, all observable behaviors of your system will be
> depended on by somebody, regardless of what you promise in the contract.

This means: every public behavior — including undocumented quirks, error message text, timing, and
ordering — becomes a de facto contract once users depend on it.

**Design implications:**

- **Be intentional about what you expose.** Every observable behavior is a potential commitment.
- **Don't leak implementation details.** If users can observe it, they will depend on it.
- **Plan for deprecation at design time.**
- **Tests are not enough.** Even with perfect contract tests, Hyrum's Law means "safe" changes can
  break real users who depend on undocumented behavior.

## The One-Version Rule

Avoid forcing consumers to choose between multiple versions of the same dependency or API. Diamond
dependency problems arise when different consumers need different versions of the same thing. Design
for a world where only one version exists at a time — extend rather than fork.

## 1. Contract First

Define the interface before implementing it. The contract is the spec — implementation follows.

```typescript
interface TaskAPI {
  // Creates a task and returns the created task with server-generated fields
  createTask(input: CreateTaskInput): Promise<Task>;

  // Returns paginated tasks matching filters
  listTasks(params: ListTasksParams): Promise<PaginatedResult<Task>>;

  // Returns a single task or throws NotFoundError
  getTask(id: string): Promise<Task>;

  // Partial update — only provided fields change
  updateTask(id: string, input: UpdateTaskInput): Promise<Task>;

  // Idempotent delete — succeeds even if already deleted
  deleteTask(id: string): Promise<void>;
}
```

## 2. Prefer Addition Over Modification

Extend interfaces without breaking existing consumers:

```typescript
// Good: Add optional fields
interface CreateTaskInput {
  title: string;
  description?: string;
  priority?: 'low' | 'medium' | 'high'; // Added later, optional
  labels?: string[]; // Added later, optional
}

// Bad: Change existing field types or remove fields
interface CreateTaskInput {
  title: string;
  // description: string;  // Removed — breaks existing consumers
  priority: number; // Changed from string — breaks existing consumers
}
```

## 3. Predictable Naming

| Pattern         | Convention             | Example                             |
| --------------- | ---------------------- | ----------------------------------- |
| REST endpoints  | Plural nouns, no verbs | `GET /api/tasks`, `POST /api/tasks` |
| Query params    | camelCase              | `?sortBy=createdAt&pageSize=20`     |
| Response fields | camelCase              | `{ createdAt, updatedAt, taskId }`  |
| Boolean fields  | is/has/can prefix      | `isComplete`, `hasAttachments`      |
| Enum values     | UPPER_SNAKE            | `"IN_PROGRESS"`, `"COMPLETED"`      |
