import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @GestureState private var dragOffset: CGFloat = 0

    private let sidebarWidth: CGFloat = AppTheme.sidebarWidth

    private var currentOffset: CGFloat {
        if appState.isSidebarOpen {
            return min(0, dragOffset)
        } else {
            return max(-sidebarWidth, -sidebarWidth + max(0, dragOffset))
        }
    }

    private var progress: CGFloat {
        (sidebarWidth + currentOffset) / sidebarWidth
    }

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Color.black.opacity(0.35 * progress)
                .ignoresSafeArea()
                .allowsHitTesting(progress > 0.01)
                .onTapGesture {
                    appState.isSidebarOpen = false
                }

            SidebarView()
                .ignoresSafeArea()
                .offset(x: currentOffset)
                .shadow(color: .black.opacity(0.2 * progress), radius: 20, x: 8, y: 0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: appState.isSidebarOpen)
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .updating($dragOffset) { value, state, _ in
                    let openingFromEdge = !appState.isSidebarOpen && value.startLocation.x < 44
                    guard openingFromEdge || appState.isSidebarOpen else { return }
                    state = value.translation.width
                }
                .onEnded { value in
                    let translation = value.translation.width
                    let velocity = value.predictedEndTranslation.width
                    if !appState.isSidebarOpen {
                        guard value.startLocation.x < 44 else { return }
                        if translation > sidebarWidth * 0.3 || velocity > sidebarWidth {
                            appState.isSidebarOpen = true
                        }
                    } else {
                        if translation < -(sidebarWidth * 0.3) || velocity < -(sidebarWidth * 0.5) {
                            appState.isSidebarOpen = false
                        }
                    }
                }
        )
    }

    @ViewBuilder
    private var mainContent: some View {
        NavigationStack {
            destinationView
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            appState.isSidebarOpen.toggle()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(.body, weight: .medium))
                        }
                        .tint(.primary)
                    }
                }
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch appState.selectedDestination {
        case .inbox, .upcoming, .completed, .list:
            TaskListView()
        case .today:
            TodayView()
        case .habits:
            HabitListView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [TaskItem.self, TaskList.self, Habit.self, HabitLog.self, FeatureConfig.self, FeatureLink.self], inMemory: true)
}
