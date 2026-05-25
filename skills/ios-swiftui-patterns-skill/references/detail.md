            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
    }

}

extension View { func cardStyle() -> some View { modifier(CardModifier()) } }

````

### Task Lifecycle for Async Work

```swift
struct UserDetailView: View {
    let userId: String
    @State private var user: User?

    var body: some View {
        Group {
            if let user {
                UserContent(user: user)
            } else {
                ProgressView()
            }
        }
        .task {
            user = await fetchUser(id: userId)
        }
    }
}
````

## Common Patterns

### Navigation with NavigationStack (iOS 16+)

```swift
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ProductListView()
                .navigationDestination(for: Product.self) { product in
                    ProductDetailView(product: product)
                }
                .navigationDestination(for: Category.self) { category in
                    CategoryView(category: category)
                }
        }
    }
}
```

### Sheet and Alert Presentation

```swift
struct ItemView: View {
    @State private var showingDetail = false
    @State private var showingDeleteAlert = false

    var body: some View {
        Button("View Details") {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            DetailSheet()
        }
        .alert("Delete Item?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { deleteItem() }
            Button("Cancel", role: .cancel) { }
        }
    }
}
```

### List with SwiftData (iOS 17+)

```swift
@Model
class Task {
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(title: String) {
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
    }
}

struct TaskListView: View {
    @Query(sort: \Task.createdAt, order: .reverse)
    private var tasks: [Task]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List(tasks) { task in
            TaskRowView(task: task)
        }
    }
}
```

## Anti-Patterns

### Avoid Large Monolithic Views

Bad:

```swift
struct BadView: View {
    var body: some View {
        VStack {
            // 200+ lines of nested views
        }
    }
}
```

Good: Extract into focused subviews.

### Don't Use @ObservedObject for Owned State

Bad:

```swift
struct BadView: View {
    @ObservedObject var viewModel = ViewModel() // Re-created on every view init!
}
```

Good:

```swift
struct GoodView: View {
    @StateObject private var viewModel = ViewModel()
}
```

### Avoid Side Effects in View Body

Bad:

```swift
var body: some View {
    let _ = print("View rendered") // Side effect!
    Text("Hello")
}
```

Good: Use `.task`, `.onAppear`, or `.onChange` for side effects.

### Don't Force Unwrap in Views

Bad:

```swift
Text(user!.name) // Crash risk
```

Good:

```swift
if let user {
    Text(user.name)
}
```

## Related Skills

- **ios-swift-concurrency**: Async/await patterns for data loading
- **ios-uikit-architecture**: When bridging UIKit and SwiftUI
