---
name: ios-swiftui-patterns
user-invocable: false
description:
  Use when building SwiftUI views, managing state with @State/@Binding/@ObservableObject, or
  implementing declarative UI patterns in iOS apps.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
metadata:
  source: GV-native
---

# iOS - SwiftUI Patterns

Modern declarative UI development for iOS, macOS, watchOS, and tvOS applications.

## Key Concepts

### State Management Hierarchy

SwiftUI provides a hierarchy of property wrappers for different state needs:

- **@State**: Local view state, owned by the view
- **@Binding**: Two-way connection to state owned elsewhere
- **@StateObject**: Creates and owns an ObservableObject
- **@ObservedObject**: References an ObservableObject owned elsewhere
- **@EnvironmentObject**: Dependency injection through the view hierarchy
- **@Environment**: Access to system-provided values

### Observable Pattern (iOS 17+)

```swift
@Observable
class UserModel {
    var name: String = ""
    var email: String = ""
    var isLoggedIn: Bool = false
}

struct ContentView: View {
    @State private var user = UserModel()

    var body: some View {
        UserProfileView(user: user)
    }
}
```

### Legacy ObservableObject Pattern

```swift
class UserViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var isLoading: Bool = false

    func fetchUser() async {
        isLoading = true
        defer { isLoading = false }
        // fetch logic
    }
}

struct UserView: View {
    @StateObject private var viewModel = UserViewModel()

    var body: some View {
        // view implementation
    }
}
```

## Best Practices

### View Composition

Break complex views into smaller, focused components:

```swift
struct OrderSummaryView: View {
    let order: Order

    var body: some View {
        VStack(spacing: 16) {
            OrderHeaderView(order: order)
            OrderItemsListView(items: order.items)
            OrderTotalView(total: order.total)
        }
    }
}
```

### Prefer Value Types

Use structs for models when possible to leverage SwiftUI's efficient diffing:

```swift
struct Product: Identifiable, Equatable {
    let id: UUID
    var name: String
    var price: Decimal
    var quantity: Int
}
```

### Use ViewModifiers for Reusable Styling

```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
