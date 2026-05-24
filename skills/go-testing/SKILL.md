---
name: go-testing
description: >
  Go testing patterns for Gentleman.Dots, including Bubbletea TUI testing. Trigger: When writing Go
  tests, using teatest, or adding test coverage.
license: Apache-2.0
metadata:
  author: gentle-vanguard
  versión: '1.0'
---

## When to Use

Use this skill when:

- Writing Go unit tests
- Testing Bubbletea TUI components
- Creating table-driven tests
- Adding integration tests
- Using golden file testing

---

## Critical Patterns

### Pattern 1: Table-Driven Tests

Standard Go pattern for multiple test cases:

```go
func TestSomething(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        expected string
        wantErr  bool
    }{
        {
            name:     "valid input",
            input:    "hello",
            expected: "HELLO",
            wantErr:  false,
        },
        {
            name:     "empty input",
            input:    "",
            expected: "",
            wantErr:  true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := ProcessInput(tt.input)

            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
                return
            }

            if result != tt.expected {
                t.Errorf("got %q, want %q", result, tt.expected)
            }
        })
    }
}
```

### Pattern 2: Bubbletea Model Testing

Test Model state transitions directly:

```go
func TestModelUpdate(t *testing.T) {
    m := NewModel()

    // Simulate key press
    newModel, _ := m.Update(tea.KeyMsg{Type: tea.KeyEnter})
    m = newModel.(Model)

    if m.Screen != ScreenMainMenu {
        t.Errorf("expected ScreenMainMenu, got %v", m.Screen)
    }
}
```

### Pattern 3: Teatest Integration Tests

Use Charmbracelet's teatest for TUI testing:

```go
func TestInteractiveFlow(t *testing.T) {
    m := NewModel()
    tm := teatest.NewTestModel(t, m)

    // Send keys
    tm.Send(tea.KeyMsg{Type: tea.KeyEnter})
    tm.Send(tea.KeyMsg{Type: tea.KeyDown})
    tm.Send(tea.KeyMsg{Type: tea.KeyEnter})

    // Wait for model to update
    tm.WaitFinished(t, teatest.WithDuration(time.Second))

    // Get final model
    finalModel := tm.FinalModel(t).(Model)

    if finalModel.Screen != ExpectedScreen {
        t.Errorf("wrong screen: got %v", finalModel.Screen)
    }
}

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)